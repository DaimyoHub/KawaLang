open Sym

module type Env = 
  sig
    type t
    type k
    type v

    val create : unit -> t

    val add : t -> k -> v -> unit
    val rem : t -> k -> v option
    val get : t -> k -> v option
  end

module type Value = sig type t end

module Make (V : Value) : Env
    with type v = V.t
    and  type k = symbol
    and  type t = (symbol, V.t) Hashtbl.t =
  struct
    type t = (symbol, V.t) Hashtbl.t
    type k = symbol
    type v = V.t

    let create () = Hashtbl.create 10

    let add env k v =
      Hashtbl.add env k v
      
    let rem env k =
      try
        let v = Hashtbl.find env k in
        Hashtbl.remove env k;
        Some v
      with Not_found -> None

    let get env k =
      try
        Some (Hashtbl.find env k)
      with Not_found -> None  
  end

type variable = {
  t    : Type.typ;
  data : Ast.expr option
}

module LocalEnv : Env 
    with type v = variable
    and  type k = symbol 
  = Make (struct type t = variable end)

type method_def = {
  ret_typ : Type.typ;
  params  : Type.typ list;
  locals  : LocalEnv.t;
  code    : Ast.instr list
}

module MethDefTable : Env 
    with type v = method_def
    and type k = symbol
  = Make (struct type t = method_def end)

type class_def = {
  sym : symbol;
  attrs : LocalEnv.t;
  meths : MethDefTable.t
}

module ClsDefTable : Env
    with type v = class_def 
    and type k = symbol
  = Make (struct type t = class_def end)

type global_ctx = {
  vars    : LocalEnv.t;
  classes : ClsDefTable.t
}

