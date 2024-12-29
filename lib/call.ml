open Frame

type caller = Caller of frame

(*
let () =
  | Caller (ctx_frame) ->
      let frame = Frame.alloc_from_frame ctx_frame
        |> Frame.add_params params
        |> Frame.bind_code code
      in
      eval @@ Caller frame
*)
