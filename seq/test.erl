-module(test).
-export([repeat_while/3]).
-export([elems_repeated_at_least_ntimes/2]).
-export([eval_polynomial/2]).
-export([pow/2]).
-export([is_even/1]).
-export([half/1]).
-export([double/1]).
-export([multiplier/2]).
-export([is_numeric/1]).
-export([replace/3]).
-export([partition/2]).
-export([bin_to_decimal/1]).
-export([until/3]).
-export([partition_ayman/2]).


repeat_while(F, G, N) -> 
    case F(N) == true of
        true -> [N] ++ repeat_while(F, G, G(N));
        false -> []
    end.


elems_repeated_at_least_ntimes(N, L) when N =< 0 -> L;
elems_repeated_at_least_ntimes(N, L) -> lists:usort(repeat(N, L, L)).


repeat(_N, [], _L) -> []; 

repeat(N, [H|T], L) -> 
    L1 = [E || E <-L, E==H],
    C= length(L1),
    case C >= N of
        true -> [H] ++ repeat(N, T, L);
        _ -> repeat(N, T, L)
end.



eval_polynomial(L, N) -> eval(L, N, length(L)).

eval([], _N, _A) -> 0;
eval(_L, _N, A) when A =< 0 -> 0;
%eval([H], N, A) -> H*pow(N,A);
eval([H|T], N, A) ->
    H*pow(N,A-1) + eval(T, N, A-1).



multiplier(_, 0) -> forbidden;
multiplier(A, _B) when A < 1 -> 0;
multiplier(A, B) -> 
    NewA = half(A),
    NewB = double(B),
    case is_even(A)==true of
        true -> multiplier(NewA, NewB);
        false -> B + multiplier(NewA, NewB)
end.


is_even(N) when N rem 2 == 0 -> true;
is_even(_N) -> false.

half(N) -> N div 2.
double(N) -> N*2.


is_numeric(L) -> is_numeric(L, 0, length(L)).
is_numeric([], 0, L) -> false;
is_numeric([], C, L) -> true;
is_numeric([H|T], C, L) when H == $., C > 0, C < L-1->
    true and is_numeric(T, C+1, L);
is_numeric([H|T], C, L) when H > $0,  H =< $9->
    true and is_numeric(T, C+1, L);
is_numeric([H|T], C, L) -> false.

replace(X, Y, Z) -> replace(X, Y, Z, 1, 0).
replace([], _Y, Z, _C, S) -> [];
replace(X, Y, Z, C, S)  when C rem 2 == 1 -> 
    case (string:slice(X, S, length(Y)) == string:slice(Y, S, length(Y)) ) of
        true -> string:concat(Z, replace(string:slice(X, S + length(Y)), Y, Z, C+1, length(Y)));
        false -> string:concat(string:slice(X, 0, length(Y)),replace(string:slice(X, 0 + length(Y)), Y, Z, C+1, length(Y)))
end;
replace(X, Y, Z, C, _S) ->  string:concat(string:slice(X, 0, length(Y)), replace(string:slice(X, 0 + length(Y)), Y, Z, C+1, length(Y))).



partition(_, []) ->
    {[], []};
partition(P, [H|T]) ->
    {TP, FP} = partition(P, T),
    case P(H) of
        true ->
            {[H|TP], FP};
        false ->
            {TP, [H|FP]}
    end.

partition_ayman(F, L) -> partition_mykuki(F, L, [], []).
partition_mykuki(F,[], L1, L2) -> L2;
partition_mykuki(F,[H|T], L1, L2) ->
    case F(H) of
        true -> L1 = lists:append(L1, [H]);
        false -> L2 = lists:append(L2, [H]) 
end,
partition_mykuki(F, T, L1, L2).

bin_to_decimal(L) -> bin_to_decimal(L, length(L)-1).
bin_to_decimal([], C) -> 0;

bin_to_decimal([H|T], C) -> H*pow(2,C) + bin_to_decimal(T, C-1).

pow(_N, 0) -> 1;
pow(N, A) -> N * pow(N, A-1).


until(F, G, E) ->
    case F(E) of
        true -> until(F, G, G(E));
        false ->  E
end.



