open Context
open Environment
open Symbol
open Type_error


let make_type_checking_env ctx class_def method_def =
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

  let map_globals globals =
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
    ) globals;
    res
  in

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
    map_globals method_def.locals;
    map_params method_def.params;
    map_attrs class_def.attrs
  ]

