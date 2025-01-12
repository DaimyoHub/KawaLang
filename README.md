# Kawa Language Interpreter

## Description of the language

Kawa is an object oriented toy programming language developed for a school
project, as an introduction to applied programming language theory. The
current implementation is a basic interpreter, with a static type checker.

### Examples

```
class point {
  attribute int x;
  attribute int y;

  method void point(int x, int y) {
    this.x = x;
    this.y = y
  }

  method int size() { 
    return this.x + this.y
  }
}

main {
  var int p;
  p = new point(1, 2);
  print(p.size());
}
```

## Interpreter architecture

The interpreter is quite naive. The pipeline for code execution is divided
in three sequential parts :

  - Parsing & Structures loading
  - Static type-checking
  - Code evaluation

### Static type-checking

The static type-checker of the language performs different actions. It basically 
checks weather well-formed programs are semantically correct at a certain level
of guarantee. ("Well-typed programs do not go wrong"). To achieve this goal it
performs different checking operations :

  - Name resolution check : "does this symbol exist in the context of the program ?"
  - User-defined typed variables check : "is this variable instantiated by an
existing class ?"
  - Expression type check : "is this expression well-typed ?"
  - Instruction type check : "are expressions put at stake from this instruction
well-typed ?"

## Development report

### Typechecker

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
    I first wanted to propagate type errors throw the exception system of Ocaml, but
    this design was hard to handle because I did not always know if in some situation,
    it would be better to just let an exception stop the typing process or to handle
    it in different possible ways.
    Eventually, I decided to handle type errors through a report mecanism which, on the
    one hand, generates side effects, printing a type error during the analysis, and on
    the other hand, can be passed through as a returned object through every typing
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
    instaciation was found, but it only checked a limited portion of the program, leaving
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
    I think that the design I chose to make the type checker makes the code globally heavy
    and sometimes hard to understand at first sight, that's why I've tried to comment it
    where I thought it could really be useful for the examinator to read.
    The reasons of some such heavy structures are the time schedule, a naive design for
    some features and patch-ups.

  - **Return statements in branching**
    I wanted to make the language permissive enough to allow branches to return values in
    the body of a method. However, it did not have enough time to handle cases where 
    one branch would return, and the other would not, so I decided to force the user to 
    make an if statement return the same type in both of its branchs, or to not make it return at all.
    For instance, the given codes report type errors

> [!NOTE]
> It was nice to remark that the typechecker is an actual kind of reducted interpreter : we
> clearly see that it evaluates a given program, but instead of working with real time values
> it uses approximations of them (types).

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

Below is a list of features provided by the type checker :

  - [x] Detect if types that are neither user-defined or built-in.
  - [x] Detect if a given symbol does not correspond to a location.
  - [x] Detect if the user tries to instatiate a class without any defined constructor.
  - [x] Detect if the body of a method contains different local variables which have
        the same symbol.
  - [x] Detect if the left/right hand side operand of an expression is ill-typed.
  - [x] Detect if an expression is ill-typed.
  - [x] Detect if a statement condition expression is a typed as a boolean.
  - [x] Detect if a void method returns.
  - [x] Detect if a return statement is missing in a typed method.
  - [x] Detect set statements where the left hand side operand type does not correspond
        to the variable type.
  - [x] Detect if a the argument of a print statement is an int.
  - [x] Detect if the user tries to call a method with too much arguments.
  - [x] Detect if the user tries to call a method missing some arguments.
  - [x] Detect if a given argument type correspond to the associated parameter type.
  - [x] Detect if a statement is ill typed.
  - [x] Detect if both branches of an if statement do not return a value of the same type.
  - [x] Detect if only one branch of an if statement returns a value.
  - [x] Not_obj_inst
  - [x] Detect if a method body contains multiple sequential return statements.
  - [x] Detect ill typed methods.
  - [x] Detect dead code in methods body
  - [x] Detect if the return type of a method correspond to returned values in its body.
  - [x] Detect if a branch of an if statement is ill typed.

### Interpreter

The interpreter mutates one's program environment reading its instructions. To perform
the interpretation of instructions that produce side effects, it also evaluates underlying
expressions contained in them.

As in the type checker, some aspects of the interpreter development were decisive for the
project design. Below is a list of the ones I dealt with :

  - **Constructing a calling environment**
    During the whole development of the type checker, I dealt with "linear environments",
    more precisely, class instances were not seen as objects linked with an environment 
    representing its attributes, but as simple variables, and to access their attributes,
    I had to make them visible in the environement contaning the object. It was not a
    good design and I later decided to make things more accessible for the interpreter
    development.

    Example: 
    *With expanding mecanism : *
    if an environment contains an instance "p" of class point,
    we cannot access the attribute "p.x" directly from the environment. We must "expand"
    p to make its attributes visible.

        env = ["p"]
        get "p.x" from env : error

        expand p in env :
        env = ["p"; "p.x"; "p.y"]
        get "p.x" from env : ok

    *With a better design (without expanding) : *
    Hence, I've decided to fix this issue, making every attributes of an object
    visible in an environment only containing the object.
        
        env = ["p"]
        get "p.x" from env : ok

    To perform it, I first look for the object in the given environment, then I try to
    the wanted attribute in its table of attributes.


