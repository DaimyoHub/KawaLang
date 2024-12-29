open Ctx
open Grammar


(*
 * load_variables context vars
 *
 * Loads the given variable declaration list in the given context.
 *)
let rec load_variables ctx = function
    [] -> ()
  | Var (sym, t) :: s -> (
      let var = { t = t; data = None } in
      LocalEnv.add ctx.vars sym var;
      load_variables ctx s
    )
  | _ -> failwith "trying to load non variable structures"


(*
 * load_attributes class_ctx attrs
 * 
 * Load the given attribute declaration list in the given class context.
 *)
let rec load_attributes class_ctx = function
    [] -> ()
  | Attr (sym, t) :: s -> (
      LocalEnv.add class_ctx.attrs sym { t = t; data = None };
      load_attributes class_ctx s
    )
  | _ -> failwith "trying to load non attribute structures"


(*
 * load_methods class_ctx methods
 * 
 * Load the given method definition list in the given class context.
 *)
let rec load_methods class_ctx = function
    [] -> ()
  | Method (sym, rt, params, locals, code) :: s ->
      let meth_ctx = {
        ret_typ = rt;
        params =
          List.map (fun p ->
            match p with
              Var (_, t) -> t
            | _ -> failwith "object is not a parameter"
          ) params;
        locals =
          List.fold_left (fun acc x ->
            match x with 
              Var (sym, typ) -> (
                LocalEnv.add acc sym { t = typ; data = None };
                acc
              )
            | _ -> failwith "object is not a variable"
          ) (LocalEnv.create ()) locals;
        code = code
      }
      in
      MethDefTable.add class_ctx.meths sym meth_ctx;
      load_methods class_ctx s
    | _ -> failwith "trying to load non method structures"


(*
 * load_classes ctx classes
 * 
 * Load the given class definition list in the given context.
 *)
let rec load_classes ctx = function
    [] -> ()
  | Class (sym, attrs, meths) :: s -> 
      let cls_ctx = {
        sym = sym;
        attrs = LocalEnv.create ();
        meths = MethDefTable.create ()
      } in
      load_attributes cls_ctx attrs;
      load_methods cls_ctx meths;
      ClsDefTable.add ctx.classes sym cls_ctx;
      load_classes ctx s
  | _ -> failwith "trying to load non class structures"

