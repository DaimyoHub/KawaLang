%{

  (*open Lexing*)
  open Abstract_syntax
  open Context
  open Environment
  open Symbol
  open Type

%}

(* Types *)
%token INT
%token BOOL
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
%token EQUALS NOT_EQUALS LESS LESS_EQUALS GREATER GREATER_EQUALS

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

%left NOT_EQUALS EQUALS LESS_EQUALS LESS GREATER GREATER_EQUALS
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
            ClassTable.add acc x.sym x;
            acc
        ) (ClassTable.create ()) cls;
      globals =
        List.fold_left (
          fun acc x ->
            Env.add acc x.sym x;
            acc
        ) (Env.create ()) glb;
      main = main
    }}
;

typ:
| INT        { Int }
| BOOL       { Bool }
| VOID       { Void }
| name=IDENT { Cls (Sym name) }
;

attr_decl:
| ATTR t=typ name=IDENT SEMI { { sym = Sym name; typ = t; data = No_data } }
;

param_def:
| t=typ name=IDENT COMMA others=param_def
    { (Sym name, { sym = Sym name; typ = t; data = No_data }) :: others }
| t=typ name=IDENT
    { [Sym name, { sym = Sym name; typ = t; data = No_data }] }
;

method_def:
| METHOD t=typ name=IDENT LPAR params=param_def RPAR BEGIN locals=list(var_decl) code=list(instr) END
    {{
      sym = Sym name;
      ret_typ = t;
      params = List.rev params;
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
      params = [];
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
            MethodTable.add acc x.sym x;
            acc
        ) (MethodTable.create ()) meths
    }}

(* ADD ATTR SET *)
instr:
| PRINT LPAR e=expr RPAR SEMI
    { Print(e) }
| name=IDENT SET e=expr SEMI
    { Set (Sym name, e) }
| THIS DOT attr=IDENT SET e=expr SEMI
    { Set (Sym ("this." ^ attr), e) }
| obj=IDENT DOT attr=IDENT SET e=expr SEMI
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
| LPAR al=separated_list(COMMA, expr) RPAR { al }
;

expr:
| LPAR e=expr RPAR                                  { e }
| n=NUM                                             { Cst (n) }
| TRUE                                              { True }
| FALSE                                             { False }
| name=IDENT                                        { Loc (Sym name) }
| THIS                                              { Loc (Sym "this") }
| THIS DOT attr_or_meth=IDENT args=option(args)
    {
      match args with
        None   -> Loc (Sym ("this." ^ attr_or_meth))
      | Some l -> Call (Sym "this", Sym attr_or_meth, l)     
    }
| obj=IDENT DOT attr_or_meth=IDENT args=option(args) 
    {
      match args with
        None   -> Loc (Sym (obj ^ "." ^ attr_or_meth))
      | Some l -> Call (Sym obj, Sym attr_or_meth, l)
    }

| lhs=expr     PLUS   rhs=expr                      { Add (lhs, rhs) }
| lhs=expr    TIMES    rhs=expr                     { Mul (lhs, rhs) }
| lhs=expr   DIVIDES   rhs=expr                     { Div (lhs, rhs) }
| lhs=expr    MODULO   rhs=expr                     { Mod (lhs, rhs) }
| lhs=expr    MINUS    rhs=expr                     { Min (lhs, rhs) }
| MINUS e=expr                                      { Neg e }

| lhs=expr    EQUALS   rhs=expr                     { Eq  (lhs, rhs) }
| lhs=expr  NOT_EQUALS rhs=expr                     { Neq (lhs, rhs) }
| lhs=expr     LESS    rhs=expr                     { Lne (lhs, rhs) }
| lhs=expr LESS_EQUALS rhs=expr                     { Leq (lhs, rhs) }
| lhs=expr    GREATER  rhs=expr                     { Gne (lhs, rhs) }
| lhs=expr GREATER_EQUALS rhs=expr                  { Geq (lhs, rhs) }

| lhs=expr     AND     rhs=expr                     { Con (lhs, rhs) }
| lhs=expr      OR     rhs=expr                     { Dis (lhs, rhs) }
| NOT e=expr                                        { Not e }

| NEW name=IDENT args=args                          { Inst (Sym name, args) }
;

