open Sym
open Ast
open Type

type sym_res_err_kind = 
  | Class_not_found     of symbol
  | Loc_not_found       of symbol
  | Class_without_ctor  of symbol
  | Method_not_in_class of symbol * symbol
  | Not_loc             of expr


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

let sym_res_err_to_str err =
  let fmt = Printf.sprintf in
  match err with
    Class_not_found (Sym s) -> fmt "%s is not a class" s
  | Loc_not_found (Sym s) -> fmt "%s is not a variable nor an attribute" s
  | Class_without_ctor (Sym s) -> fmt "Constructor of the class %s is not defined" s
  | Method_not_in_class (Sym c, Sym m) -> fmt "Method %s is not defined in class %s" m c
  | Not_loc _ -> "Expression does not correspond to variable nor attribute"

let typ_err_to_str rep =
  let fmt = Printf.sprintf in
  match rep.kind with
    Sym_res_err err -> sym_res_err_to_str err
  | Lhs_ill_typed _ -> fmt "LHS is ill typed : expected %s, obtained %s" (ttos rep.expected) (ttos rep.obtained)
  | Rhs_ill_typed _ -> fmt "RHS is ill typed : expected %s, obtained %s" (ttos rep.expected) (ttos rep.obtained)
  | Expr_ill_typed _ -> "Expression is ill typed"
  | Cond_not_bool _ -> "Condition expression is not a predicate"
  | Void_method_return -> "Method typed as void should not return"
  | Typed_method_not_return -> "Typed method should return"
  | Set_ill_typed (Sym s, _) -> fmt "Cannot set variable '%s' typed as %s with a value of type %s" s (ttos rep.expected) (ttos rep.obtained)
  | Print_not_int _ -> "Argument of print is not of type int"
  | Unexpected_args (Sym s) -> fmt "Calling %s method with too much arguments" s
  | Expected_args (Sym s) -> fmt "Missing arguments to call %s method" s
  | Arg_ill_typed (Sym s, _) -> fmt "Argument type (%s) does not correspond to parameter type (%s) of %s method" (ttos rep.obtained) (ttos rep.expected) s
  | Loc_type_not_user_def (Sym s) -> fmt "Variable %s is not an object" s
  | Unexpected_type _ -> "Unexpected type :"
  | Expected_void_instr _ -> "Expected void instruction"
  | Ill_typed _ -> "Instruction is ill typed"

let report_typ_err exp obt kind =
  let rep = {
    expected = exp;
    obtained = obt;
    kind = kind
  } in
  print_endline (typ_err_to_str rep);
  Error rep

let propagate_typ_err rep = Error rep

let report_sym_res_err err =
  report_typ_err None None (Sym_res_err err)

