(*
open Lang.Type_checker
open Lang.Ctx
open Lang.Ast


(*
let () =
  let ctx = { vars = LocalEnv.create (); classes = ClsDefTable.create () } in
  LocalEnv.add ctx.vars (Sym "test") { t = Bool; data = Some (Cst 8) };
  let is = [
    Set (Sym "test", Cst 0);
    If (True,
      [Set (Sym "test", Cst 1)],
      [Set (Sym "test", Cst (-1))]);
    Ret (Add (Loc (Sym "test"), Cst 4))
  ] in
  let _ = check_seq ctx Int is in ()
*)
*)
