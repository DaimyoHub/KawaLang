open Lang


let _ =
  let lexbuf = In_channel.open_text "test.kwa" 
    |> Lexing.from_channel
  in
  let prog = Parser.program Lexer.token lexbuf in
  match Type_checker.check_seq prog (Environment.Env.create ()) Type.Void prog.main with
    Ok _ -> print_endline "yay"
  | Error _ -> print_endline "nop"
