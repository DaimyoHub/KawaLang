open Abstract_syntax
open Environment
open Symbol
open Symbol_resolver
open Method


type value = 
    VInt  of int
  | VBool of bool
  | VObj  of Env.t
  | VNull


let value_to_data = function
    VInt n -> Expr (Cst n)
  | VBool b -> Expr (if b then True else False)
  | VObj table -> (
      let mapped_table = Hashtbl.create 5 in
      Env.iter (fun attr loc ->
        Hashtbl.add mapped_table attr (loc.typ, loc.data)
      ) table;
      Obj mapped_table
    )
  | VNull -> No_data


let rec eval_expr ctx env expr = 
  let eao   = eval_arithmetic_op ctx env
  and eco   = eval_comparison_op ctx env
  and elo   = eval_logic_op      ctx env
  and eexpr = eval_expr          ctx env
  in
  match expr with
    Cst n        -> VInt n
  | True         -> VBool true
  | False        -> VBool false
  | Loc sym      -> eval_variable ctx env sym
  | Attr (o, s)  -> eval_attribute ctx env o s
  | This         -> eval_variable ctx env (Sym "this") 
  | Add (e1, e2) -> eao e1 e2 ( + )
  | Mul (e1, e2) -> eao e1 e2 ( * )
  | Div (e1, e2) -> eao e1 e2 ( / )
  | Mod (e1, e2) -> eao e1 e2 (mod)
  | Min (e1, e2) -> eao e1 e2 ( - )
  | Neg e -> (
      match eexpr e with
        VInt n -> VInt (- n)
      | _ -> failwith "Unreachable : neg expr is ill-typed"
    )

  (* Equality operations *)
  | Eq  (e1, e2) -> (
      match eexpr e1, eexpr e2 with
        VInt a,  VInt b  -> VBool (a = b)
      | VBool a, VBool b -> VBool (a = b)
      | _ -> failwith "Unreachable : eq expr is ill typed"
    )
  | Neq (e1, e2) -> (
      match eexpr e1, eexpr e2 with
        VInt a,  VInt b  -> VBool (a <> b)
      | VBool a, VBool b -> VBool (a <> b)
      | _ -> failwith "Unreachable : eq expr is ill typed"
    )

  | Lne (e1, e2) -> eco e1 e2 ( < )
  | Leq (e1, e2) -> eco e1 e2 (<= )
  | Gne (e1, e2) -> eco e1 e2 ( > )
  | Geq (e1, e2) -> eco e1 e2 (>= )

  | Con (e1, e2) -> elo e1 e2 (&& )
  | Dis (e1, e2) -> elo e1 e2 (|| )
  | Not e -> (
      match eexpr e with
        VBool b -> VBool (b = false)
      | _ -> failwith "Unreachable : not expr is ill-typed"
    )

  | Inst (class_sym, args) -> (
      let class_def = Result.get_ok @@ get_class_from_symbol ctx class_sym in
      let ctor_def = Result.get_ok @@ get_ctor_from_symbol ctx class_sym in
      let calling_env = Option.get @@ make_interpreting_env ctx class_def None ctor_def args in
      let _ = exec_seq ctx calling_env ctor_def.code in

      (* After calling the ctor, we copy the object instanciated to return it *)
      let res = Env.create () in

      Env.iter (fun (Sym name) v ->
        match String.split_on_char '.' name with
          [this; attr] when this = "this" ->
            Env.add res (Sym attr) { typ = v.typ; data = v.data; sym = Sym attr }
        | _ -> ()
      ) calling_env;

      (* ICI IL FAUT METTRE À JOUR L'ENTIÈRETÉ DE L'ENVIRONNEMENT IN PLACE *)
      (* ON RASSEMBLE LES ATTRIBUTS COMMUNS À UN OBJET *)
      (* ON MET A JOUR LES LOCS SIMPLES *)
      (* ON MET À JOUR LES OBJETS AVEC LE RASSEMBLEMENT FAIT JUSTE AVANT *)
  
      VObj res
    )
  | Call (_, _, _) -> failwith "TODO"


and eval_arithmetic_op ctx env e1 e2 (op : int -> int -> int) =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in (
    match v1, v2 with
      VInt a, VInt b -> VInt (op a b)
    | _ -> failwith "Unreachable : bin op expr is ill-typed"
  )


and eval_comparison_op ctx env e1 e2 op =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in (
    match v1, v2 with
      VInt a,  VInt b  -> VBool (op a b)
    | _ -> failwith "Unreachable : bin op expr is ill-typed"
  )


and eval_logic_op ctx env e1 e2 op =
  let v1 = eval_expr ctx env e1 and v2 = eval_expr ctx env e2 in (
    match v1, v2 with
      VBool a,  VBool b  -> VBool (op a b)
    | _ -> failwith "Unreachable : bin op expr is ill-typed"
  )


and eval_variable ctx env sym =
  eval_data ctx env (Result.get_ok @@ get_variable_data ctx env sym)


and eval_attribute ctx env obj_sym attr_sym =
  eval_data ctx env (Result.get_ok @@ get_attribute_data ctx env obj_sym attr_sym)


and eval_data ctx env data =
  match data with
    Obj attrs -> (
      let mapped_attrs = Env.create () in
      Hashtbl.iter (fun attr (typ, data) ->
        Env.add mapped_attrs attr { typ = typ; data = data; sym = attr }
      ) attrs;
      VObj mapped_attrs
    )
  | Expr expr -> eval_expr ctx env expr
  | No_data -> VNull


and exec_seq ctx env seq =
  match seq with
    [] -> VNull
  | instr :: s -> (
      match exec_instr ctx env instr with
        VNull -> exec_seq ctx env s
      | v -> v
    )


and value_to_string ctx env = function
    VNull    -> "null"
  | VInt n   -> Printf.sprintf "%d" n
  | VBool b  -> Printf.sprintf "%s" (if b then "true" else "false")
  | VObj obj -> (
      let res = "{\n" in
      Env.iter (fun (Sym name) v ->
        let sdata = value_to_string ctx env (eval_data ctx env v.data) in
        let _ = res ^ Printf.sprintf "\t%s -> %s\n" name sdata in ()
      ) obj;
      res ^ "}"
    )


and exec_instr ctx env instr =
  match instr with
    Print e -> (
      print_endline (value_to_string ctx env (eval_expr ctx env e));
      VNull
    )
  | If (cond, s1, s2) -> (
      match eval_expr ctx env cond with
        VBool b ->
          if b then exec_seq ctx env s1 else exec_seq ctx env s2
      | _ -> failwith "Unreachable : condition is ill-typed"
    )
  | While (cond, seq) -> (
      match eval_expr ctx env cond with
        VBool b ->
          if b then
            let v = exec_seq ctx env seq in
            if v = VNull then exec_instr ctx env instr
            else v
          else VNull
      | _ -> failwith "Unreachable : condition is ill-typed"
    )
  | Set (loc, expr) -> (
      let new_data = value_to_data (eval_expr ctx env expr) in 
      let symbol = Result.get_ok @@ get_location_symbol loc in
      match Env.get ctx.globals symbol with
        None -> (
          match Env.get env symbol with
            None -> failwith "Unreachable : unable to find loc"
          | Some v -> (
              Env.add env symbol { typ = v.typ; sym = v.sym; data = new_data };
              VNull
            )
        )
      | Some v -> (
          Env.add ctx.globals symbol { typ = v.typ; sym = v.sym; data = new_data };
          VNull
        )
    )
  | Ret e -> eval_expr ctx env e
  | Ignore e -> let _ = eval_expr ctx env e in VNull

