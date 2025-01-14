%{

  (*open Lexing*)
  open Abstract_syntax
  open Context
  open Environment
  open Symbol
  open Type
  open Syntax_error

  let env_of_list l =
    List.fold_left (
      fun acc x ->
        Env.add acc x.sym x;
        acc
    ) (Env.create ()) l

  let meth_table_of_list l =
    List.fold_left (
      fun acc (x : method_def) ->
        MethodTable.add acc x.sym x;
        acc
    ) (MethodTable.create ()) l

  let class_table_of_list l =
    List.fold_left (
      fun acc (x : class_def) ->
        ClassTable.add acc x.sym x;
        acc
    ) (ClassTable.create ()) l

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
%token EXTENDS
%token INSTANCEOF
%token CAST
%token STATIC
%token DOUBLE_COL

%token PLUS MINUS TIMES DIVIDES MODULO 
%token AND OR NOT
%token EQUALS NOT_EQUALS LESS LESS_EQUALS GREATER GREATER_EQUALS STRUCT_EQ STRUCT_NEQ

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

%left NOT_EQUALS EQUALS LESS_EQUALS LESS GREATER GREATER_EQUALS STRUCT_EQ STRUCT_NEQ
%left AND OR
%left NOT
%nonassoc INSTANCEOF
%left MODULO
%left MINUS
%left PLUS
%left DIVIDES
%left TIMES

%start program
%type <prog_ctx> program

%%

program:
| glb=list(var_decl)
  cls=list(class_def)
  MAIN BEGIN
    main=list(instr)
  END
  EOF
    {
      {
        classes = class_table_of_list cls;
        globals = env_of_list glb;
        main    = main
      }
    }
;

typ:
| INT        { Int }
| BOOL       { Bool }
| VOID       { Void }
| name=IDENT { Cls (Sym name) }
;

semi: SEMI { () };

var_init:
| VAR typ IDENT SET error { raise Missing_semi }
| VAR t=typ name=IDENT SET e=expr semi
    {
      (Sym name, t, e)
    }
;

var_decl:
| VAR typ IDENT error { raise Missing_semi }
| VAR t=typ name=IDENT semi
    {
      make_loc name t
    }
;

attr_decl:
| ATTR typ IDENT error { raise Missing_semi }
| ATTR t=typ name=IDENT semi
    {
      make_loc name t
    }
;

(*
static_attr_decl:
| STATIC ATTR t=typ name=IDENT SEMI           { { sym = Sym name; typ = t; data = No_data } }
;
*)

param:
| t=typ name=IDENT
    {
      Sym name, make_loc name t
    }
;

params:
| LPAR al=separated_list(COMMA, param) RPAR
    {
      List.rev al
    }
;

static_meth_def:
| STATIC METHOD t=typ name=IDENT ps=option(params) BEGIN
    code=list(instr)
  END
    {
      {
        sym     = Sym name;
        ret_typ = t;
        params  = (
          match ps with
            None -> []
          | Some l -> l
        );
        code    = code
      }
    }
;

method_def:
| METHOD t=typ name=IDENT ps=option(params) BEGIN
    code=list(instr)
  END
    {
      {
        sym     = Sym name;
        ret_typ = t;
        params  = (
          match ps with
          | None -> []
          | Some l -> l
        );
        code    = code
      }
    }
;

super:
| EXTENDS super=IDENT { super }
;

class_def:
| CLASS name=IDENT s=option(super) BEGIN
    (*static_attrs=list(static_attr_decl)*)
    attrs=list(attr_decl)
    static_meths=list(static_meth_def)
    meths=list(method_def)
  END
    {
      {
        static_attrs = Env.create ();

        sym          = Sym name;
        attrs        = env_of_list attrs;
        meths        = meth_table_of_list meths;
        static_meths = meth_table_of_list static_meths;
        super        = (
          match s with
            None -> None
          | Some s -> Some (Sym s)
        )
      }
    }

instr:
| v=var_init
    {
      let s, t, e = v in Init (s, t, e)
    }
| PRINT LPAR expr RPAR error { raise Missing_semi }
| PRINT LPAR e=expr RPAR semi
    {
      Print(e)
    }
| IDENT SET expr error { raise Missing_semi }
| name=IDENT SET e=expr semi 
    {
      Set (Loc (Sym name), e)
    }
| THIS DOT IDENT SET expr error { raise Missing_semi}
| THIS DOT attr=IDENT SET e=expr semi
    {
      Set (Attr (Sym "this", Sym attr), e)
    }
| IDENT DOT IDENT SET expr error { raise Missing_semi }
| obj=IDENT DOT attr=IDENT SET e=expr semi
    {
      Set (Attr (Sym obj, Sym attr), e)
    }
| RETURN expr error { raise Missing_semi }
| RETURN e=expr semi
    {
      Ret e
    }
| expr error { raise Missing_semi }
| e=expr semi
    {
      Ignore e
    }
| IF LPAR cond=expr RPAR BEGIN
    is1=list(instr)
  END ELSE BEGIN
    is2=list(instr)
  END
    {
      If (cond, is1, is2)
    }
| WHILE LPAR cond=expr RPAR BEGIN
    seq=list(instr)
  END
    {
      While (cond, seq)
    }
;

args:
| LPAR al=separated_list(COMMA, expr) RPAR { al }
;

object_expr:
| name=IDENT                                        { Loc (Sym name) }
| THIS                                              { Loc (Sym "this") }
| NEW name=IDENT LPAR al=separated_list(COMMA, expr) RPAR { Inst (Sym name, al) }
| THIS DOT attr_or_meth=IDENT args=option(args)
    {
      match args with
        None   -> Attr (Sym "this", Sym attr_or_meth)
      | Some l -> Call (Sym "this", Sym attr_or_meth, l)     
    }
| obj=IDENT DOT attr_or_meth=IDENT args=option(args) 
    {
      match args with
        None   -> Attr (Sym obj, Sym attr_or_meth)
      | Some l -> Call (Sym obj, Sym attr_or_meth, l)
    }
| t=typ DOUBLE_COL attr_or_meth=IDENT args=option(args)
    {
      match args with
        None   -> StaticAttr (t, Sym attr_or_meth)
      | Some l -> StaticCall (t, Sym attr_or_meth, l)
    }
| c=cast_expr                                       { c }
;

cast_expr:
| CAST LPAR t=typ RPAR e=object_expr                { Cast (e, t) }
;

paren_expr:
| LPAR e=expr RPAR                                  { e }
;

expr:
| n=NUM                                             { Cst (n) }
| TRUE                                              { True }
| FALSE                                             { False }
| o=object_expr                                     { o }
| e=paren_expr                                      { e }
| lhs=expr     PLUS   rhs=expr                      { Add (lhs, rhs) }
| lhs=expr    TIMES    rhs=expr                     { Mul (lhs, rhs) }
| lhs=expr   DIVIDES   rhs=expr                     { Div (lhs, rhs) }
| lhs=expr    MODULO   rhs=expr                     { Mod (lhs, rhs) }
| lhs=expr    MINUS    rhs=expr                     { Min (lhs, rhs) }
| MINUS e=expr                                      { Neg e }

| lhs=expr    EQUALS   rhs=expr                     { Eq  (lhs, rhs) }
| lhs=expr  NOT_EQUALS rhs=expr                     { Neq (lhs, rhs) }
| lhs=expr   STRUCT_EQ rhs=expr                     { StructEq(lhs, rhs) }
| lhs=expr  STRUCT_NEQ rhs=expr                     { StructNeq(lhs, rhs) }
| e=expr    INSTANCEOF t=typ                        { InstanceOf (e, t) } 
| lhs=expr     LESS    rhs=expr                     { Lne (lhs, rhs) }
| lhs=expr LESS_EQUALS rhs=expr                     { Leq (lhs, rhs) }
| lhs=expr    GREATER  rhs=expr                     { Gne (lhs, rhs) }
| lhs=expr GREATER_EQUALS rhs=expr                  { Geq (lhs, rhs) }

| lhs=expr     AND     rhs=expr                     { Con (lhs, rhs) }
| lhs=expr      OR     rhs=expr                     { Dis (lhs, rhs) }
| NOT e=expr                                        { Not e }
;

