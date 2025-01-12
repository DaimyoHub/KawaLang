open Environment
open Type
open Type_error
open Context

let is_object_allocated obj =
  match obj.typ with
  | Cls _ -> if obj.data = No_data then false else true
  | _ -> true

let allocate_object_data ctx obj =
  let rec add_class_attributes attrs class_symbol =
    match ClassTable.get ctx.classes class_symbol with
    | None ->
        let _ = silent_report_symbol_resolv (Class_not_found class_symbol) in
        No_data
    | Some cls ->
        Env.iter
          (fun s loc -> Hashtbl.add attrs s (loc.typ, loc.data))
          cls.attrs;
        match cls.super with
        | None -> Obj attrs
        | Some super_symbol -> add_class_attributes attrs super_symbol
  in
  match obj.typ with
  | Cls sym -> 
      let res = Hashtbl.create 5 in
      add_class_attributes res sym
  | _ -> No_data
