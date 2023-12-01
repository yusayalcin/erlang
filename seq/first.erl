-module(first).
-export([foo/0, foo/1]).

foo() -> ok.


foo(A) -> 
    A + 1.