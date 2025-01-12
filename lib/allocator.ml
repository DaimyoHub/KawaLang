open Environment
open Type
open Type_error
open Context

let is_object_allocated obj =
  match obj.typ with
  | Cls _ -> if obj.data = No_data then false else true
  | _ -> true

let allocate_object_data ctx obj =
  match obj.typ with
  | Cls sym -> (
      match ClassTable.get ctx.classes sym with
      | None ->
          let _ = silent_report_symbol_resolv (Class_not_found sym) in
          No_data
      | Some cls ->
          let res = Hashtbl.create 5 in
          Env.iter
            (fun s loc -> Hashtbl.add res s (loc.typ, loc.data))
            cls.attrs;
          Obj res)
  | _ -> No_data
