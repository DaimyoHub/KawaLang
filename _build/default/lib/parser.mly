%{

  open Lexing
  open Ast
  open Context
  open Environment

%}

(* Types *)
%token INT
%token BOOL
%token <string> CLS
%token VOID

%token MAIN

(* Object related *)
%token CLASS
%token ATTR
%token THIS
%token NEW
%token METHOD

%token LPAR RPAR BEGIN END SEMI
%token COMMA
%token PRINT
%token EOF
%token IF ELSE WHILE RETURN
%token TRUE FALSE

%token <string> IDENT
%token VAR
%token <int> NUM

%start program
%type <prog_ctx> program

%%

var_decl:
| VAR t=typ name=IDENT { { sym = Sym name; typ = t; data = No_data } }

program:
| glb=list(var_decl) cls=list(class_def) MAIN BEGIN main=list(instruction) END EOF
    {{
      classes = 
        List.fold_left (
          fun acc x ->
            ClsDefTable.add acc x.sym x;
            acc
        ) (ClsDefTable.create ()) cls;
      globals =
        List.fold_left (
          fun acc x ->
            Env.add acc x.sym x;
            acc
        ) (Env.create ()) glb;
      main
    }}
;

typ:
| INT      { Int }
| BOOL     { Bool }
| VOID     { Void }
| name=CLS { Cls (Sym name) }
;

attr_decl:
| ATTR t=typ name=IDENT { { sym = Sym name; typ = t; data = No_data } }
;

param_def:
| t=typ name=IDENT COMMA others=list(param_def)
    { { sym = name; typ = t; data = No_data } :: others }
| t=typ name=IDENT
    { [{ sym = name; typ = t; data = No_data }] }
;

method_def:
| METHOD t=typ name=IDENT LPAR params=param_def RPAR BEGIN locals=list(var_decl) code=list(instruction) END
    {{
      sym     = name;
      ret_typ = t;
      params  = 
        List.fold_left (
          fun acc x ->
            Env.add acc x.sym x;
            acc
        ) (Env.create ()) params;
      locals = 
        List.fold_left (
          fun acc x ->
            Env.add acc x.sym x;
            acc
        ) (Env.create ()) locals;
      code = code
    }}
;

class_def:
| CLASS name=IDENT BEGIN attrs=list(attr_decl) meths=list(method_def) END
    {{
      sym   = Sym name;
      attrs =
        List.fold_left (
          fun acc x ->
            Env.add acc x.sym x;
            acc
        ) (Env.create ()) attrs;
      meths =
        List.fold_left (
          fun acc x ->
            MethDefTable.add acc x.sym x;
            acc
        ) (MethDefTable.create ()) meths
    }}

instruction:
| PRINT LPAR e=expression RPAR SEMI { Print(e) }
;

expression:
| n=NUM { Cst(n) }
;

