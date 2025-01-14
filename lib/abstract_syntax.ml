open Symbol
open Type

type expr =
  (* Constants & symbols *)
  | Cst of int
  | True
  | False
  | Loc of symbol
  | Attr of symbol * symbol
  | StaticAttr of typ * symbol
  | This
  (* Arithmetic operators *)
  | Add of expr * expr
  | Mul of expr * expr
  | Div of expr * expr
  | Mod of expr * expr
  | Min of expr * expr
  | Neg of expr
  (* Equality operators *)
  | Eq of expr * expr
  | Neq of expr * expr
  | StructEq of expr * expr
  | StructNeq of expr * expr
  | InstanceOf of expr * typ
  (* Comparison operators *)
  | Lne of expr * expr
  | Leq of expr * expr
  | Gne of expr * expr
  | Geq of expr * expr
  (* Logic operators *)
  | Con of expr * expr
  | Dis of expr * expr
  | Not of expr
  (* OO operations *)
  | Inst of symbol * expr list
  | Call of symbol * symbol * expr list
  | StaticCall of typ * symbol * expr list
  | Cast of expr * typ

type instr =
  | Print of expr
  | Set of expr * expr
  | If of expr * instr list * instr list
  | While of expr * instr list
  | Ret of expr
  | Ignore of expr
  | Init of symbol * typ * expr
