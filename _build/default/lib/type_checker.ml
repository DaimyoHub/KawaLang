open Type
open Context
open Environment
open Abstract_syntax
open Symbol_resolver
open Symbol
open Type_error


(*
 * type_expr context env expr
 * 
 * Types the given expression based on the context. If any typing error, or symbol
 * resolving error occurs, then it is reported. Reports do not stop the typing
 * process to allow an exhaustive analysis of the given expression in one pass.
 *)
let rec type_expr ctx env expr =
  let tbo = type_bin_op ctx env
  in
  match expr with
      Cst _        -> Ok Int
    | True
    | False        -> Ok Bool
    | Loc s        -> get_variable_type ctx env s
    | Attr (o, s)  -> get_attribute_type ctx env o s
    | This         -> get_variable_type ctx env (Sym "this")
    | Add (e1, e2) 
    | Mul (e1, e2) 
    | Mod (e1, e2)
    | Min (e1, e2)
    | Div (e1, e2) -> tbo Int Int e1 e2
    | Neg a -> (
        match check ctx env a Int with
          Ok t -> Ok t
        | Error rep -> report (Some Int) rep.obtained (Expr_ill_typed a)
      )
    | Eq (e1, e2)  -> (
        match type_expr ctx env e1 with
          Ok t -> (
            match check ctx env e2 t with
              Ok _ -> Ok Bool
            | Error rep -> (
                match rep.kind with
                  Sym_res_err _ -> propagate rep
                | _ -> report (Some t) rep.obtained (Rhs_ill_typed e2)
              )          )
        | Error rep -> propagate rep
      )
    | Neq (e1, e2)
    | Geq (e1, e2)
    | Lne (e1, e2)
    | Gne (e1, e2)
    | Leq (e1, e2) -> tbo Int Bool e1 e2
    | Con (e1, e2) -> tbo Bool Bool e1 e2
    | Dis (e1, e2) -> tbo Bool Bool e1 e2
    | Not a        -> (
        match check ctx env a Bool with
          Ok t -> Ok t
        | Error rep -> report (Some Bool) rep.obtained (Expr_ill_typed a)
      )

    | Inst (class_symbol, args) -> (
        match get_ctor_from_symbol ctx class_symbol with
          Ok ctor -> (
            match type_call ctx env class_symbol Void args ctor.params with
              Ok Void -> Ok (Cls class_symbol)
            | Error rep -> propagate rep
            | Ok _ -> failwith "Unreachable : ctor does not return type void"
          )
        | Error rep -> propagate rep
      )
    | Call (caller, callee, args) -> (
        match get_variable_type ctx env caller with
          Ok (Cls class_symbol) -> (
            match get_class_from_symbol ctx class_symbol with
              Ok cls -> (
                match get_method_from_class cls callee with
                  Ok meth -> type_call ctx env callee meth.ret_typ args meth.params
                | Error rep -> propagate rep
              )
            | Error rep -> propagate rep
          )
        | Ok t -> 
            report None (Some t) (Loc_type_not_user_def caller)
        | Error rep -> propagate rep
      )


(*
 * check_method context class_def method_def
 * 
 * Checks if a given method associated to a class is well typed or not.
 *)
and check_method ctx (class_def : class_def) method_def =
  let mapped_params = List.fold_left (fun acc (sym, loc) ->
    Env.add acc sym loc;
    acc
  ) (Env.create ()) method_def.params
  in
  let env = Env.merge [method_def.locals; mapped_params] in
  match env with
    Some env -> (
      let _ = Env.add env (Sym "this")
        { sym = Sym "this"; typ = Cls class_def.sym; data = No_data }
      in
      match check_seq ctx env method_def.ret_typ method_def.code with
        Ok rt -> Ok rt
      | Error _ -> report None None (Method_ill_typed method_def.sym)
    )
  | None -> report_symbol_resolv Diff_locs_same_sym


(*
 * check context env expected_type expr
 * 
 * Checks if the given expression can be typed (based on the given context) and if
 * its type correspond to the given one.
 *)
and check ctx env e t =
  match type_expr ctx env e with
  | Ok typ ->
      if typ = t then Ok typ
      else
        report (Some t) (Some typ) (Unexpected_type e)
  | err -> err


(*
 * type_bin_op context env expected_type result_type e1 e2
 * 
 * Types the given binary operation, checking if both given operands can be given the
 * same type. If so, gives the result type.
 *)
and type_bin_op ctx env exp res e1 e2 =
  let chk = check ctx env in
  match chk e1 exp with
    Ok _ -> (
      match chk e2 exp with
        Ok _ -> Ok res
      | Error rep -> (
          match rep.kind with
            Sym_res_err _ -> propagate rep
          | _ -> report (Some exp) rep.obtained (Rhs_ill_typed e2)
        )
    )
  | Error rep -> (
      match rep.kind with
        Sym_res_err _ -> propagate rep
      | _ -> report (Some exp) rep.obtained (Lhs_ill_typed e1)
    )


(*
 * type_args context env method_symbol return_type args params
 * 
 * Types the given list of arguments then checks if it computed types correspond to the
 * parameter types of the given method.
 *)
and type_call ctx env sym ret_typ args params =
  let param_ts = 
    List.fold_left (
      fun acc (_, v) -> v.typ :: acc
    ) [] params
  in
  let rec aux args param_ts =
    match args, param_ts with
      [], [] -> Ok ret_typ
    | [], _ -> report None None (Expected_args sym)
    | _, [] -> report None None (Unexpected_args sym)
    | a :: s1, p :: s2 ->
        match check ctx env a p with
          Ok _ -> aux s1 s2
        | Error rep ->
            report (Some p) rep.obtained (Arg_ill_typed (sym, a))
  in
  aux args param_ts


(*
 * check_instr context env expected_type instr
 * 
 * Checks if each expression of the given instruction are well-typed and if these types
 * make the given instruction coherent.
 *)
and check_instr ctx env exp instr =
  let chk = check ctx env 
  and chs = check_seq ctx env
  in
  match instr with
    Print e -> (
      match chk e Int with
        Ok _ -> Ok Void
      | Error rep -> report (Some Int) (rep.obtained) (Print_not_int e)
    )
  | Set (loc, Inst (class_symbol, args)) -> (
      match get_location_type ctx env loc with
        Ok No_type -> failwith "TODO : type inference"
      | Ok (Cls class_symbol) -> (
          match chk (Inst (class_symbol, args)) (Cls class_symbol) with
            Ok _ -> Ok Void
          | Error rep -> propagate rep
        )
      | Ok t ->
          let sym = Result.get_ok @@ get_location_symbol loc in
          report (Some (Cls class_symbol)) (Some t) (Not_obj_inst (sym, class_symbol))
      | Error rep -> propagate rep
    )
  | Set (loc, e) -> (
      match get_location_type ctx env loc with
        Ok No_type -> failwith "TODO : type inference"
      | Ok t -> (
          match chk e t with
            Ok _ -> Ok Void
          | Error rep -> 
              let sym = Result.get_ok @@ get_location_symbol loc in
              if is_call_related_report rep then
                report None None (Set_ill_typed_without_info sym)
              else
                report (Some t) rep.obtained (Set_ill_typed (sym, e))
        )
      | Error rep -> propagate rep
    ) 
  | If (_, _, _) -> check_if_statement ctx env exp instr
  | While (cond, is) -> (
      match chk cond Bool with
        Ok _ -> chs exp is
      | Error rep ->
          report (Some Bool) rep.obtained (Cond_not_bool cond)
    )
  | Ret e -> chk e exp
  | Ignore e -> (
      match type_expr ctx env e with
        Ok _ -> Ok Void
      | Error rep -> propagate rep
    )

(*
 * check_if_statement context env expected_type if_stmt
 * 
 * Checks if a given if statement is well-typed. I define the meaning of the 
 * sentence "an if statement is well typed" in my programming report (see README.md).
 *)
and check_if_statement ctx env exp instr =
  let rec check_branch flag seq exp =
    match seq with
      [] -> Ok Void
    | [Ret e] -> (
        match check ctx env e exp with
          Ok _ -> Ok exp
        | Error rep -> report (Some exp) rep.obtained Return_bad_type
      )
    | Ret e :: s ->
        let _ = check_branch flag s exp and _ = report None None Dead_code in (
          match check ctx env e exp with
            Ok _ -> Ok exp
          | Error rep -> report (Some exp) rep.obtained Return_bad_type
        )
    | instr :: s -> (
        match check_instr ctx env exp instr with
          Ok Void -> check_branch flag s exp
        | Ok _ -> failwith "Unreachable : check_if_statement.check_branch" 
        | Error rep ->
            let _ = report (Some Void) rep.obtained (If_branch_ill_typed flag) in
            check_branch flag s exp
      )
  in
  match instr with
    If (cond, seq1, seq2) -> (
      match check ctx env cond Bool with
        Ok _ -> (
          match check_branch true seq1 exp with
            Ok t -> (
              match check_branch false seq2 t with
                Ok u -> 
                  if t = u then Ok t
                  else if exp <> Void && (t <> Void && u = Void) || (t = Void && u <> Void) then
                    report None None If_stmt_may_return
                  else
                    report (Some t) (Some u) Branches_not_return_same
              | Error rep -> report (Some t) rep.obtained Branches_not_return_same
            )
          | Error rep -> propagate rep
        )
      | Error rep -> report (Some Bool) rep.obtained (Cond_not_bool cond)
    )
  | _ -> failwith "Unreachable : check_if_statement of an instruction which is not an if statement"


(*
 * check_seq context env expected_type instr_list
 * 
 * Checks each instruction and handles the cases where a sequence of instructions 
 * should return a result or not.
 *)
and check_seq ctx env exp seq =
  match seq with
    [] ->
      if exp = Void then
        Ok Void
      else
        report None None Typed_method_not_return
  | [Ret e] ->
      if exp <> Void then (
        match check ctx env e exp with
          Ok t -> Ok t
        | Error rep -> propagate rep
      ) else
        report (Some Void) None Void_method_return
  | Ret e :: s ->
      let _ = check_seq ctx env exp s and _ = report None None Dead_code in (
        match check ctx env e exp with
          Ok _ -> Ok exp
        | Error rep ->
            report (Some exp) rep.obtained Return_bad_type
      )
  | If (c, s1, s2) :: s -> (
      match check_instr ctx env exp (If (c, s1, s2)) with
        Ok Void -> check_seq ctx env exp s
      | Ok _ -> check_seq ctx env Void s
      | Error rep -> let _ = check_seq ctx env exp s in propagate rep
    )
  | instr :: s -> (
      match check_instr ctx env Void instr with
        Ok _ -> check_seq ctx env exp s
      | Error rep -> let _ = check_seq ctx env exp s in propagate rep
    )

