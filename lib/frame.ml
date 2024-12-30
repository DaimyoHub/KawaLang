(*open Eval*)
open Ctx
open Sym

type frame = {
  caller_id    : int;
  id           : int;
  caller       : symbol;
  callee       : symbol;
  locals       : LocalEnv.t;
  globals      : global_ctx
}

let alloc_initial_frame ctx =
  {
    caller_id   = -1; 
    id          = 0;
    caller      = Sym "lang";
    callee      = Sym "main";
    locals      = LocalEnv.create ();
    globals     = ctx
  }



