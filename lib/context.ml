open Abstract_syntax
open Environment
open Symbol

type method_def = {
  sym     : symbol;
  ret_typ : Type.typ;
  params  : (symbol * loc) list;
  locals  : Env.t;
  code    : instr list
}

module MethDefTable : Env_t 
    with type v = method_def
    and  type k = symbol
  = Make (struct type t = method_def end)

type class_def = {
  sym : symbol;
  attrs : Env.t;
  meths : MethDefTable.t
}

module ClsDefTable : Env_t
    with type v = class_def 
    and  type k = symbol
  = Make (struct type t = class_def end)

type prog_ctx = {
  globals : Env.t;
  classes : ClsDefTable.t;
  main    : instr list
}

