open Context
open Environment
open Type_error
open Allocator
open Abstract_syntax
open Symbol

let ( let* ) res f =
  match res with
  | Ok x -> f x
  | Error rep -> propagate rep

(*
 * get_class context symbol
 *
 * If the [symbol] does correspond to an existing class, it returns its
 * definition. If it does not, it reports a symbol resolving error.
 *)
let get_class ctx symbol =
  match ClassTable.get ctx.classes symbol with
  | None -> report_symbol_resolv (Class_not_found symbol)
  | Some cls -> Ok cls

let is_super_class ctx final_super_sym class_sym =
  let* _ = get_class ctx final_super_sym in
  let Sym fsn = final_super_sym in
  let rec find_super class_sym =
    let* cls = get_class ctx class_sym in
    match cls.super with
    | None -> Ok false
    | Some (Sym super_name) -> (
        if super_name = fsn then
          Ok true
        else find_super (Sym super_name))
  in
  find_super class_sym

(*
 * get_method class_def symbol
 *
 * If [symbol] does correspond to a method associated to [class_def], it
 * returns the method definition. If it does not, it reports a symbol resolving
 * error.
 *)
let get_method ctx (class_def : class_def) symbol =
  let rec get_method_in_super super_def =
    match MethodTable.get super_def.meths symbol with
    | None -> (
        match super_def.super with
        | None -> report_symbol_resolv (Method_not_in_class (class_def.sym, symbol))
        | Some super_symbol -> (
            match get_class ctx super_symbol with
            | Ok super_def -> get_method_in_super super_def
            | Error _ ->
                report None None (Super_class_not_defined super_symbol)))
    | Some meth -> Ok meth
  in
  get_method_in_super class_def

(*
 * get_ctor_from_symbol ctx symbol
 *
 * If [symbol] does correspond to an existing class, it returns its constructor's
 * definition. If it does not, it reports a symbol resolving error.
 *)
let get_ctor ctx symbol =
  match get_class ctx symbol with
  | Ok cls -> (
      match get_method ctx cls symbol with
      | Ok ctor -> Ok ctor
      | Error rep -> propagate rep)
  | Error rep -> propagate rep

(*
 * get_variable ctx env symbol
 * 
 * If [symbol] does correspond to a global variable or a location from the local
 * environment, it returns its definition. If it does not, it reports a symbol
 * resolving error. It also allocates objects when they are not allocated yet.
 *)
let get_variable ctx env symbol =
  let allocate_then_get env var =
    if is_object_allocated var = false then (
      let allocated_obj =
        { sym = var.sym; typ = var.typ; data = allocate_object_data ctx var }
      in
      Env.add env var.sym allocated_obj;
      Ok allocated_obj)
    else Ok var
  in
  match Env.get env symbol with
  | None -> (
      match Env.get ctx.globals symbol with
      | None -> report_symbol_resolv (Loc_not_found symbol)
      | Some var -> allocate_then_get ctx.globals var)
  | Some var -> allocate_then_get env var

let silent_get_variable ctx env symbol =
  let allocate_then_get env var =
    if is_object_allocated var = false then (
      let allocated_obj =
        { sym = var.sym; typ = var.typ; data = allocate_object_data ctx var }
      in
      Env.add env var.sym allocated_obj;
      Ok allocated_obj)
    else Ok var
  in
  match Env.get env symbol with
  | None -> (
      match Env.get ctx.globals symbol with
      | None -> silent_report_symbol_resolv (Loc_not_found symbol)
      | Some var -> allocate_then_get ctx.globals var)
  | Some var -> allocate_then_get env var

(*
 * get_attribute ctx env loc_symbol attr_symbol
 *
 * If [loc_symbol] corresponds to a global/local object, and if [attr_sym]
 * corresponds to one of the object's attributes, it returns the attribute's
 * definition. If it does not, it reports a symbol resolving error. It also allocates
 * objects when they are not allocated yet.
 *
 * This function fails if a variable is found but its type and data are not 
 * coherent.
 *)
let get_attribute ctx env loc_sym attr_sym =
  let allocate_then_get env var =
    if is_object_allocated var = false then (
      let alloc_obj =
        { sym = var.sym; typ = var.typ; data = allocate_object_data ctx var }
      in
      Hashtbl.replace env var.sym (var.typ, alloc_obj.data);
      Ok alloc_obj)
    else Ok var
  in
  match get_variable ctx env loc_sym with
  | Ok var -> (
      match (var.typ, var.data) with
      | Cls _, Obj attrs -> (
          try
            let typ, data = Hashtbl.find attrs attr_sym in
            let loc = { typ; data; sym = attr_sym } in
            allocate_then_get attrs loc
          with _ ->
            report_symbol_resolv (Attribute_not_found (loc_sym, attr_sym)))
      | _, _ -> report None (Some var.typ) (Expected_object var.sym))
  | Error rep -> propagate rep

(*
 * get_location ctx env loc_kind
 *
 * If [loc_kind] corresponds to a variable or an attribute, it returns its
 * definition. If it does not, it reports a symbol resolving error.
 *)
let get_location ctx env loc_kind =
  match loc_kind with
  | Loc symbol -> get_variable ctx env symbol
  | Attr (obj, attr) -> get_attribute ctx env obj attr
  | _ -> report_symbol_resolv Not_loc

(*
 * get_location_symbol loc_kind
 *
 * If [loc_kind] corresponds to a variable or an attribute, it gives back its
 * symbol. If it does not, it reports a symbol resolving error.
 *)
let get_location_symbol loc_kind =
  match loc_kind with
  | Loc symbol -> Ok symbol
  | Attr (obj, attr) ->
      let (Sym obj_name) = obj and (Sym attr_name) = attr in
      Ok (Sym (obj_name ^ "." ^ attr_name))
  | _ -> report_symbol_resolv Not_loc

(*
 * get_variable_type ctx env symbol
 *
 * If [symbol] does correspond to a global/local variable, it returns its type.
 * If it does not, it reports a symbol resolving error.
 *)
let get_variable_type ctx env symbol =
  match get_variable ctx env symbol with
  | Ok var -> (
      match var.typ with
      | Cls class_sym ->
          if Result.is_error @@ get_class ctx class_sym then
            report None None (Type_not_defined class_sym)
          else Ok var.typ
      | _ -> Ok var.typ)
  | Error rep -> propagate rep

(*
 * get_attribute_type ctx env object_sym attribute_sym
 *
 * If the given object symbol corresponds to an object, and the given attribute
 * corresponds to one of the object's attribute, it returns the type of the 
 * attribute. If there is an issue during symbol resolving, a symbol resolving
 * error is reported.
 *)
let get_attribute_type ctx env obj_sym attr_sym =
  match get_attribute ctx env obj_sym attr_sym with
  | Ok attr -> (
      match attr.typ with
      | Cls class_sym ->
          if Result.is_error @@ get_class ctx class_sym then
            report None None (Type_not_defined class_sym)
          else Ok attr.typ
      | _ -> Ok attr.typ)
  | Error rep -> propagate rep

(*
 * get_location_type ctx env loc_kind
 *
 * If the given location correspond to a variable or an attribute of the globals
 * the given local environment, it return its type. If it does not, it reports
 * a symbol resolving error.
 *)
let get_location_type ctx env loc_kind =
  match loc_kind with
  | Loc symbol -> get_variable_type ctx env symbol
  | Attr (obj, attr) -> get_attribute_type ctx env obj attr
  | _ -> report_symbol_resolv Not_loc

(*
 * get_variable_data ctx env symbol
 * 
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its data. If it does not, it reports a 
 * symbol resolving error.
 *)
let get_variable_data ctx env symbol =
  match get_variable ctx env symbol with
  | Ok var -> Ok var.data
  | Error rep -> propagate rep

(*
 * get_attribute_data ctx env object_sym attribute_sym
 *
 * If the given object symbol corresponds to an object, and the given attribute
 * corresponds to one of the object's attribute, it returns the data of the 
 * attribute. If there is an issue during symbol resolving, a symbol resolving
 * error is reported.
 *)
let get_attribute_data ctx env obj_sym attr_sym =
  match get_attribute ctx env obj_sym attr_sym with
  | Ok attr -> Ok attr.data
  | Error rep -> propagate rep

(*
 * get_location_data ctx env loc_kind
 *
 * If the given location correspond to a variable or an attribute of the globals
 * or the given local environment, it returns its data. If it does not, it 
 * reports a symbol resolving error.
 *)
let get_location_data ctx env loc_kind =
  match loc_kind with
  | Loc symbol -> get_variable_data ctx env symbol
  | Attr (obj, attr) -> get_attribute_data ctx env obj attr
  | _ -> report_symbol_resolv Not_loc

(*
 * get_method_return_type class_def method_symbol
 *
 * Gets the return type of the method associated to the given symbol if it 
 * corresponds a a method of the given class definition.
 *)
let get_method_return_type ctx cls meth_sym =
  match get_method ctx cls meth_sym with
  | Error rep -> propagate rep
  | Ok meth -> Ok meth.ret_typ

(*
 * get_object_attributes ctx env symbol 
 *
 * If the given symbol does correspond to an object of the global variables or
 * to an object of the local environment, then it returns its attributes. If it
 * does not, it reports a symbol resolving error or a type error.
 *)
let get_attributes ctx env symbol =
  let* obj = get_variable ctx env symbol in
  match obj.data with
  | Obj attrs -> 
      Ok (Hashtbl.fold (fun sym (typ, data) acc ->
        Env.add acc sym { sym = sym; typ = typ; data = data };
        acc
      ) attrs (Env.create ()))
  | _ -> report None (Some obj.typ) (Loc_type_not_user_def obj.sym)

