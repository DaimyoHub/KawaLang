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
      | Cls (Sym s) -> s
    )

let pprint_symbol_resolv err =
  let fmt = Printf.sprintf in
  match err with
    Class_not_found (Sym s) ->
      fmt "'%s' is not a class." s
  | Loc_not_found (Sym s) ->
      fmt "'%s' is not a variable nor an attribute." s
  | Class_without_ctor (Sym s) ->
      fmt "Constructor of the class '%s' is not defined." s
  | Method_not_in_class (Sym c, Sym m) ->
      fmt "Method '%s' is not defined in class '%s'." m c
  | Not_loc _ ->
      fmt "'Expression does not correspond to variable nor attribute'"
  | Diff_locs_same_sym ->
      fmt "Different locals have the same symbol."

let pprint rep =
  let fmt = Printf.sprintf in
  match rep.kind with
    Sym_res_err err -> pprint_symbol_resolv err
  | Lhs_ill_typed _ ->
      fmt "LHS has type %s. Expected type %s instead." (ttos rep.obtained)
        (ttos rep.expected)
  | Rhs_ill_typed _ ->
      fmt "RHS has type %s. Expected type %s instead." (ttos rep.obtained)
        (ttos rep.expected)
  | Expr_ill_typed _ ->
      "Expression is ill typed."
  | Cond_not_bool _ ->
      "Condition expression is not a predicate."
  | Void_method_return ->
      "Method typed as void should not return."
  | Typed_method_not_return ->
      "Typed method should return."
  | Set_ill_typed (Sym s, _) ->
      fmt "Cannot set variable '%s' typed as %s with a value of type %s." s
        (ttos rep.expected) (ttos rep.obtained)
  | Print_not_int _ ->
      "Argument of print is not of type int."
  | Unexpected_args (Sym s) ->
      fmt "Calling %s method with too much arguments." s
  | Expected_args (Sym s) ->
      fmt "Missing arguments to call %s method." s
  | Arg_ill_typed (Sym s, _) ->
      fmt "Argument type (%s) does not correspond to parameter type (%s)
           of %s method." (ttos rep.obtained) (ttos rep.expected) s
  | Loc_type_not_user_def (Sym s) ->
      fmt "Variable %s is not an object." s
  | Unexpected_type _ ->
      "Unexpected type."
  | Expected_void_instr _ ->
      "Expected void instruction."
  | Ill_typed _ ->
      "Instruction is ill typed."
  | Branches_not_return_same ->
      "Both branches of an if statement must be samely typed."
  | Not_obj_inst (Sym loc_sym, Sym cls_sym) ->
      fmt "Cannot instanciate class '%s' with the variable '%s' not typed as '%s'."
        cls_sym loc_sym cls_sym
  | Already_returned ->
      fmt "Found multiple sequential return statements for a same method."
  | Method_ill_typed (Sym sym) ->
      fmt "Method '%s' is ill typed." sym
  | Dead_code ->
      fmt "Found dead code."
  | Class_type_not_exist (Sym name) ->
      fmt "Class type '%s' does not exist. Class '%s' has not been defined." name
        name
  | Return_bad_type ->
      fmt "Returning value of type %s but expected a value of type %s."
        (ttos rep.obtained) (ttos rep.expected)
  | If_branch_ill_typed b ->
      fmt "Conditional statement %s branch is ill typed."
        (if b then "first" else "second")

let report exp obt kind =
  let rep = {
    expected = exp;
    obtained = obt;
    kind = kind
  } in
  print_endline (pprint rep);
  Error rep

let propagate rep = Error rep

let report_symbol_resolv err =
  report None None (Sym_res_err err)

