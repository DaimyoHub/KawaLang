open Symbol
open Abstract_syntax
open Type

type sym_res_err_kind = 
  | Class_not_found     of symbol
  | Loc_not_found       of symbol
  | Class_without_ctor  of symbol
  | Method_not_in_class of symbol * symbol
  | Not_loc             of symbol
  | Diff_locs_same_sym


type typ_err_kind =
    Sym_res_err             of sym_res_err_kind
  | Lhs_ill_typed           of expr
  | Rhs_ill_typed           of expr
  | Expr_ill_typed          of expr
  | Cond_not_bool           of expr
  | Void_method_return
  | Typed_method_not_return
  | Set_ill_typed           of symbol * expr
  | Print_not_int           of expr
  | Unexpected_args         of symbol
  | Expected_args           of symbol
  | Arg_ill_typed           of symbol * expr
  | Loc_type_not_user_def   of symbol 
  | Unexpected_type         of expr
  | Expected_void_instr     of instr
  | Ill_typed               of instr
  | Branches_not_return_same
  | Not_obj_inst            of symbol * symbol
  | Already_returned
  | Method_ill_typed        of symbol
  | Dead_code
  | Class_type_not_exist    of symbol
  | Return_bad_type
  | If_branch_ill_typed     of bool
  | Set_ill_typed_without_info of symbol
  | If_stmt_may_return


type typ_err_report = {
  expected : typ option;
  obtained : typ option;
  kind : typ_err_kind;
}

let ttos ot =
  match ot with
    None -> "None"
  | Some t -> (
      match t with
        Int -> "int"
      | Bool -> "bool"
      | Void -> "void"
      | No_type -> "no type"
      | Cls (Sym s) -> s
    )

let pprint_symbol_resolv err =
  let fmt = Printf.sprintf in
  match err with
    Class_not_found (Sym s) ->
      fmt "Symbol '%s' does not correspond to a class.\n" s
  | Loc_not_found (Sym s) ->
      fmt "Symbol '%s' does not correspond to any variable or attribute.\n" s
  | Class_without_ctor (Sym s) ->
      fmt "Constructor of the class '%s' is not defined.\n" s
  | Method_not_in_class (Sym c, Sym m) ->
      fmt "Method '%s' is not defined in class '%s'.\n" m c
  | Not_loc _ ->
      fmt "Expression does not correspond to variable nor attribute\n"
  | Diff_locs_same_sym ->
      fmt "Different locals have the same symbol.\n"

let pprint rep =
  let fmt = Printf.sprintf in
  match rep.kind with
    Sym_res_err err -> pprint_symbol_resolv err
  | Lhs_ill_typed _ ->
      fmt "LHS has type %s. Expected type %s instead.\n" (ttos rep.obtained)
        (ttos rep.expected)
  | Rhs_ill_typed _ ->
      fmt "RHS has type %s. Expected type %s instead.\n" (ttos rep.obtained)
        (ttos rep.expected)
  | Expr_ill_typed _ ->
      fmt "Expression has type %s. Expected an expression of type %s.\n" 
        (ttos rep.obtained) (ttos rep.expected)
  | Cond_not_bool _ ->
      fmt "Condition expression is not a predicate. Expression has type %s.\n"
        (ttos rep.obtained)
  | Void_method_return ->
      "Method typed as void should not return.\n"
  | Typed_method_not_return ->
      "Typed method should return.\n"
  | Set_ill_typed (Sym s, _) ->
      fmt "Cannot set variable '%s' typed as %s with a value of type %s.\n" s
        (ttos rep.expected) (ttos rep.obtained)
  | Print_not_int _ ->
      "Argument of print is not of type int.\n"
  | Unexpected_args (Sym s) ->
      fmt "Calling '%s' method with too much arguments.\n" s
  | Expected_args (Sym s) ->
      fmt "Missing arguments to call '%s' method.\n" s
  | Arg_ill_typed (Sym s, _) ->
      fmt "Argument type (%s) does not correspond to parameter type (%s) of %s method.\n"
        (ttos rep.obtained) (ttos rep.expected) s
  | Loc_type_not_user_def (Sym s) ->
      fmt "Variable %s is not an object.\n" s
  | Unexpected_type _ ->
      "Unexpected type : "
  | Expected_void_instr _ ->
      "Expected void instruction.\n"
  | Ill_typed _ ->
      "Instruction is ill typed.\n"
  | Branches_not_return_same ->
      "Both branches of an if statement must be given the same type.\n"
  | Not_obj_inst (Sym loc_sym, Sym cls_sym) ->
      fmt "Cannot instanciate class '%s' with the variable '%s' not typed as '%s'.\n"
        cls_sym loc_sym cls_sym
  | Already_returned ->
      fmt "Found multiple sequential return statements for a same method.\n"
  | Method_ill_typed (Sym sym) ->
      fmt "Method '%s' is ill typed.\n" sym
  | Dead_code ->
      fmt "Found dead code.\n"
  | Class_type_not_exist (Sym name) ->
      fmt "Class type '%s' does not exist. Class '%s' has not been defined.\n" name
        name
  | Return_bad_type ->
      fmt "Returning value of type %s but expected a value of type %s.\n"
        (ttos rep.obtained) (ttos rep.expected)
  | If_branch_ill_typed b ->
      fmt "Conditional statement %s branch is ill typed.\n"
        (if b then "first" else "second")
  | Set_ill_typed_without_info (Sym name) ->
      fmt "Unable to set variable '%s' : RHS operand is ill typed.\n" name
  | If_stmt_may_return ->
      fmt "Conditional statement only returns in one branch.\n"

let report exp obt kind =
  let rep = {
    expected = exp;
    obtained = obt;
    kind = kind
  } in
  print_string (pprint rep);
  Error rep

let propagate rep = Error rep

let report_symbol_resolv err =
  report None None (Sym_res_err err)

let is_call_related_report rep =
  match rep.kind with
    Expected_args _
  | Unexpected_args _
  | Arg_ill_typed (_, _) -> true
  | _ -> false
   
