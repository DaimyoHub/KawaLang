open Ctx
open Type_error

let get_class_from_symbol ctx sym =
  match ClsDefTable.get ctx.classes sym with
    None -> report_symbol_resolv (Class_not_found sym)
  | Some cls -> Ok cls

let get_method_from_class cls sym =
  match MethDefTable.get cls.meths sym with
    None -> report_symbol_resolv (Method_not_in_class (cls.sym, sym))
  | Some meth -> Ok meth

let get_variable_type global_ctx local_env sym =
  match LocalEnv.get local_env sym with
    None -> (
      match LocalEnv.get global_ctx.locs sym with
        None -> report_symbol_resolv (Loc_not_found sym)
      | Some var -> Ok var.typ
    )
  | Some var -> Ok var.typ

let get_variable_data env sym =
    match LocalEnv.get env sym with
      None -> report_symbol_resolv (Loc_not_found sym)
    | Some var -> Ok var.data

let find_object_attributes env object_sym =
  match LocalEnv.get env object_sym with
    None -> failwith "object not found"
  | Some loc -> get_object_attributes loc

