open Symbol
open Abstract_syntax
open Type

module type Table = sig
  type t
  type k
  type v

  val create : unit -> t
  val add : t -> k -> v -> unit
  val rem : t -> k -> v option
  val get : t -> k -> v option
  val raw : t -> (k, v) Hashtbl.t
  val iter : (k -> v -> unit) -> t -> unit
  val merge : t list -> t option
end

module type Value = sig
  type t
end

module Make (V : Value) :
  Table
    with type v = V.t
     and type k = symbol
     and type t = (symbol, V.t) Hashtbl.t = struct
  type t = (symbol, V.t) Hashtbl.t
  type k = symbol
  type v = V.t

  let create () = Hashtbl.create 10

  let add env k v =
    try
      let _ = Hashtbl.find env k in
      Hashtbl.replace env k v
    with _ -> Hashtbl.add env k v

  let rem env k =
    try
      let v = Hashtbl.find env k in
      Hashtbl.remove env k;
      Some v
    with Not_found -> None

  let get env k = try Some (Hashtbl.find env k) with Not_found -> None
  let raw env = env
  let iter f env = Hashtbl.iter f (raw env)

  let rec merge envs =
    match envs with
    | [] -> Some (create ())
    | x :: s ->
        Hashtbl.fold
          (fun k v acc ->
            match acc with
            | Some r -> (
                try
                  let _ = Hashtbl.find r k in
                  None
                with _ ->
                  Hashtbl.add r k v;
                  Some r)
            | None -> None)
          (raw x) (merge s)
end

type data = No_data | Expr of expr | Obj of (symbol, typ * data) Hashtbl.t
type loc = { sym : symbol; typ : Type.typ; data : data }

let get_object_attributes loc =
  match loc.data with
  | Obj attrs -> attrs
  | _ -> raise (Invalid_argument "arg is not an object")

module Env : Table with type v = loc and type k = symbol = Make (struct
  type t = loc
end)
