open Sym
open Type
open Ast


type var
type attr
type meth
type cls


type decl =
    Var    of symbol * typ
  | Attr   of symbol * typ
  | Method of symbol * typ * decl list * decl list * instr list
  | Class  of symbol * decl list * decl list


type prog = Prog of decl list * decl list * instr list

