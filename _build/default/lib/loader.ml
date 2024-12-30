(*
open Context
open Environment
open Ast


(*
 * load_variables context vars
 *
 * Loads the given variable declaration list in the given context.
 *)
let rec load_variables env = function
    [] -> ()
  | Var (sym, t) :: s -> (
      let var = { sym = sym; typ = t; data = No_data } in
      LocalEnv.add env sym var;
      load_variables env s
    )
  | _ -> failwith "trying to load non variable structures"


(*
 * load_attributes class_ctx attrs
 * 
 * Load the given attribute declaration list in the given class context.
 *)
let rec load_attributes (class_ctx : class_def) = function
    [] -> ()
  | Attr (sym, t) :: s -> (
      LocalEnv.add class_ctx.attrs sym { sym = sym; typ = t; data = No_data };
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
        sym = sym;
        ret_typ = rt;
        params =
          List.fold_left (
            fun acc x -> 
              let _ = match x with
                  Var (sym, t) ->
                    LocalEnv.add acc sym { sym = sym; typ = t; data = No_data }
                | _ -> raise (Invalid_argument "Expected a list of var decls")
              in acc
          ) (LocalEnv.create ()) params;
        locals =
          List.fold_left (
            fun acc x -> 
              let _ = match x with
                  Var (sym, t) ->
                    LocalEnv.add acc sym { sym = sym; typ = t; data = No_data }
                | _ -> raise (Invalid_argument "Expected a list of var decls")
              in acc
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
      let class_ctx = {
        sym = sym;
        attrs = LocalEnv.create ();
        meths = MethDefTable.create ()
      } in
      load_attributes class_ctx attrs;
      load_methods class_ctx meths;
      ClsDefTable.add ctx.classes sym class_ctx;
      load_classes ctx s
  | _ -> failwith "trying to load non class structures"


*)
