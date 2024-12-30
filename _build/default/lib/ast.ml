open Symbol
open Type


type expr =
  (* Constants & symbols *)
    Cst of int
  | True
  | False
  | Loc of symbol
  | This

  (* Arithmetic operators *)
  | Add of expr * expr
  | Mul of expr * expr
  | Div of expr * expr
  | Mod of expr * expr
  | Min of expr * expr
  | Neg of expr

  (* Comparison operators *)
  | Eq of expr * expr
  | Neq of expr * expr
  | Lne of expr * expr
  | Leq of expr * expr

  (* Logic operators *)
  | Con of expr * expr
  | Dis of expr * expr
  | Not of expr

  (* OO operations *)
  | Inst of symbol * expr list
  | Call of symbol * symbol * expr list


type instr =
    Print  of expr
  | Set    of symbol * expr
  | If     of expr * instr list * instr list
  | While  of expr * instr list
  | Ret    of expr
  | Ignore of expr


type var
type attr
type meth
type cls


type decl =
    Var    of symbol * typ
  | Attr   of symbol * typ
  | Method of symbol * typ * decl list * decl list * instr list
  | Class  of symbol * decl list * decl list

