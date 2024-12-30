open Ast
open Ctx
open Sym

type value = 
    VInt  of int
  | VBool of bool
  | VObj  of symbol
  | VNull

let eval_expr g l e = 
  ignore g;
  ignore l;
  ignore e;
  VInt 0


let value_to_data env = function
    VInt n -> Expr (Cst n)
  | VBool b -> Expr (if b then True else False)
  | VObj sym ->
      let loc = Option.get (LocalEnv.get env sym) in
      loc.data
  | VNull -> No_data


let rec eval_instr global_ctx local_env instr =
  match instr with
    Print e ->
      let _ = match eval_expr global_ctx local_env e with
          VInt n -> print_endline (Printf.sprintf "%d" n)
        | _ -> failwith "Unreachable" 
      in VNull
  | Set (sym, e) -> 
      let set_loc_data env =
        let value_data = value_to_data env (eval_expr global_ctx local_env e) in
        let loc = Option.get (LocalEnv.get env sym) in
        LocalEnv.add env sym { typ = loc.typ; data = value_data }
      in
      let _ = match LocalEnv.get local_env sym with
          Some _ -> set_loc_data local_env
        | None -> (
            match LocalEnv.get global_ctx.locs sym with
              Some _ -> set_loc_data global_ctx.locs
            | None -> failwith "Loc not found"
          )
      in VNull 
  | If (cond, is1, is2) -> (
      match eval_expr global_ctx local_env cond with
        VBool b ->
          if b then
            eval_seq global_ctx local_env is1
          else
            eval_seq global_ctx local_env is2
      | _ -> failwith "Unreachable"
    )
  | While (cond, is) -> (
      match eval_expr global_ctx local_env cond with
        VBool b ->
          if b then (
            let v = eval_seq global_ctx local_env is in
            if v <> VNull then v
            else
              eval_instr global_ctx local_env instr
          ) else VNull
      | _ -> failwith "Unreachable"
    )
  | Ret e -> eval_expr global_ctx local_env e
  | Ignore e -> let _ = eval_expr global_ctx local_env e in VNull


and eval_seq global_ctx local_env seq =
  match seq with
    [] -> VNull
  | Ret e :: _ -> eval_instr global_ctx local_env (Ret e)
  | instr :: s -> 
      let _ = eval_instr global_ctx local_env instr in
      eval_seq global_ctx local_env s
