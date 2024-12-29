open Sym

type typ = Int | Bool | Cls of symbol | Void

exception Type_error
exception Symbol_not_found
exception Ctor_not_defined


