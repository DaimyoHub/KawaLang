open Context
open Environment
open Symbol
open Type_error


(*
 * Expands object globals attributes, including them in a result environment.
 *)
let map_env ctx env =
  let res = Env.create () in
  Env.iter (fun k v ->
    match v.typ with
      Cls cls_sym -> (
        match ClassTable.get ctx.classes cls_sym with
          Some cls -> 
            Env.iter (fun a b ->
              let nsym = 
                let Sym attr_name = a and Sym obj_name = k in
                Sym (obj_name ^ "." ^ attr_name)
              in
              Env.add res nsym { sym = nsym; typ = b.typ; data = No_data }
            ) cls.attrs
        | None -> let _ =
            report None (Some v.typ) (Class_type_not_exist cls_sym) in ()
      )
    | _ -> Env.add res k v
  ) env;
  res


(*
 * make_type_checking_env ctx class_def method_def
 *
 * Builds up a calling environment allowing the type checker to properly check if the
 * code of a method is well-typed.
 *
 * It performs the following computations :
 *   - for each param, if its type is built-in, add it to the result environment, if it
 *     is an object, add its attributes to the environment
 *   - for each global, do the same
 *   - add each attribute of the caller to the result environment
 *)
let make_type_checking_env ctx class_def method_def =
  (*
   * We rewrite attributes of the caller : "caller.attr" (caller ctx) -> "this.attr"
   * (calling ctx)
   *)
  let map_attrs attrs =
    let res = Env.create () in
    Env.iter (fun _ v ->
      let nsym = 
        let Sym name = v.sym in Sym ("this." ^ name)
      in
      Env.add res nsym { sym = nsym; typ = v.typ; data = No_data }
    ) attrs;
    res
  in

  (*
   * We copy built-in typed params and we rewrite object params attributes : "param" 
   * (caller ctx) -> "param.attr1; param.attr2..." (calling ctx)
   *)
  let map_params params =
    let res = Env.create () in
    List.iter (fun (k, v) ->
      match v.typ with
        Cls cls_sym -> (
          match ClassTable.get ctx.classes cls_sym with
            Some cls -> 
              Env.iter (fun a b ->
                let nsym = 
                  let Sym attr_name = a and Sym obj_name = k in
                  Sym (obj_name ^ "." ^ attr_name)
                in
                Env.add res nsym { sym = nsym; typ = b.typ; data = No_data }
              ) cls.attrs
          | None -> let _ =
              report None (Some v.typ) (Class_type_not_exist cls_sym) in ()
        )
      | _ -> Env.add res k v
    ) params;
    res
  in

  Env.merge [
    map_env ctx ctx.globals;
    map_env ctx method_def.locals;
    map_params method_def.params;
    map_attrs class_def.attrs
  ]


let make_interpreting_env ctx class_def caller callee args =
  (*
   * We rewrite attributes of the caller : "caller.attr" (caller ctx) -> "this.attr"
   * (calling ctx)
   *)
  let map_attrs attrs =
    let res = Env.create () in
    Env.iter (fun _ v ->
      let nsym = 
        let Sym name = v.sym in Sym ("this." ^ name)
      in
      Env.add res nsym { sym = nsym; typ = v.typ; data = v.data }
    ) attrs;
    res
  in

  (*
   * We copy built-in typed params and we rewrite object params attributes : "param" 
   * (caller ctx) -> "param.attr1; param.attr2..." (calling ctx)
   *)
  let map_params params args =
    let res = Env.create () in
    let rec iter params args =
      match params, args with
        [], [] -> ()
      | (k, v) :: s, arg :: t -> (
          match v.typ with
            Cls cls_sym -> (
              match ClassTable.get ctx.classes cls_sym with
                Some cls -> 
                  Env.iter (fun a b ->
                    let nsym = 
                      let Sym attr_name = a and Sym obj_name = k in
                      Sym (obj_name ^ "." ^ attr_name)
                    in
                    Env.add res nsym { sym = nsym; typ = b.typ; data = Expr arg };
                    iter s t
                  ) cls.attrs
              | None -> let _ =
                  report None (Some v.typ) (Class_type_not_exist cls_sym) in ()
            )
          | _ -> (
              Env.add res k { sym = k; typ = v.typ; data = Expr arg };
              iter s t
            )
        )
      | _ -> failwith "Unreachable : calling ill-typed"
    in
    iter params args;
    res
  in

  Env.merge [
    map_params callee.params args;
    map_env ctx ctx.globals;
    map_env ctx callee.locals;
    map_attrs (
      match caller with
        None -> class_def.attrs
      | Some c -> c.attrs
    )
  ]
 
