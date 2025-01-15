open Lang
open Lexing
open Context
open Syntax_error

let get_position lexbuf =
  let pos = lexbuf.lex_curr_p in
  Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let kawai file =
  let lexbuf = Lexing.from_channel (In_channel.open_text file) in
  try
    let prog = Parser.program Lexer.token lexbuf in
    Type_checker.check_prog prog;
    Interpreter.exec_prog prog
  with
  | Type_checker.Class_type_error class_def ->
      let (Sym class_name) = class_def.sym in
      print_endline (Printf.sprintf "Class %s is ill-typed." class_name);
      VNull
  | Type_checker.Main_type_error ->
      print_endline "Main block is ill-typed.";
      VNull
  | Interpreter.Exec_error pos ->
      print_endline (Printf.sprintf "Execution error : %s" pos);
      VNull
  | Parser.Error ->
      print_endline (Printf.sprintf "Syntax error : %s" (get_position lexbuf));
      VNull
  | Missing_semi ->
      print_endline (Printf.sprintf "Missing semicolon : %s" (get_position lexbuf));
      VNull

let () =
  try
    let relative_path = Sys.argv.(1) in
    let _ = kawai relative_path in ()
  with
  | _ -> print_endline "Command line : kawai 'path/to/file.kwa'"
