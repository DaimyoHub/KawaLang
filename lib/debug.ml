open Environment
open Symbol
open Type
open Context

let data_to_string data =
  match data with Expr (Cst n) -> string_of_int n | _ -> "unknown"

let type_to_string typ =
  match typ with
  | Int -> "int"
  | Bool -> "bool"
  | Cls (Sym cls) -> cls
  | Void -> "void"

let print_env env =
  let t = Env.raw env in
  Hashtbl.iter
    (fun k v ->
      let (Sym name) = k in
      print_endline
      @@ Printf.sprintf "%s -> %s (%s)" name (data_to_string v.data)
           (type_to_string v.typ))
    t

let print_method_table mt =
  let t = MethodTable.raw mt in
  Hashtbl.iter
    (fun k v ->
      let (Sym name) = k in
      print_endline @@ Printf.sprintf "%s -> %s" name (type_to_string v.ret_typ))
    t
