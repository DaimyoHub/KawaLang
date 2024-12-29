%{

  open Lexing
  open Ast

%}

(* Types *)
%token <int> INT
%token <bool> BOOL
%token VOID

%token MAIN

(* Object related *)
%token CLASS
%token ATTR
%token THIS
%token NEW
%token METHOD

%token LPAR RPAR BEGIN END SEMI
%token PRINT
%token EOF
%token IF ELSE WHILE RETURN
%token TRUE FALSE

%token <string> IDENT
%token VAR

%start program
%type <Ast.t> program

%%

program:
| MAIN BEGIN main=list(instruction) END EOF
    { {classes=[]; globals=[]; main} }
;

instruction:
| PRINT LPAR e=expression RPAR SEMI { Print(e) }
;

expression:
| n=INT { Int(n) }
;
