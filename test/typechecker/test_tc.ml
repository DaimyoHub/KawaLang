open Lang
open Lexing
open Environment
open Type
open Context

let get_position lexbuf =
  let pos = lexbuf.lex_curr_p in
  Printf.sprintf "Syntax error : %d:%d" 
    pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let _ =
  let lexbuf = In_channel.open_text (Sys.argv.(1)) 
    |> Lexing.from_channel
  in
  let prog =
    try
      Parser.program Lexer.token lexbuf 
    with Parser.Error -> failwith (get_position lexbuf)
  in

  print_endline "Checking classes :";
  ClassTable.iter (fun _ cls ->
    MethodTable.iter (fun _ meth ->
      let _ = Type_checker.check_method prog cls meth in ()
    ) cls.meths
  ) prog.classes;

  print_endline "Checking main :";
  let _ = Type_checker.check_seq prog (Env.create ()) Void prog.main in ()

