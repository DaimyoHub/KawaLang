open Abstract_syntax
open Environment
open Symbol

type method_def = {
  sym : symbol;
  ret_typ : Type.typ;
  params : (symbol * loc) list;
  code : instr list;
}

module MethodTable : Table with type v = method_def and type k = symbol =
Make (struct
  type t = method_def
end)

type class_def = {
  sym : symbol;
  static_attrs : Env.t;
  attrs : Env.t;
  meths : MethodTable.t;
  static_meths : MethodTable.t;
  super : symbol option;
}

module ClassTable : Table with type v = class_def and type k = symbol =
Make (struct
  type t = class_def
end)

type prog_ctx = { globals : Env.t; classes : ClassTable.t; main : instr list }
