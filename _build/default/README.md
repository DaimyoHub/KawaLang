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

  - Structures loading
  - Static type-checking
  - Code evaluation

### Structures loading

Every structure of the program is loaded in memory in order to statically
type-check the program (see type-checking section for details) and allow method
call and class instantiation during evaluation (see evaluation section for
details)

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

### Code evaluation

Code evaluation simply evaluates a given program, whether by calculating an
expression result, or by mutating the memory state of the program given by
some instructions.

## Development report

### Loader

The loader linearly reads the program and simultaneously stores its structures in
memory. For instance, we give the following program :

```
class Point {
    attribute int x;
    attribute int y;

    method void Point(int x, int y) {
        this.x = x;
        this.y = y;
    } 
}
```

Which will be loaded such that a model of the class Point would be stored in memory,
containing informations such as attributes associated to some Point object and
methods associated to some Point object. A model of the method Point is also
stored in memory and linked to the Point class, containing its parameters types,
its code, its returning type...


> [!CAUTION]
> A delicate aspect of the loader development was the decision of structures used to
> represent programs objects.

## Typechecker

The typechecker performs two processes :

  - it basically tries to type each expression of a program, based on an associated typing
  environment. If it cannot type a given expression, it gives back a type error report
  containing details about the typing failure.

  - then it types and checks each sequence of instructions according to the expression typing
  algorithm described above. If some typing error is reported due to an expression typing
  error, or an instruction typing error, it propagates this report, adding some informations
  if necessary.

> [!CAUTION]
> It was hard to handle type errors. I first wanted to propagate them using exceptions,
> but I did not really know how to handle them correcly (should I catch a deeper exception
> and rethrow it, adding some informations, or should I just let the deeper exception 
> going up and handle it in the interpreter ?). Moreover, exceptions are side-effects,
> and I wanted to keep my program as pure as necessary, to avoid mixing different 
> techniques and loose myself in a "spaghetti designed" program. It is already ugly 
> enough to make it worse...

### Evaluator
