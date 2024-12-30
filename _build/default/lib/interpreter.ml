open Ast
open Environment
open Context
open Symbol

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
      let loc = Option.get (Env.get env sym) in
      loc.data
  | VNull -> No_data


let rec eval_instr ctx env instr =
  match instr with
    Print e ->
      let _ = match eval_expr ctx env e with
          VInt n -> print_endline (Printf.sprintf "%d" n)
        | _ -> failwith "Unreachable" 
      in VNull
  | Set (sym, e) -> 
      let set_loc_data env =
        let value_data = value_to_data env (eval_expr ctx env e) in
        let loc = Option.get (Env.get env sym) in
        Env.add env sym { sym = sym; typ = loc.typ; data = value_data }
      in
      let _ = match Env.get env sym with
          Some _ -> set_loc_data env
        | None -> (
            match Env.get ctx.globals sym with
              Some _ -> set_loc_data ctx.globals
            | None -> failwith "Loc not found"
          )
      in VNull 
  | If (cond, is1, is2) -> (
      match eval_expr ctx env cond with
        VBool b ->
          if b then
            eval_seq ctx env is1
          else
            eval_seq ctx env is2
      | _ -> failwith "Unreachable"
    )
  | While (cond, is) -> (
      match eval_expr ctx env cond with
        VBool b ->
          if b then (
            let v = eval_seq ctx env is in
            if v <> VNull then v
            else
              eval_instr ctx env instr
          ) else VNull
      | _ -> failwith "Unreachable"
    )
  | Ret e -> eval_expr ctx env e
  | Ignore e -> let _ = eval_expr ctx env e in VNull


and eval_seq ctx env seq =
  match seq with
    [] -> VNull
  | Ret e :: _ -> eval_instr ctx env (Ret e)
  | instr :: s -> 
      let _ = eval_instr ctx env instr in
      eval_seq ctx env s
