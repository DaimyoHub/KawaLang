
(* The type of tokens. *)

type token = 
  | WHILE
  | VOID
  | VAR
  | TRUE
  | TIMES
  | THIS
  | SET
  | SEMI
  | RPAR
  | RETURN
  | PRINT
  | PLUS
  | OR
  | NUM of (int)
  | NOT
  | NEW
  | NEQUALS
  | MODULO
  | MINUS
  | METHOD
  | MAIN
  | LPAR
  | LESS_EQUALS
  | LESS
  | INT
  | IF
  | IDENT of (string)
  | FALSE
  | EQUALS
  | EOF
  | END
  | ELSE
  | DOT
  | DIVIDES
  | COMMA
  | CLS of (string)
  | CLASS
  | BOOL
  | BEGIN
  | ATTR
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Context.prog_ctx)
