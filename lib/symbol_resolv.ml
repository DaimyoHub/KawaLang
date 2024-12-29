open Ctx
open Type_error

let get_class_from_symbol ctx sym =
  match ClsDefTable.get ctx.classes sym with
    None -> report_sym_res_err (Class_not_found sym)
  | Some cls -> Ok cls

let get_method_from_class cls sym =
  match MethDefTable.get cls.meths sym with
    None -> report_sym_res_err (Method_not_in_class (cls.sym, sym))
  | Some meth -> Ok meth

let get_variable_type ctx sym =
  match LocalEnv.get ctx.vars sym with
    None -> report_sym_res_err (Loc_not_found sym)
  | Some var -> Ok var.t

let get_variable_data ctx sym =
    match LocalEnv.get ctx.vars sym with
      None -> report_sym_res_err (Loc_not_found sym)
    | Some var -> Ok var.data

