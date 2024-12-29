open Type
open Ast
open Ctx
open Sym

type var
type attr
type meth
type cls

type _ decl =
    Var    : symbol * typ                                                  -> var decl
  | Attr   : symbol * typ                                                  -> attr decl
  | Method : symbol * typ * (var decl) list * (var decl) list * instr list -> meth decl
  | Class  : symbol * (attr decl) list * (meth decl) list                  -> cls decl

type prog = Prog of (var decl) list * (cls decl) list * instr list

let rec load_vars ctx = function
    [] -> ()
  | Var (sym, t) :: s -> (
      let var = { t = t; data = None } in
      LocalEnv.add ctx.vars sym var;
      load_vars ctx s
    )

let rec load_attrs cls_ctx = function
    [] -> ()
  | Attr (sym, t) :: s -> (
      LocalEnv.add cls_ctx.attrs sym { t = t; data = None };
      load_attrs cls_ctx s
    )

let rec load_meths cls_ctx = function
    [] -> ()
  | Method (sym, rt, params, locals, code) :: s ->
      let meth_ctx = {
        ret_typ = rt;
        params = List.map (fun p -> let Var (_, t) = p in t) params;
        locals =
          List.fold_left (fun acc x ->
            let Var (sym, t) = x in
            LocalEnv.add acc sym { t = t; data = None };
            acc
          ) (LocalEnv.create ()) locals;
        code = code
      }
      in
      MethDefTable.add cls_ctx.meths sym meth_ctx;
      load_meths cls_ctx s

let rec load_classes ctx = function
    [] -> ()
  | Class (sym, attrs, meths) :: s -> 
      let cls_ctx = {
        sym = sym;
        attrs = LocalEnv.create ();
        meths = MethDefTable.create ()
      } in
      load_attrs cls_ctx attrs;
      load_meths cls_ctx meths;
      ClsDefTable.add ctx.classes sym cls_ctx;
      load_classes ctx s

