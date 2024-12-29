open Type
open Ctx
open Ast
open Type_error
open Symbol_resolv


let type_mem_loc ctx = function
    Loc s -> (
        match LocalEnv.get ctx.vars s with
          None -> report_sym_res_err (Loc_not_found s)
        | Some sd -> Ok sd.t
      )
  | e -> report_sym_res_err (Not_loc e)


let rec type_expr ctx = function
      Cst _ -> Ok Int
    | True
    | False -> Ok Bool
    | Loc s -> type_mem_loc ctx (Loc s)
    | This -> type_mem_loc ctx This
    | Add (e1, e2) 
    | Mul (e1, e2) 
    | Mod (e1, e2)
    | Min (e1, e2)
    | Div (e1, e2) -> type_bin_op ctx Int Int e1 e2
    | Neg a -> type_expr ctx a
    | Eq (e1, e2)
    | Neq (e1, e2)
    | Lne (e1, e2)
    | Leq (e1, e2) -> type_bin_op ctx Int Bool e1 e2
    | Con (e1, e2)
    | Dis (e1, e2) -> type_bin_op ctx Bool Bool e1 e2
    | Not a -> type_expr ctx a
    | Inst (cls_sym, args) -> (
        match get_class_from_symbol ctx cls_sym with
          Ok cls -> (
            match get_method_from_class cls cls_sym with
              Ok ctor -> type_args ctx cls_sym (Cls cls_sym) args ctor.params
            | _ -> report_sym_res_err (Class_without_ctor cls_sym)
          )
        | Error rep -> Error rep
      )
    | Call (caller, callee, args) ->
        match get_variable_type ctx caller with
          Ok (Cls cls_sym) -> (
            match get_class_from_symbol ctx cls_sym with
              Ok cls -> (
                match get_method_from_class cls callee with
                  Ok meth -> type_args ctx callee meth.ret_typ args meth.params
                | Error rep -> Error rep
              )
            | Error rep -> Error rep
          )
        | Ok t -> 
            report_typ_err None (Some t) (Loc_type_not_user_def caller)
        | err -> err


and check ctx e t =
  match type_expr ctx e with
  | Ok typ ->
      if typ = t then Ok typ
      else
        report_typ_err (Some t) (Some typ) (Unexpected_type e)
  | err -> err


and type_bin_op ctx exp res e1 e2 =
  match check ctx e1 exp with
    Ok _ -> (
      match check ctx e2 exp with
        Ok _ -> Ok res
      | Error rep -> report_typ_err (Some exp) rep.obtained (Rhs_ill_typed e2)
    )
  | Error rep -> report_typ_err (Some exp) rep.obtained (Lhs_ill_typed e1)


and type_args ctx sym ret_typ args params =
  match args, params with
    [], [] -> Ok ret_typ
  | [], _ -> report_typ_err None None (Expected_args sym)
  | _, [] -> report_typ_err None None (Unexpected_args sym)
  | a :: s1, p :: s2 ->
      match check ctx a p with
        Ok _ -> type_args ctx sym ret_typ s1 s2
      | Error rep -> report_typ_err (Some p) rep.obtained (Arg_ill_typed (sym, a))


let rec check_instr ctx exp = function
    Print e -> (
      match check ctx e Int with
        Ok _ -> Ok Void
      | err -> err
    )
  | Set (sym, e) -> (
      match get_variable_type ctx sym with
        Ok t -> (
          match check ctx e t with
            Ok _ -> Ok Void
          | Error rep -> report_typ_err (Some t) rep.obtained (Set_ill_typed (sym, e))
        )
      | err -> err
    ) 
  | If (cond, is1, is2) -> (
      match check ctx cond Bool with
        Ok _ -> (
          match check_seq ctx exp is1 with
            Ok _ -> check_seq ctx exp is2
          | err -> err
        )
      | Error rep -> report_typ_err (Some Bool) rep.obtained (Cond_not_bool cond)
    )
  | While (cond, is) -> (
      match check ctx cond Bool with
        Ok _ -> check_seq ctx exp is
      | Error rep -> report_typ_err (Some Bool) rep.obtained (Cond_not_bool cond)
    )
  | Ret e -> check ctx e exp
  | Ignore _ -> Ok Void


and check_seq ctx exp = function
    [] ->
      if exp <> Void then
        report_typ_err None None Typed_method_not_return
      else Ok Void
  | Ret e :: _ ->
      if exp = Void then
        report_typ_err None None Void_method_return
      else check ctx e exp
  | instr :: s -> (
      match check_instr ctx Void instr with
        Ok _ -> check_seq ctx exp s
      | Error rep ->
          let _ = propagate_typ_err rep in
          check_seq ctx exp s
    )
