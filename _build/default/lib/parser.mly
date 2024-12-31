%{

  (*open Lexing*)
  open Abstract_syntax
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

%token PLUS MINUS TIMES DIVIDES MODULO 
%token AND OR NOT
%token EQUALS NEQUALS LESS LESS_EQUALS

%token LPAR RPAR BEGIN END SEMI
%token COMMA
%token DOT
%token PRINT
%token EOF
%token IF ELSE WHILE RETURN
%token TRUE FALSE

%token <string> IDENT
%token VAR
%token SET
%token <int> NUM

%nonassoc SET
%left NEQUALS EQUALS LESS_EQUALS LESS
%left AND OR
%left NOT
%left MODULO
%left MINUS
%left PLUS
%left DIVIDES
%left TIMES


%start program
%type <prog_ctx> program

%%

var_decl:
| VAR t=typ name=IDENT SEMI { { sym = Sym name; typ = t; data = No_data } }

program:
| glb=list(var_decl) cls=list(class_def) MAIN BEGIN main=list(instr) END EOF
    {{
      classes = 
        List.fold_left (
          fun acc (x : class_def) ->
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
| ATTR t=typ name=IDENT SEMI { { sym = Sym name; typ = t; data = No_data } }
;

param_def:
| t=typ name=IDENT COMMA others=param_def
    { { sym = Sym name; typ = t; data = No_data } :: others }
| t=typ name=IDENT
    { [{ sym = Sym name; typ = t; data = No_data }] }
;

method_def:
| METHOD t=typ name=IDENT LPAR params=param_def RPAR BEGIN locals=list(var_decl) code=list(instr) END
    {{
      sym = Sym name;
      ret_typ = t;
      params = 
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
| METHOD t=typ name=IDENT LPAR RPAR BEGIN locals=list(var_decl) code=list(instr) END
    {{
      sym = Sym name;
      ret_typ = t;
      params = Env.create ();
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
          fun acc (x : method_def) ->
            MethDefTable.add acc x.sym x;
            acc
        ) (MethDefTable.create ()) meths
    }}

(* ADD ATTR SET *)
instr:
| PRINT LPAR e=expr RPAR SEMI
    { Print(e) }
| name=IDENT SET e=expr SEMI
    { Set (Sym name, e) }
| obj=IDENT DOT attr=IDENT SET e=expr
    { Set (Sym (obj ^ "." ^ attr), e) }
| IF LPAR cond=expr RPAR BEGIN is1=list(instr) END ELSE BEGIN is2=list(instr) END
    { If (cond, is1, is2) }
| WHILE LPAR cond=expr RPAR BEGIN seq=list(instr) END
    { While (cond, seq) }
| RETURN e=expr SEMI
    { Ret e }
| e=expr SEMI
    { Ignore e }
;

args:
| e=expr COMMA others=args { e :: others }
| e=expr                   { [e] }
;

expr:
| LPAR e=expr RPAR                                  { e }
| n=NUM                                             { Cst n }
| TRUE                                              { True }
| FALSE                                             { False }
| name=IDENT                                        { Loc (Sym name) }
| THIS                                              { Loc (Sym "this") }
| obj=IDENT DOT attr=IDENT                          { Loc (Sym (obj ^ "dot" ^ attr)) }

| lhs=expr     PLUS   rhs=expr                      { Add (lhs, rhs) }
| lhs=expr    TIMES    rhs=expr                     { Mul (lhs, rhs) }
| lhs=expr   DIVIDES   rhs=expr                     { Div (lhs, rhs) }
| lhs=expr    MODULO   rhs=expr                     { Mod (lhs, rhs) }
| lhs=expr    MINUS    rhs=expr                     { Min (lhs, rhs) }
| MINUS e=expr                                      { Neg e }

| lhs=expr    EQUALS   rhs=expr                     { Eq  (lhs, rhs) }
| lhs=expr   NEQUALS   rhs=expr                     { Neq (lhs, rhs) }
| lhs=expr     LESS    rhs=expr                     { Lne (lhs, rhs) }
| lhs=expr LESS_EQUALS rhs=expr                     { Leq (lhs, rhs) }

| lhs=expr     AND     rhs=expr                     { Con (lhs, rhs) }
| lhs=expr      OR     rhs=expr                     { Dis (lhs, rhs) }
| NOT e=expr                                        { Not e }

| NEW name=IDENT LPAR args=args RPAR                { Inst (Sym name, args) }
| NEW name=IDENT LPAR RPAR                          { Inst (Sym name, []) }
| caller=IDENT DOT callee=IDENT LPAR args=args RPAR { Call (Sym caller, Sym callee, args) }
| caller=IDENT DOT callee=IDENT LPAR RPAR           { Call (Sym caller, Sym callee, []) }
;

