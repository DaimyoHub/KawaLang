
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
  | NOT_EQUALS
  | NOT
  | NEW
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
  | GREATER_EQUALS
  | GREATER
  | FALSE
  | EQUALS
  | EOF
  | END
  | ELSE
  | DOT
  | DIVIDES
  | COMMA
  | CLASS
  | BOOL
  | BEGIN
  | ATTR
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Context.prog_ctx)
