open Lang
open Lexing

let get_position lexbuf =
  let pos = lexbuf.lex_curr_p in
  Printf.sprintf "Syntax error : %d:%d" 
    pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let _ =
  let lexbuf = In_channel.open_text "test.kwa" 
    |> Lexing.from_channel
  in
  let prog =
    try
      Parser.program Lexer.token lexbuf 
    with Parser.Error -> failwith (get_position lexbuf)
  in
  match Type_checker.check_seq prog (Environment.Env.create ()) Type.Void prog.main with
    Ok _ -> print_endline "yay"
  | Error _ -> print_endline "nop"
