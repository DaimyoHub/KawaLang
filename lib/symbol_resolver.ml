open Context
open Environment
open Type_error
open Allocator
open Abstract_syntax
open Symbol


(*
 * get_class_from_symbol context symbol
 *
 * If the given symbol does correspond to an existing class, it returns its
 * definition. If it does not, it reports a symbol resolving error.
 *)
let get_class_from_symbol ctx sym =
  match ClassTable.get ctx.classes sym with
    None -> report_symbol_resolv (Class_not_found sym)
  | Some cls -> Ok cls


(*
 * get_method_from_class class_def symbol
 *
 * If the given symbol does correspond to a method associated to the given class
 * definition, it returns the method definition. If it does not, it reports a
 * symbol resolving error.
 *)
let get_method_from_class cls sym =
  match MethodTable.get cls.meths sym with
    None -> report_symbol_resolv (Method_not_in_class (cls.sym, sym))
  | Some meth -> Ok meth


(*
 * get_ctor_from_symbol ctx symbol
 *
 * If the given symbol does correspond to an existing class, it returns its 
 * definition. If it does not, it reports a symbol resolving error.
 *)
let get_ctor_from_symbol ctx sym =
  match get_class_from_symbol ctx sym with
    Ok cls -> (
      match get_method_from_class cls sym with
        Ok ctor -> Ok ctor
      | Error rep -> propagate rep
    )
  | Error rep -> propagate rep


(*
 * get_variable ctx env symbol
 * 
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its definition. If it does not, it reports a
 * symbol resolving error.
 *)
let get_variable ctx env sym =

  let allocate_then_get env var =
    if is_object_allocated var = false then
      let allocated_obj =
        { sym = var.sym; typ = var.typ; data = allocate_object_data ctx var }
      in
      Env.add env var.sym allocated_obj;
      Ok allocated_obj
    else Ok var
  in

  match Env.get env sym with
    None -> (
      match Env.get ctx.globals sym with
        None -> report_symbol_resolv (Loc_not_found sym)
      | Some var -> allocate_then_get ctx.globals var
    )
  | Some var -> allocate_then_get env var


(*
 * get_variable_attr ctx env loc_symbol attr_symbol
 *
 * If the given loc_symbol correspond to a global object or a local object, it 
 * returns its definition. If it does not, it reports a symbol resolving error.
 *
 * This function fails if a variable is found but its type and data are not 
 * coherent.
 *)
let get_attribute ctx env loc_sym attr_sym =

  let allocate_then_get env var =
    if is_object_allocated var = false then
      let alloc_obj =
        { sym = var.sym; typ = var.typ; data = allocate_object_data ctx var }
      in
      Hashtbl.replace env var.sym (var.typ, alloc_obj.data);
      Ok alloc_obj
    else Ok var
  in

  match get_variable ctx env loc_sym with
    Ok var -> (
      match var.typ, var.data with
        Cls _, Obj attrs -> (
          try
            let typ, data = Hashtbl.find attrs attr_sym in
            let loc = { typ = typ; data = data; sym = attr_sym } in
            allocate_then_get attrs loc
          with _ -> report_symbol_resolv (Attribute_not_found (loc_sym, attr_sym))
        )
      | _, _ -> failwith "Incoherence type/data of loc."
    )
  | Error rep -> propagate rep


let get_location ctx env loc_kind =
  match loc_kind with
    Loc sym -> get_variable ctx env sym
  | Attr (obj, attr) -> get_attribute ctx env obj attr
  | _ -> report_symbol_resolv Not_loc


let get_location_symbol loc_kind =
  match loc_kind with
    Loc sym -> Ok sym
  | Attr (obj, attr) ->
      let Sym obj_name = obj and Sym attr_name = attr in
      Ok (Sym (obj_name ^ "." ^ attr_name))
  | _ -> report_symbol_resolv Not_loc


(*
 * get_variable_type ctx env symbol
 *
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its type. If it does not, it reports a
 * symbol resolving error.
 *)
let get_variable_type ctx env sym =
  match get_variable ctx env sym with
    Ok var -> (
      match var.typ with
        Cls class_sym ->
          if Result.is_error @@ get_class_from_symbol ctx class_sym then
            report None None (Type_not_defined class_sym)
          else Ok var.typ
      | _ -> Ok var.typ
    )
  | Error rep -> propagate rep


let get_attribute_type ctx env obj_sym attr_sym =
  match get_attribute ctx env obj_sym attr_sym with
    Ok attr -> (
      match attr.typ with
        Cls class_sym ->
          if Result.is_error @@ get_class_from_symbol ctx class_sym then
            report None None (Type_not_defined class_sym)
          else Ok attr.typ
      | _ -> Ok attr.typ
    )
  | Error rep -> propagate rep


let get_location_type ctx env loc_kind =
  match loc_kind with
    Loc sym -> get_variable_type ctx env sym
  | Attr (obj, attr) -> get_attribute_type ctx env obj attr
  | _ -> report_symbol_resolv Not_loc


(*
 * get_variable_data ctx env symbol
 * 
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its data. If it does not, it reports a 
 * symbol resolving error.
 *)
let get_variable_data ctx env sym =
  match get_variable ctx env sym with
    Ok var -> Ok var.data
  | Error rep -> propagate rep

  
let get_attribute_data ctx env obj_sym attr_sym =
  match get_attribute ctx env obj_sym attr_sym with
    Ok attr -> Ok attr.data
  | Error rep -> propagate rep


let get_location_data ctx env loc_kind =
  match loc_kind with
    Loc sym -> get_variable_data ctx env sym
  | Attr (obj, attr) -> get_attribute_data ctx env obj attr
  | _ -> report_symbol_resolv Not_loc


(*
 * get_object_attributes ctx env symbol 
 *
 * If the given symbol does correspond to an object of the global variables or
 * to an object of the local environment, then it returns its attributes. If it
 * does not, it reports a symbol resolving error or a type error.
 *)
let get_object_attributes ctx env sym =
  match get_variable ctx env sym with
    Ok obj -> (
      match obj.data with
        Obj attrs -> Ok attrs
      | _ -> report None (Some obj.typ) (Loc_type_not_user_def obj.sym)
    )
  | Error rep -> propagate rep


(*
 * get_method_return_type class_def method_symbol
 *
 * Gets the return type of the method associated to the given symbol if it 
 * corresponds a a method of the given class definition.
 *)
let get_method_return_type cls meth_sym =
  match get_method_from_class cls meth_sym with
    Error rep -> propagate rep
  | Ok meth -> Ok meth.ret_typ

