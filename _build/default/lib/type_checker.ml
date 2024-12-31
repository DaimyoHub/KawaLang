open Type
open Context
open Environment
open Abstract_syntax
open Symbol_resolver
open Symbol
open Type_error


(*
 * type_mem_loc context env expr
 * 
 * Gives the type of a given expression corresponding to a variable or an attribute.
 * If the expression is not such an object or is not in the current context, then a
 * symbol resolving error is reported.
 *)
let type_mem_loc ctx env sym =
  match Env.get env sym with
    Some loc -> Ok loc.typ
  | None -> (
      match Env.get ctx.globals sym with
        Some loc -> Ok loc.typ
      | None -> report_symbol_resolv (Not_loc sym)
    )


(*
 * type_expr context env expr
 * 
 * Types the given expression based on the context. If any typing error, or symbol
 * resolving error occurs, then it is reported. Reports do not stop the typing
 * process to allow an exhaustive analysis of the given expression in one pass.
 *)
let rec type_expr ctx env expr =
  let tml = type_mem_loc ctx env
  and tbo = type_bin_op ctx env
  and texpr = type_expr ctx env
  in
  match expr with
      Cst _        -> Ok Int
    | True
    | False        -> Ok Bool
    | Loc s        -> tml s
    | This         -> tml (Sym "this")
    | Add (e1, e2) 
    | Mul (e1, e2) 
    | Mod (e1, e2)
    | Min (e1, e2)
    | Div (e1, e2) -> tbo Int Int e1 e2
    | Neg a -> texpr a
    | Eq (e1, e2)
    | Neq (e1, e2)
    | Lne (e1, e2)
    | Leq (e1, e2) -> tbo Int Bool e1 e2
    | Con (e1, e2)
    | Dis (e1, e2) -> tbo Bool Bool e1 e2
    | Not a        -> texpr a
    | Inst (class_symbol, args) -> (
        match get_class_from_symbol ctx class_symbol with
          Ok cls -> (
            match get_method_from_class cls class_symbol with
              Ok ctor -> type_inst ctx env cls ctor args
            | _ ->
                report_symbol_resolv (Class_without_ctor class_symbol)
          )
        | Error rep -> propagate rep
      )
    | Call (caller, callee, args) -> (
        match get_variable_type ctx env caller with
          Ok (Cls class_symbol) -> (
            match get_class_from_symbol ctx class_symbol with
              Ok cls -> (
                match get_method_from_class cls callee with
                  Ok meth -> type_call ctx env caller meth args
                | Error rep -> Error rep
              )
            | Error rep -> Error rep
          )
        | Ok t -> 
            report None (Some t) (Loc_type_not_user_def caller)
        | Error rep -> propagate rep
      )


(*
 * type_call context env caller callee args
 *
 * Types a call to a given method. It checks if passed argument types correspond to
 * parameter types, then it recursivelly checks the if the method code is well-typed.
 *)
and type_call ctx env caller callee args =
  let targs = type_args ctx env in
  let loc =
    match Env.get env caller with
      Some loc -> loc
    | None -> (
        match Env.get ctx.globals caller with
          Some loc -> loc
        | None -> failwith "Unreachable"
      )
  in
  let calling_env =
    Hashtbl.fold (fun k v acc -> 
      let (typ, data) = v in
      Env.add acc k { sym = k; typ = typ; data = data };
      acc
    )
    (get_object_attributes loc)
    (Env.create ())
  in
  match targs callee.sym callee.ret_typ args callee.params with
    Ok rt -> check_seq ctx calling_env rt callee.code
  | Error rep -> propagate rep


(*
 * type_inst context env caller callee args
 *
 * Types a call to a given ctor. It checks if passed argument types correspond to
 * parameter types, then it recursivelly checks the if the ctor code is well-typed.
 *)
and type_inst ctx env cls ctor args =
  let targs = type_args ctx env in
  match targs ctor.sym Void args ctor.params with
    Ok Void ->
      check_seq ctx cls.attrs Void ctor.code
  | Ok t ->
      report (Some Void) (Some t) Void_method_return
  | Error rep -> propagate rep



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
      | Error rep ->
          report (Some exp) rep.obtained (Rhs_ill_typed e2)
    )
  | Error rep ->
      report (Some exp) rep.obtained (Lhs_ill_typed e1)


(*
 * type_args context env method_symbol return_type args params
 * 
 * Types the given list of arguments then checks if it computed types correspond to the
 * parameter types of the given method.
 *)
and type_args ctx env sym ret_typ args params =
  let param_ts = 
    Hashtbl.fold (
      fun _ v acc -> v.typ :: acc
    ) (Env.raw params) []
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
      | err -> err
    )
  | Set (sym, Inst (class_symbol, args)) -> (
      match get_variable_type ctx env sym with
        Ok (Cls class_symbol) -> (
          match chk (Inst (class_symbol, args)) Void with
            Ok _ -> Ok Void
          | Error rep -> propagate rep
        )
      | Ok t ->
          report (Some (Cls class_symbol)) (Some t) (Not_obj_inst (sym, class_symbol))
      | Error rep -> propagate rep
    )
  | Set (sym, e) -> (
      match get_variable_type ctx env sym with
      | Ok t -> (
          match chk e t with
            Ok _ -> Ok Void
          | Error rep ->
              report (Some t) rep.obtained (Set_ill_typed (sym, e))
        )
      | Error rep -> propagate rep
    ) 
  (*
   * In this impementation of Kawa, I force both branches of an if statement to be
   * given the same type by the algorithm. It simplifies the analysis of the returning
   * constraints of a given method.
   *)
  | If (cond, is1, is2) -> (
      match chk cond Bool with
        Ok _ -> (
          match chs exp is1 with
            Ok t -> (
              match chs t is2 with
                Ok _ -> Ok t
              | Error rep -> 
                  report (Some t) rep.obtained (Branches_not_return_same)
            )
          | Error rep -> propagate rep
        )
      | Error rep ->
          report (Some Bool) rep.obtained (Cond_not_bool cond)
    )
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
 * check_seq context env expected_type instr_list
 * 
 * Checks each instruction and handles the cases where a sequence of instructions 
 * should return a result or not.
 *)
and check_seq ctx env exp seq =
  let chk = check ctx env
  and chs = check_seq ctx env
  in
  match seq with
    [] ->
      if exp <> Void then
        report None None Typed_method_not_return
      else Ok Void
  | Ret e :: _ ->
      if exp = Void then
        report None None Void_method_return
      else chk e exp
  | instr :: s -> (
      match check_instr ctx env Void instr with
        Ok _ -> chs exp s
      | Error rep ->
          let _ = propagate rep in
          chs exp s
    )

