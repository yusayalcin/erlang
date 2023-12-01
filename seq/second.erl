-module(second).
-export([inc/1]).

inc([H|T]) ->
    [first:foo(H) | inc(T)];

inc([]) -> [].

% inc(L) when length(L) == 0 -> 