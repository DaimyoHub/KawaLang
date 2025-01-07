open Context
open Environment
open Type_error


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
 *
 * 
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its definition. If it does not, it reports a
 * symbol resolving error.
 *)
let get_variable ctx env sym =
  match Env.get env sym with
    None -> (
      match Env.get ctx.globals sym with
        None -> report_symbol_resolv (Loc_not_found sym)
      | Some var -> Ok var
    )
  | Some var -> Ok var


(*
 * 
 *
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its type. If it does not, it reports a
 * symbol resolving error.
 *)
let get_variable_type ctx env sym =
  match get_variable ctx env sym with
    Ok var -> Ok var.typ
  | Error rep -> propagate rep


(*
 * 
 * 
 * If the given symbol does correspond to a global variable or a location from
 * the local environment, it returns its data. If it does not, it reports a 
 * symbol resolving error.
 *)
let get_variable_data ctx env sym =
  match get_variable ctx env sym with
    Ok var -> Ok var.data
  | Error rep -> propagate rep


(*
 * 
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


let get_method_ret_typ cls meth_sym =
  match get_method_from_class cls meth_sym with
    Error rep -> propagate rep
  | Ok meth -> Ok meth.ret_typ

