{

  open Lexing
  open Parser

  exception LexicalError of string

  let keyword_or_ident =
    let h = Hashtbl.create 17 in
      List.iter (fun (s, k) -> Hashtbl.add h s k)
        [
          "print",     PRINT;
          "main",      MAIN;
          "class",     CLASS;
          "var",       VAR;
          "attribute", ATTR;
          "int",       INT;
          "bool",      BOOL;
          "void",      VOID;
          "true",      TRUE;
          "false",     FALSE;
          "this",      THIS;
          "new",       NEW;
          "if",        IF;
          "else",      ELSE;
          "while",     WHILE;
          "return",    RETURN;
          "method",    METHOD
        ];
      fun s ->
        try  Hashtbl.find h s
        with Not_found -> IDENT(s)
        
}

let digit   = ['0'-'9']
let number  = ['-']? digit+
let alpha   = ['a'-'z' 'A'-'Z']
let ident   = ['a'-'z' '_'] (alpha | '_' | digit)*

let white   = [' ' '\t' '\r']+
let newline = '\n' | '\r' | "\r\n"

let uop = '-' | '!'
let bop = '+' | '-' | '*' | '/' | '%' | "==" | "!=" | '<' | "<=" | "&&" | "||"
  
rule token = parse
  (* Newline and whitespaces *)
  | newline              { new_line lexbuf; token lexbuf }
  | white                { token lexbuf }

  (* One line and multi-line comment *)
  | "//" [^ '\n']* "\n"  { new_line lexbuf; token lexbuf }
  | "/*"                 { comment lexbuf; token lexbuf }

  | number as n          { NUM(int_of_string n) }
  | ident as id          { keyword_or_ident id }

  | ","                  { COMMA }
  | ";"                  { SEMI }
  | "("                  { LPAR }
  | ")"                  { RPAR }
  | "{"                  { BEGIN }
  | "}"                  { END }

  (* Unary and binary operators *)
  | '-'                  { MINUS }
  | '!'                  { NOT }
  | '+'                  { PLUS }
  | '*'                  { TIMES }
  | '/'                  { DIVIDES }
  | '%'                  { MODULO }
  | "=="                 { EQUALS }
  | "!="                 { NEQUALS }
  | '<'                  { LESS }
  | "<="                 { LESS_EQUALS }
  | "&&"                 { AND }
  | "||"                 { OR }

  (* Lexer cannot correctly parse the current lexbuf *)
  | _                    { raise (Error ("unknown character : " ^ lexeme lexbuf)) }

  | eof                  { EOF }

and comment = parse
  | "*/"                 { () }
  | _                    { comment lexbuf }
  | eof                  { raise (Error "unterminated comment") }

