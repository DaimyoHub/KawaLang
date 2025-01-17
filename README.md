# Kawa Language Interpreter : development report

## Contact

The project is available of github : `github.com/DaimyoHub/KawaLang`

  - `alexis.pocquet@universite-paris-saclay.fr`
  - `alexis.pocquet@etu-upsaclay.fr`

Usage :
```
$ dune build
$ dune install
$ kawai program.kwa
```

Testing interpreter/type checker :
```
$ kawai test/interpreter/test_file1.kwa
$ kawai test/typechecker/test_file2.kwa
```

## Description of the language

Kawa is an object oriented toy programming language developed for a school
project, as an introduction to applied programming language theory. The
current implementation is a basic interpreter, with a static type checker.

## Interpreter architecture

### The global architecture

The interpreter is quite naive. The pipeline for code execution is divided
in three sequential parts :

  - Parsing & Structures loading
  - Static type-checking
  - Code evaluation/execution

That two last components strongly depend on the next one, which is permanently being
used during the interpretating process :

  - Symbol/name resolution

### A global overview of the design

As a given program is typically represented by an abstract syntax tree, both type checker and 
interpreter are implemented as recursive functions, depending on mutually recursive sub-functions.
They both go through the tree and type, check or execute the represented program.

In the type checker, I have decided to use the Result monad to propagate the result of typing/
checking functions. It made the syntax heavy at some points, but the binding operator "let*" 
allowed me to clean it everywhere I hade to propagate errors, without reporting anything.
Basically, every function that types/checks an expression/instruction work as the following sample :

```ocaml
let rec type_checker_func context current_env expr =
    (* Maybe a match on the given expression *)
    (* Maybe some operations mutating env and/or preparing expr *)
    match another_type_checker_func context current_env with
    | Ok typ ->
        (* Checking typ *)
        Ok some_type
    | Error report -> 
        (* Analyzing the report *)
        report (Some expected_type) (Some obtained_type) (Error_kind infos)
```

In the interpreter, **we assume that the given AST representing some portion of the code is well-typed
(i.e. it has been checked by the type checker)**. From this point of view, it was not necessary to
check static properties of the program (instead for some features, see extensions) as it should have
been done upstream. As a consequence, the code of the interpreter was not as heavy as in the type
checker. Basically, the interpreting function works as the following sample :

```ocaml
let rec interpreter_func context current_env expr =
    match expr with
    | SomeExpr (a, b) ->
        let va = some_interpreting_func context current_env
        and vb = some_interpreting_func context current_env
        in
        (* Mutating the given current_env *)
        (* Compute the value of the expression *)
    | (* ... *)
```

Finally, calls to the symbol resolver could be done anywhere in type checking and interpretating
functions.

### Files and modules

| file                   | contents                                                               |
|------------------------|------------------------------------------------------------------------|
| lib/abstract_syntax.ml | Contains the type representing the abstract syntax of a program.       |
| lib/context.ml         | Contains program structures such as class definition, method definition, program context, etc. |
| lib/environment.ml     | Contains the generic module Table that represents an associative table and Env, an instance of Table representing an environment. |
| lib/symbol.ml          | Contains the type symbol.                                              |
| lib/type.ml            | Contains representations of a program types.                           |
| lib/lexer.mll          | The lexer.                                                             |
| lib/parser.mly         | The parser.                                                            |
| lib/type_checker.ml    | The type checker. It contains every type checking and typing functions. |                                                            
| lib/interpreter.ml     | The interpreter. It contains every executing/evaluating functions.     |
| lib/symbol_resolver.ml | It contains every function that checks the nature of symbols (classes, methods, locations...), and every function that returns properties of program's objects. |
| lib/type_error.ml      | It contains the interface to handle (report, propagating, printing out type errors. |
| lib/allocator.ml       | It contains functions allocating objects during the program execution. |
| lib/levenshtein.ml     | It contains functions for the extension "did you mean ... ?".          |
| lib/debug.ml           | It contains debugging functions.                                       |

Every function is commented in the project. Comments do not exhaustivelly expose the behaviour of
functions but at least, it gives their general behaviour.

### A general feedback

I've spent a lot of time on this project because it really motivated me. If I had more time
I would have probably tried to make the interpreter more elegant. My first idead was to generate
a bytecode but it would have been too long, so I've just decided to use techniques learned in class.
More generally, I would have given more of my development type to make structures more intuitive,
the interface more uniform and to make the whole project work elegantly.

I have spent half of my time on the static analysis (type checking, name resolution and analysis of
return statements in branches), and the other half on the interpreter and the global project
architecture.

I'm quite satisfied of my own work, but above all, I know that there are a lot of things that could
have been better designed (architecturally and algorithmically). I had to find a compromise between
the schedule and the development of extensions/well designed features.

### Static type checker

The static type-checker of the language performs different actions. It basically 
checks that a syntactycally correct program is semantically correct at a certain level
of guarantee. ("Well-typed programs do not go wrong"). To achieve this goal it
performs different checking operations :

  - Name resolution check : "does this symbol exist in the context of the program ?"
  - User-defined typed variables check : "is this variable instantiated by an
existing class ?"
  - Expression type check : "is this expression well-typed ?"
  - Instruction type check : "are expressions put at stake from this instruction
well-typed ?"

The typechecker performs two processes :

  - it basically tries to type each expression of a program, based on an associated typing
  environment. If it cannot type a given expression, it gives back a type error report
  containing details about the typing failure.

  - then it types and checks each sequence of instructions according to the expression typing
  algorithm described above. If some typing error is reported due to an expression typing
  error, or an instruction typing error, it propagates this report, adding some informations
  if necessary.

The development of the typechecker put some aspects of type checking and kawa semantics
at stake. Below is a list of such stakes and how I decided to deal with :

  - **Type error report**
    I first wanted to propagate type errors thanks to the exception system of Ocaml, but
    this design was hard to handle because I did not always know if in some situation,
    it would be better to just let an exception stop the typing process or to handle
    it in different possible ways.
    Eventually, I decided to handle type errors through a report mecanism which, on the
    one hand, generates side effects, printing a type error during the analysis, and on
    the other hand, can be passed through as a returned object in every typing
    or checking function, to potentially recursivelly analyze the program in order
    to generate a more precise type error report.

  - **How much permissive ?**
    I also had to choose between to possible global designs for the type checker. One
    possibility was to make a permissive type checker which only analyzed basic static 
    properties of the program. However, I chose to make it less permissive and more
    precise (see features of the type checker for an exhaustive list of analyzable patterns)
    because I've been used to strong/static type-checkers and because this version
    of Kawa has few features, that it is easy to cover a majority of problematic patterns
    in the language. Another reason for this design is that I wanted to try to have a
    precise type checker, able to deal with some intricate patterns such as return
    statements in branchings.

  - **How to deal with method code checking ?**
    I first tried to recursivelly check the code of methods when a method call or an
    instanciation was found, but it only checked a limited portion of the program, leaving
    dead code unchecked. 
    I therefore designed the type checker in order to check methods independently from
    call expressions.

  - **A bit of patch-ups**
    During the type checker testing process, I had to patch-up some portions of it to
    make it more precise (better type error messages in precise contexts, for instance)
    and to fix some minor issues.
    In some places, the code is heavy and a bit messy, it could be far better, but I wanted
    to respect the time schedule.

  - **Heavy design**
    I think that the design I chose to make the type checker makes the code a bit heavy to read 
    and sometimes hard to understand at first sight, that's why I've tried to comment it
    where I thought it could really be useful for the examinator to read.
    The reasons of some such heavy structures are the time schedule, a naive design for
    some features (extensions...) and patch-ups.

  - **Return statements in branching**
    I wanted to make the language permissive enough to allow branches to return values in
    the body of a method. However, I did not have enough time to handle cases where 
    one branch would return, and the other would not, so I decided to force the user to 
    make an if statement return the same type in both of its branchs, or to not make it return at all.
    For instance, some specific branching/return patterns are given below :

```
method int test() { /* error : method does not return well */
    if (cond) {
        /* ... */
        return 7;
    } else {
        /*  */
        return true;
        /* error : this branch return type does not correspond to the one wanted */
    }
}
```

```
method int test() {
    if (cond) {
        return 5;
    } else {
        /* no return statements */
        /* error : both branches must return int */
    }
}
```

```
method int test() { /* error : method do not return at all */
    /* no return statements */

    if (cond) {
        /* no return statements */
    } else {
        /* no return statements */
    }

    /* no return statements */
}
```

```
method int test() { /* ok : both branches return, so the method always returns */
    if (cond) {
        return 1;
    } else {
        return 0;
    }
}
```

```
method int test() { /* ok : both branches do not return but a the method always returns */
    if (cond) {
        /* no return statement */
    } else {
        /* no return statements */
    }

    return 0;
}
```

> [!NOTE]
> It was nice to remark that the typechecker is an actual kind of interpreter : we
> clearly see that it evaluates a given program, but instead of working with real time values
> it uses approximations of them (types).

Below is a list of mandaroty features provided by the type checker :

  - (M) Detect if the user is trying to access an attribute that does not belong to an object.
  - (M) Detect if the user is trying to access an attribute/method of a non-object location.
  - (M) Detect if a void method returns.
  - (M) Detect if an expression is ill-typed.
  - (M) Detect if a statement is ill typed.
  - (M) Detect if a given symbol does not correspond to a location. (see extension for details)

Every other features of the type checker are extensions. The type checker recursivelly travels
a whole branch of the program and if at some node, some "basic" type error is found, it recursivelly
provides details of the error, according to the context.

Below is a list of object oriented static checking features :

  - (E) Detect if a user forgets to define a contructor for a class.
  - (E) Detect if the user tries to instantiate a class without any defined constructor.

Then a list of method/method calling checking features :
  - (E) Detect if the user tries to call a method with too much arguments.
  - (E) Detect if the user tries to call a method missing some arguments.
  - (E) Detect if a method that should return does not.
  - (E) Detect if a given argument type correspond to the associated parameter type.
  - (E) Detect ill typed methods.

A list of features of the type checker related to branching/return statements :

  - (E) Detect if both branches of an if statement do not return a value of the same type.
  - (E) Detect if only one branch of an if statement returns a value.
  - (E) Detect if a method body contains multiple sequential return statements.
  - (E) Detect code written after a block of instructions that will surelly return. (specific dead code)
  - (E) Detect if the return type of a method correspond to returned values in its body.
  - (E) Detect if a branch of an if statement is ill typed.

Finally, some other generic checking features :

  - (E) Detect if types that are either user-defined or built-in.
  - (E) Detect if some symbol references different locations in a block of instructions.
  - (E) Precises if the left/right hand side operand of an expression is ill-typed.
  - (E) Detect if a statement condition expression is a typed as a boolean.
  - (E) Detect set statements where the left hand side operand type does not correspond
    to the variable type.
  - (E) Detect if a the argument of a print statement is an int.
  - (E) Detect if the user is trying to mutate a constant location.

The trickyest parts of the type checker are below, if the type checker contains bugs, they are
probably linked to these parts :

  - The sequence of instructions checking process, especially the one dedicated to if
    statements (see functions `exec_seq` and `exec_if_statement`).
  - It is possible that a same type error report appears two or tree times on the output. It is
    caused by the fact that a same error can appear at two different places in the code (in
    this case it is not a bug), or by the fact that some checking processes report the same
    error independently, or by the fact that I do not propagate some error silently (without
    printing the report on the output). In this case, it is not a bug, because the error is
    still reported and the checking process does not keep going, but it can be ugly.

I have worked a lot on the type checker (at least 1/2 of the development time), to make it as
exhaustive as possible and still permissive.

### Symbol resolver

Both type checker and interpreter strongly relate on the symbol resolver : it is a module
that performs every location/context access (and sometimes, mutations). It is a component of the type
checker, as it uses the type error report interface. Most of errors reported by the 
symbol resolver are "symbol resolving errors", which are a specific kind of type errors.

The symbol resolver sometimes mutates locations, for instance, when we are trying to acces 
a location which is an instance of a class. It allows to safely try to access its attributes,
because basically, one cannot access an arbitrary attribute of a declared but uninitialized
object.

Finally, the symbol resolver is probably the most important part of the type checker, as it
allows the latter to check the coherence of expressions and instructions containing more
complex data than just constants.

Locations are either variables, or attributes, or static attributes.

Below is a list of features provided by the symbol resolver :

  - Get a class
  - Check if a class is a super class for another
  - Get a method from a class
  - Get a static method
  - Get the return type of a method
  - Get the constructor of a class

  - Get a location and allocate it if it is not yet
  - Get a location symbol
  - Get a location type
  - Get a location data
  - Get the set of attributes of a location

As said before, each of these features are wrapped thanks to the type error report 
mecanism, to allow performing its operation safely.

### Interpreter

The interpreter mutates one's program environment reading its instructions. To perform
the interpretation of instructions that produce side effects, it also evaluates underlying
expressions contained in them.

As in the type checker, some aspects of the interpreter development were decisive for the
project design. Below is a list of the ones I dealt with :

  - **Constructing a calling environment**
    During the whole development of the type checker, I dealt with "linear environments",
    more precisely, class instances were not seen as objects linked with an environment 
    representing their attributes, but as simple variables, and to access their attributes,
    I had to make them visible in the environement contaning the object. It was not a
    good design and I later decided to make things more accessible for the interpreter
    development.

    Example: 
    With expanding mecanism :
    if an environment contains an instance "p" of class point,
    we cannot access the attribute "p.x" directly from the environment. We must "expand"
    p to make its attributes visible.

        env = ["p"]
        get "p.x" from env : error

        expand p in env :
        env = ["p"; "p.x"; "p.y"]
        get "p.x" from env : ok

    With a better design (without expanding) :
    Hence, I've decided to fix this issue, making every attributes of an object
    visible in an environment only containing the object.
        
        env = ["p"]
        get "p.x" from env : ok

    To perform it, I first look for the object in the given environment, then I try to find
    the wanted attribute in its table of attributes.

  - **Updating environment after call**
    Figuring out how to update environments put at stake during a method call was also tricky.
    I just decided to copy each location of the calling environment in its proper initial
    location (globals, attributes...). It is quite naive but it does the work.

### Implementation details of major features

#### Method calls



#### Inheritance features

### List of extensions

This interpreter of Kawa includes the following extensions :

  - See features of the type checker that are not mandatory.
  - [x] Cast expressions : It was hard to deal with conflicts in a first time, as a consequence,
        because time was running out, I decided to explicitely write cast expressions with the
        syntax `cast (class) expr`. A cast is only relevant during the type checking process,
        so it is the only place I handle it. The interpreter juste ignores it and evaluates the
        given expression.

  - [x] The instanceof operation : It would have been nice to evaluate this expression during
        the type checking process but I did not forecasted to implement this extension, and
        my type checker does not generates a typed AST. So, in this implementation, the type checker
        just checks this existence of the given class and types the given expression, and the interpreter
        performs the operation.

  - [x] Static methods (but not attributes because I did not have time to implement them) : 
        I reserved a method table in class definitions, to gather statit methods. Both in the type
        checker and in the interpreter, static methods are handled just like classical methods,
        except that the constructed calling environment does not contain any caller object.

  - [x] Declaration of variables with an initial value : I implemented locations so that they could 
        directly be constructed with a given data. I just added more syntax to the parser. Attributes
        cannot be initialized in their declaration because this task is provided by the constructor.
        Same for global variables, as we can initialize them in the main block.

  - [x] Declaration of variables everywhere in a block of instructions. (in the case of a while
        block, it does not work properly. Local variables of the block will persist out of scope)
        I had to add an "init" instruction to the language. Semantically, it is the same as
        a declaration followed by an affectation, both in the type checker and the interpreter.
        Moreover, I had to handle constant locations being declared with an initial value. In this case,
        I created a distinct "set" instruction (ConstSet) which should initialize a given
        constant location only once : when it is declared. When the parser finds constant location
        initialization, instead of returning a "Set" instruction, it returns a "ConstSet" one.

  - [x] Structural equality of locations : The syntax is `expr === expr`. It is pretty much the
        same as `==` but it checks equality of attributes when comparing objects together.

  - [x] Telling when a semicolon is missing : I used the built-in rule "error" of menhir to handle it.
        For each instruction, I duplicate it, transforming the "semi" rule to the "error" rule.
        
  - [x] When the user is trying to access a location that does not exist, it gives an error
        message specifying a location's name that is almost like the written symbol. The algorithm
        computes Levenshtein distances of each symbols in the current environment from the
        symbol that was not recognized.

  - [x] Immutable locations `var const type name = ...`. The only tool that really does the job
        for constant locations is the type checker, in the interpreter, I assume that, if we are
        trying to mutate a location, then it is not constant.

  - [x] If instruction without forcing the else branch : I just made the else branch optional in the
        parser.

  - [x] Panic instruction to abort the program execution. I wanted a feature that could stop the execution
        of a well typed program in the presence of runtime errors. It is just one more instruction in
        the language. The type checker does nothing and the interpreter raises an Exec_panic exception,
        with an error code.

