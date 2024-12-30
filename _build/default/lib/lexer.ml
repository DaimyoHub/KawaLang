# 1 "lib/lexer.mll"
 

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
        

# 37 "lib/lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\230\255\231\255\002\000\001\000\001\000\002\000\238\255\
    \240\255\241\255\003\000\244\255\245\255\246\255\247\255\248\255\
    \249\255\079\000\017\000\027\000\043\000\002\000\014\000\255\255\
    \252\255\002\000\253\255\236\255\237\255\234\255\233\255\232\255\
    \016\000\253\255\254\255\039\000\255\255";
  Lexing.lex_backtrk =
   "\255\255\255\255\255\255\024\000\024\000\020\000\024\000\255\255\
    \255\255\255\255\013\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\005\000\004\000\012\000\016\000\001\000\000\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\001\000\255\255";
  Lexing.lex_default =
   "\002\000\000\000\000\000\255\255\255\255\255\255\255\255\000\000\
    \000\000\000\000\255\255\000\000\000\000\000\000\000\000\000\000\
    \000\000\255\255\255\255\255\255\255\255\255\255\255\255\000\000\
    \000\000\025\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \034\000\000\000\000\000\255\255\000\000";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\021\000\023\000\021\000\026\000\022\000\000\000\021\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\021\000\
    \023\000\000\000\000\000\021\000\000\000\000\000\000\000\000\000\
    \021\000\010\000\021\000\000\000\000\000\007\000\004\000\030\000\
    \014\000\013\000\008\000\009\000\016\000\019\000\021\000\020\000\
    \018\000\018\000\018\000\018\000\018\000\018\000\018\000\018\000\
    \018\000\018\000\035\000\015\000\005\000\006\000\029\000\028\000\
    \027\000\018\000\018\000\018\000\018\000\018\000\018\000\018\000\
    \018\000\018\000\018\000\018\000\018\000\018\000\018\000\018\000\
    \018\000\018\000\018\000\018\000\018\000\024\000\036\000\000\000\
    \000\000\000\000\025\000\000\000\000\000\000\000\000\000\017\000\
    \000\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\012\000\003\000\011\000\031\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\000\000\000\000\000\000\000\000\017\000\000\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \001\000\000\000\255\255\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \033\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\021\000\025\000\000\000\255\255\021\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\022\000\
    \022\000\255\255\255\255\022\000\255\255\255\255\255\255\255\255\
    \000\000\000\000\021\000\255\255\255\255\000\000\000\000\004\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\022\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\032\000\000\000\000\000\000\000\005\000\006\000\
    \010\000\018\000\018\000\018\000\018\000\018\000\018\000\018\000\
    \018\000\018\000\018\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\020\000\035\000\255\255\
    \255\255\255\255\020\000\255\255\255\255\255\255\255\255\000\000\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\003\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\255\255\255\255\255\255\255\255\017\000\255\255\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\255\255\025\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \032\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    ";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec token lexbuf =
   __ocaml_lex_token_rec lexbuf 0
and __ocaml_lex_token_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 49 "lib/lexer.mll"
                         ( new_line lexbuf; token lexbuf )
# 166 "lib/lexer.ml"

  | 1 ->
# 50 "lib/lexer.mll"
                         ( token lexbuf )
# 171 "lib/lexer.ml"

  | 2 ->
# 53 "lib/lexer.mll"
                         ( new_line lexbuf; token lexbuf )
# 176 "lib/lexer.ml"

  | 3 ->
# 54 "lib/lexer.mll"
                         ( comment lexbuf; token lexbuf )
# 181 "lib/lexer.ml"

  | 4 ->
let
# 56 "lib/lexer.mll"
              n
# 187 "lib/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 56 "lib/lexer.mll"
                         ( NUM(int_of_string n) )
# 191 "lib/lexer.ml"

  | 5 ->
let
# 57 "lib/lexer.mll"
             id
# 197 "lib/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 57 "lib/lexer.mll"
                         ( keyword_or_ident id )
# 201 "lib/lexer.ml"

  | 6 ->
# 59 "lib/lexer.mll"
                         ( COMMA )
# 206 "lib/lexer.ml"

  | 7 ->
# 60 "lib/lexer.mll"
                         ( SEMI )
# 211 "lib/lexer.ml"

  | 8 ->
# 61 "lib/lexer.mll"
                         ( LPAR )
# 216 "lib/lexer.ml"

  | 9 ->
# 62 "lib/lexer.mll"
                         ( RPAR )
# 221 "lib/lexer.ml"

  | 10 ->
# 63 "lib/lexer.mll"
                         ( BEGIN )
# 226 "lib/lexer.ml"

  | 11 ->
# 64 "lib/lexer.mll"
                         ( END )
# 231 "lib/lexer.ml"

  | 12 ->
# 67 "lib/lexer.mll"
                         ( MINUS )
# 236 "lib/lexer.ml"

  | 13 ->
# 68 "lib/lexer.mll"
                         ( NOT )
# 241 "lib/lexer.ml"

  | 14 ->
# 69 "lib/lexer.mll"
                         ( PLUS )
# 246 "lib/lexer.ml"

  | 15 ->
# 70 "lib/lexer.mll"
                         ( TIMES )
# 251 "lib/lexer.ml"

  | 16 ->
# 71 "lib/lexer.mll"
                         ( DIVIDES )
# 256 "lib/lexer.ml"

  | 17 ->
# 72 "lib/lexer.mll"
                         ( MODULO )
# 261 "lib/lexer.ml"

  | 18 ->
# 73 "lib/lexer.mll"
                         ( EQUALS )
# 266 "lib/lexer.ml"

  | 19 ->
# 74 "lib/lexer.mll"
                         ( NEQUALS )
# 271 "lib/lexer.ml"

  | 20 ->
# 75 "lib/lexer.mll"
                         ( LESS )
# 276 "lib/lexer.ml"

  | 21 ->
# 76 "lib/lexer.mll"
                         ( LESS_EQUALS )
# 281 "lib/lexer.ml"

  | 22 ->
# 77 "lib/lexer.mll"
                         ( AND )
# 286 "lib/lexer.ml"

  | 23 ->
# 78 "lib/lexer.mll"
                         ( OR )
# 291 "lib/lexer.ml"

  | 24 ->
# 81 "lib/lexer.mll"
                         ( raise (Error ("unknown character : " ^ lexeme lexbuf)) )
# 296 "lib/lexer.ml"

  | 25 ->
# 83 "lib/lexer.mll"
                         ( EOF )
# 301 "lib/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_token_rec lexbuf __ocaml_lex_state

and comment lexbuf =
   __ocaml_lex_comment_rec lexbuf 32
and __ocaml_lex_comment_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 86 "lib/lexer.mll"
                         ( () )
# 313 "lib/lexer.ml"

  | 1 ->
# 87 "lib/lexer.mll"
                         ( comment lexbuf )
# 318 "lib/lexer.ml"

  | 2 ->
# 88 "lib/lexer.mll"
                         ( raise (Error "unterminated comment") )
# 323 "lib/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_comment_rec lexbuf __ocaml_lex_state

;;

