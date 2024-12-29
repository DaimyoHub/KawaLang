(*open Eval*)
open Ast
open Ctx

type frame = {
  mutable code : instr list;
  caller_id    : int;
  id           : int;
  params       : LocalEnv.t;
}

let alloc_initial_frame () =
  {
    code        = [];
    caller_id   = -1; 
    id          = 0;
    params      = LocalEnv.create ();
  }

(*
 * It is necessary to wrap the Frame.t type because of the field 'id', which
 * must be unique for each frame.
 *)
let alloc_from_frame =
  let id_counter = ref 0 in
  fun caller_frame -> (
    incr id_counter;
    {
      code      = [];
      caller_id = caller_frame.id; 
      id        = !id_counter;
      params    = LocalEnv.create ();
    }
  )

let bind_code =
  let code_enabled_tag = ref false in
  fun code frame ->
    if !code_enabled_tag then
      frame
    else (
      frame.code <- code;
      code_enabled_tag := true;
      frame
    )

let add_parameter s v call =
  LocalEnv.add call.params s v;
  call

let add_params params call =
  List.iter (fun (s, v) -> let _ = add_parameter s v call in ()) params;
  call
   
