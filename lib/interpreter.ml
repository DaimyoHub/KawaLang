open Abstract_syntax
open Environment
open Symbol
open Symbol_resolver
open Type_error
open Type_checker
open Context

exception Exec_error of string

let ( let* ) res f = match res with Ok x -> f x | Error rep -> propagate rep

type value = VInt of int | VBool of bool | VObj of Env.t | VNull

let make_this_symbol =
  let counter = ref 0 in
  fun _ ->
    incr counter;
    let cs = string_of_int !counter in
    Sym (Printf.sprintf "@this%s" cs)

let value_to_data = function
  | VInt n -> Expr (Cst n)
  | VBool b -> Expr (if b then True else False)
  | VObj table ->
      let mapped_table = Hashtbl.create 5 in
      Env.iter
        (fun attr loc -> Hashtbl.add mapped_table attr (loc.typ, loc.data))
        table;
      Obj mapped_table
  | VNull -> No_data

let rec update_args calling_env env (params : (symbol * loc) list) initial_args
    =
  match (initial_args, params) with
  | [], [] -> ()
  | Loc arg_sym :: ars, (psym, _) :: prs ->
      let param_loc = Option.get @@ Env.get calling_env psym in
      Env.add env arg_sym
        { sym = arg_sym; typ = param_loc.typ; data = param_loc.data };
      let _ = Env.rem calling_env psym and _ = Env.rem calling_env arg_sym in
      update_args calling_env env prs ars
  | Attr (Sym obj_name, _) :: ars, (psym, _) :: prs ->
      let param_loc = Option.get @@ Env.get calling_env psym in
      (match param_loc.data with
      | Obj attrs ->
          Env.add env (Sym obj_name)
            { sym = Sym obj_name; typ = param_loc.typ; data = Obj attrs }
      | _ -> raise (Exec_error "update_args.1"));
      let _ = Env.rem calling_env psym
      and _ = Env.rem calling_env (Sym obj_name) in
      update_args calling_env env prs ars
  | _ :: ars, _ :: prs -> update_args calling_env env prs ars
  | _, _ -> raise (Exec_error "update_args.2")

let rec exec_prog ctx = exec_seq ctx ctx.globals ctx.main

and eval_data ctx env data =
  match data with
  | Obj attrs ->
      let mapped_attrs = Env.create () in
      Hashtbl.iter
        (fun attr (typ, data) ->
          Env.add mapped_attrs attr { typ; data; sym = attr })
        attrs;
      VObj mapped_attrs
  | Expr expr -> eval_expr ctx env expr
  | No_data -> VNull

and value_to_string ctx env = function
  | VNull -> "null"
  | VInt n -> Printf.sprintf "%d" n
  | VBool b -> Printf.sprintf "%s" (if b then "true" else "false")
  | VObj obj ->
      let res = "{\n" in
      Env.iter
        (fun (Sym name) v ->
          let sdata = value_to_string ctx env (eval_data ctx env v.data) in
          let _ = res ^ Printf.sprintf "\t%s -> %s\n" name sdata in
          ())
        obj;
      res ^ "}"

and eval_expr ctx env expr =
  let eao = eval_arithmetic_op ctx env
  and eco = eval_comparison_op ctx env
  and elo = eval_logic_op ctx env
  and eexpr = eval_expr ctx env in
  match expr with
  | Cst n -> VInt n
  | True -> VBool true
  | False -> VBool false
  | Loc sym -> eval_variable ctx env sym
  | Attr (o, s) -> eval_attribute ctx env o s
  | This -> eval_variable ctx env (Sym "this")
  | Add (e1, e2) -> eao e1 e2 ( + )
  | Mul (e1, e2) -> eao e1 e2 ( * )
  | Div (e1, e2) -> eao e1 e2 ( / )
  | Mod (e1, e2) -> eao e1 e2 ( mod )
  | Min (e1, e2) -> eao e1 e2 ( - )
  | Neg e -> (
      match eexpr e with
      | VInt n -> VInt (-n)
      | _ -> raise (Exec_error "eval_expr.1"))
  (* Equality operations *)
  | Eq (e1, e2) -> eval_equality ctx env e1 e2 true
  | Neq (e1, e2) -> eval_equality ctx env e1 e2 false
  | StructEq (e1, e2) -> eval_structural_equality_op ctx env e1 e2 true
  | StructNeq (e1, e2) -> eval_structural_equality_op ctx env e1 e2 false
  | InstanceOf (e, t) -> (
      (* Instead of redoing the whole type checker to make it change the AST,
         I prefer to just type the expression e twice (in the type checker,
         and in the interpreter). *)
      match type_expr ctx env e with
      | Ok typ -> if t = typ then VBool true else VBool false
      | Error _ -> raise (Exec_error "eval_expr.2"))
  | Lne (e1, e2) -> eco e1 e2 ( < )
  | Leq (e1, e2) -> eco e1 e2 ( <= )
  | Gne (e1, e2) -> eco e1 e2 ( > )
  | Geq (e1, e2) -> eco e1 e2 ( >= )
  | Con (e1, e2) -> elo e1 e2 ( && )
  | Dis (e1, e2) -> elo e1 e2 ( || )
  | Not e -> (
      match eexpr e with
      | VBool b -> VBool (b = false)
      | _ -> raise (Exec_error "eval_expr.3"))
  | Call (caller, callee, args) -> eval_call ctx env caller callee args
  | Inst (callee, args) ->
      let this_symbol = make_this_symbol () in
      Env.add env this_symbol
        { sym = this_symbol; data = No_data; typ = Cls callee };
      let _ = eval_call ctx env this_symbol callee args in
      let this_loc = Option.get @@ Env.get env this_symbol in
      let v = eval_data ctx env this_loc.data in
      let _ = Env.rem env this_symbol in
      v
  | StaticCall (class_type, callee, args) ->
      eval_static_call ctx env class_type callee args
  | Cast (expr, _) -> eval_expr ctx env expr
  | StaticAttr (_, _) -> VNull

and eval_args ctx env params args =
  let rec eval_args_loop params args acc =
    match (params, args) with
    | [], [] -> acc
    | pr :: prs, ar :: ars ->
        let new_data = value_to_data (eval_expr ctx env ar)
        and psym, ploc = pr in
        Env.add acc psym { sym = psym; typ = ploc.typ; data = new_data };
        eval_args_loop prs ars acc
    | _, _ -> raise (Exec_error "eval_args")
  in
  eval_args_loop params (List.rev args) (Env.create ())

and eval_call ctx env caller callee args =
  let copy_without_caller env =
    let res = Env.create () in
    Env.iter
      (fun k v ->
        let Sym n1, Sym n2 = (k, caller) in
        if n1 <> n2 then Env.add res k v)
      env;
    res
  in
  let var = Result.get_ok @@ get_variable ctx env caller in
  match var.typ with
  | Cls class_symbol ->
      let cls = Result.get_ok @@ get_class ctx class_symbol in
      let meth = Result.get_ok @@ get_method ctx cls callee in

      let args_env = eval_args ctx env meth.params args in
      let calling_env =
        Option.get @@ Env.merge [ args_env; copy_without_caller ctx.globals ]
      in
      Env.add calling_env (Sym "this")
        { sym = Sym "this"; typ = Cls class_symbol; data = var.data };
      let res = exec_seq ctx calling_env meth.code in

      update_args calling_env env meth.params args;

      let this_loc = Option.get @@ Env.get calling_env (Sym "this") in
      Env.add env caller this_loc;

      Env.iter
        (fun k v ->
          if Env.get ctx.globals k <> None then Env.add ctx.globals k v)
        calling_env;

      res
  | _ -> raise (Exec_error "eval_call")

and eval_static_call ctx env typ callee args =
  match typ with
  | Cls class_symbol ->
      let cls = Result.get_ok @@ get_class ctx class_symbol in
      let meth = Result.get_ok @@ get_static_method cls callee in

      let args_env = eval_args ctx env meth.params args in

      let calling_env = Option.get @@ Env.merge [ args_env; ctx.globals ] in
      let res = exec_seq ctx calling_env meth.code in

      update_args calling_env env meth.params args;

      Env.iter (fun k v -> Env.add ctx.globals k v) calling_env;

      res
  | _ -> raise (Exec_error "eval_static_call")

and eval_equality ctx env e1 e2 op =
  match (eval_expr ctx env e1, eval_expr ctx env e2) with
  | VInt a, VInt b -> VBool (a = b = op)
  | VBool a, VBool b -> VBool (a = b = op)
  | VNull, VNull -> VBool op
  | VObj _, VObj _ -> (
      match (e1, e2) with
      | Loc (Sym n1), Loc (Sym n2) -> VBool (n1 = n2 = op)
      | Attr (Sym o1, Sym a1), Attr (Sym o2, Sym a2) ->
          VBool ((o1 = o2 && a1 = a2) = op)
      | _, _ -> VBool (op = false))
  | _ -> raise (Exec_error "eval_equality")

and eval_structural_equality_op ctx env e1 e2 op =
  match (eval_expr ctx env e1, eval_expr ctx env e2) with
  | VInt a, VInt b -> VBool (a = b = op)
  | VBool a, VBool b -> VBool (a = b = op)
  | VNull, VNull -> VBool op
  | VObj a1, VObj a2 ->
      let res = ref true in
      Env.iter
        (fun k v1 ->
          match Env.get a2 k with
          | Some v2 ->
              if
                is_same_value ctx env
                  (eval_data ctx env v1.data)
                  (eval_data ctx env v2.data)
                <> op
              then res := false
          | None -> ())
        a1;
      VBool !res
  | _ -> raise (Exec_error "eval_structural_equality")

and eval_arithmetic_op ctx env e1 e2 (op : int -> int -> int) =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in
  match (v1, v2) with
  | VInt a, VInt b -> VInt (op a b)
  | _ -> raise (Exec_error "eval_arithmetic_op")

and eval_comparison_op ctx env e1 e2 op =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in
  match (v1, v2) with
  | VInt a, VInt b -> VBool (op a b)
  | _ -> raise (Exec_error "eval_comparison_op")

and eval_logic_op ctx env e1 e2 op =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in
  match (v1, v2) with
  | VBool a, VBool b -> VBool (op a b)
  | _ -> raise (Exec_error "eval_logic_op")

and eval_variable ctx env sym =
  eval_data ctx env (Result.get_ok @@ get_variable_data ctx env sym)

and eval_attribute ctx env obj_sym attr_sym =
  eval_data ctx env
    (Result.get_ok @@ get_attribute_data ctx env obj_sym attr_sym)

and is_same_value ctx env v1 v2 =
  match (v1, v2) with
  | VNull, VNull -> true
  | VBool a, VBool b -> a = b
  | VInt a, VInt b -> a = b
  | VObj a, VObj b ->
      let res = ref true in
      Env.iter
        (fun k v1 ->
          match Env.get b k with
          | Some v2 ->
              if
                is_same_value ctx env
                  (eval_data ctx env v1.data)
                  (eval_data ctx env v2.data)
              then res := false
          | None -> ())
        a;
      !res
  | _ -> raise (Exec_error "is_same_value")

and exec_instr ctx env instr =
  match instr with
  | Print e ->
      print_endline (value_to_string ctx env (eval_expr ctx env e));
      VNull
  | If (cond, s1, s2) -> (
      match eval_expr ctx env cond with
      | VBool b -> if b then exec_seq ctx env s1 else exec_seq ctx env s2
      | _ -> raise (Exec_error "exec_instr.1"))
  | While (cond, seq) -> (
      match eval_expr ctx env cond with
      | VBool b ->
          if b then
            let v = exec_seq ctx env seq in
            if v = VNull then exec_instr ctx env instr else v
          else VNull
      | _ -> raise (Exec_error "exec_instr.2"))
  | Set (Loc symbol, expr) -> (
      let new_data = value_to_data (eval_expr ctx env expr) in
      match Env.get ctx.globals symbol with
      | None -> (
          match Env.get env symbol with
          | None -> raise (Exec_error "exec_instr.3")
          | Some v ->
              Env.add env symbol { typ = v.typ; sym = v.sym; data = new_data };
              VNull)
      | Some v ->
          Env.add ctx.globals symbol
            { typ = v.typ; sym = v.sym; data = new_data };
          VNull)
  | Set (Attr (obj_sym, attr_sym), expr) -> (
      let update_attribute env obj new_data =
        match obj.data with
        | Obj attrs -> (
            match get_attribute ctx env obj_sym attr_sym with
            | Ok attr -> Hashtbl.replace attrs attr.sym (attr.typ, new_data)
            | _ -> raise (Exec_error "exec_instr.4"))
        | _ -> raise (Exec_error "exec_instr.5")
      in
      let new_data = value_to_data (eval_expr ctx env expr) in
      match Env.get ctx.globals obj_sym with
      | None -> (
          match Env.get env obj_sym with
          | None -> raise (Exec_error "exec_instr.6")
          | Some obj ->
              update_attribute env obj new_data;
              VNull)
      | Some obj ->
          update_attribute ctx.globals obj new_data;
          VNull)
  | Ret e -> eval_expr ctx env e
  | Ignore e ->
      let _ = eval_expr ctx env e in
      VNull
  | Init (sym, typ, expr) ->
      Env.add env sym { sym; typ; data = Expr expr };
      exec_instr ctx env (Set (Loc sym, expr))
  | _ -> raise (Exec_error "exec_instr.7")

and exec_seq ctx env seq =
  match seq with
  | [] -> VNull
  | instr :: s -> (
      match exec_instr ctx env instr with VNull -> exec_seq ctx env s | v -> v)
