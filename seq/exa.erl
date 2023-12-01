-module(exa).
-export([differences/2]).
-export([applyAll/2]).
-export([getPositions/2]).
-export([riffleShuffle/1]).
-export([reverse/1]).
-export([repeat_while/3]).
-export([elems_repeated_at_least_ntimes/2]).
-export([eval_polynomial/2]).
-export([bin_to_decimal/1]).
-export([first_n_abundant_nums/1]).
-export([figure/1]).
-export([upperLower/1]).
-export([zip/2]).
-export([tails/1]).
-export([multiplier/2]).
-export([is_numeric/1]).
-export([partition/2]).
-export([sums/2]).
-export([isSquareNum/1]).
-export([sumOfSquares/1]).
-export([isPrime/1]).
-export([primesBelow/1]).
-export([elemsAtEvenPos/1]).
-export([swapEvenOddPos/1]).
-export([applyAllPar/2]).
-export([merge_sort/1]).
-export([apply_alternately/3]).
-export([fib/1]).
differences([],_) -> [];
differences([H1|T1], [H2|T2]) when H1 /= H2 ->
    [H1] ++ differences(T1, T2);
differences([_H1|T1], [_H2|T2]) ->
    differences(T1, T2).

applyAll(F, L) -> [err_han(G,E) ||  G <-F, E <-L ].
err_han(G, E) ->
    try 
        G(E)
    catch
        _:_ -> bad_fun_argument
    end.


getPositions(X, L) -> getPositions(X, L, 1).
getPositions(_X, [], _C) -> [];
getPositions(X, [X|T], C) -> [C] ++ getPositions(X, T, C+1);
getPositions(X, [_H|T], C) -> getPositions(X, T, C+1).


riffleShuffle([]) -> [];
riffleShuffle([X]) -> [X];
riffleShuffle(L) when length(L) rem 2 == 0-> 
    {L1, L2} = lists:split(length(L) div 2, L),
    mer(L1, L2);
riffleShuffle(L) -> 
     {L1, L2} = lists:split(length(L) div 2, L),
     NewL2 = reverse(L2),
     mer(L1, NewL2).

mer([],[]) -> [];
mer([],[X]) -> [X];
mer([H1|T1], [H2|T2]) ->
    [H1,H2] ++ mer(T1, T2).

reverse([H|T]) -> T ++ [H].


repeat_while(F, G, N) ->
    case F(N) of
        true -> [N] ++ repeat_while(F, G, G(N));
        false -> []
end.


elems_repeated_at_least_ntimes(N, L) -> lists:usort(elems_repeated_at_least_ntimes(N, L, L)).
elems_repeated_at_least_ntimes(N, [], _L) -> [];
elems_repeated_at_least_ntimes(N, L, _) when N < 1 -> lists:sort(L);
elems_repeated_at_least_ntimes(N, [H|T], L) ->
    L2=[E || E <-L, E==H],
    case (length(L2)>=N) of
        true -> [H] ++ elems_repeated_at_least_ntimes(N, T, L);
        false -> elems_repeated_at_least_ntimes(N, T, L)
end.

eval_polynomial(L, N) -> eval(L, length(L)-1, N).
eval([], _S, _N) -> 0;
eval([H|T], S, N) ->
    H*pow(N, S) + eval(T, S-1, N).

pow(_N, 0) -> 1;
pow(N, S) -> N * pow(N, S-1).


bin_to_decimal(L) -> bin_to_decimal(L, length(L)-1).

bin_to_decimal([], _) -> 0;
bin_to_decimal([H|T], C) -> H*pow(2,C) + bin_to_decimal(T, C-1).


first_n_abundant_nums(N) -> list(N, lists:seq(1,10000)).
list(N,[H|T]) when N > 0->
    case check_abundant(H) of
        true -> [H] ++ list(N-1, T);
        false -> list(N, T)
end;
list(0, _L) -> [].
check_abundant(N) -> 
    L = lists:seq(1, N-1),
    L2 = [E || E <-L, N rem E == 0],
    Sum = lists:sum(L2),
    Sum > N.


figure({X,Y,Z}) when X > 0, Y > 0, Z > 0 ->
     case {X==Y, X==Z, Y==Z} of
            {true, false, false} -> {isosceles,not_rectangle};
            {false, true, false} -> {isosceles,not_rectangle};
            {false, false, true} -> {isosceles,not_rectangle};
                             _   ->  equilateral(X, Y, Z)
end;

figure({X,Y,Z,T}) when X > 0, Y > 0, Z > 0, T > 0 ->
    case {X==Y, X==Z, Y==T} of
        {true, true, true} -> square;
        {false, true, true} -> rectangle
end.

equilateral(X, Y, Z) ->
    case {X==Y, Y==Z} of
        {true, true} -> {equilateral,not_rectangle};
         _           -> not_a_proper_triangle
end.



upperLower(N) ->
    case (lists:member(N, lists:seq($a, $z))) of 
        true -> string:to_upper(N);
        _ ->  case lists:member(N, lists:seq($A, $Z)) of
                    true -> string:to_lower(N);
                    false -> N
    end
end.


zip([],_) -> [];
zip(_, []) -> [];
zip([H|T1], [L|T2]) -> 
    [{H,L}] ++ zip(T1,T2).
%zip ([1,2], "abc")= [{1, 'a'}, {2, 'b'}]


tails([]) -> [[]];
tails([H|T]) ->
    [[H|T]] ++ tails(T).


multiplier(_, 0) -> forbidden;
multiplier(0, _Y) -> 0;
multiplier(X, Y) ->
        NewX = half(X),
        NewY = double(Y),
        case is_even(X) of
            true -> multiplier(NewX, NewY);
            false -> Y + multiplier(NewX, NewY)
    end.

half(X) -> X div 2.
double(X) -> X*2.
is_even(X) -> X rem 2 ==0.


is_numeric(L) -> is_numeric(L, length(L), L).

is_numeric([], N, _L) -> false;
is_numeric([X], N, L) when $9 >= X, $1 =< X -> true;
is_numeric([H|T], N, L) when $9 >= H, $1 =< H-> 
    true and is_numeric(T, N-1, L);
is_numeric([H|T], N, L) when $. == H, N /= length(L), N /= 1-> 
    true and is_numeric(T, N-1, L);
is_numeric([H|T], N, L) -> false.


partition(F, L) -> 
    L1 = [E || E <- L, F(E)==true],
    L2 = [E || E <- L, F(E)==false],
    [L1,L2].



% -- `sums` computes all sums of an element of l1 with an element of l2.
% -- sums [10, 20] [1,3,5] == [11,13,15,21,23,25]

sums(L1, L2) -> [E+F || E <- L1, F <-L2].

% `sumOfSquares n` should be the sum of the first n square numbers.

sumOfSquares(N) -> sumOfSquares(N, lists:seq(1, 10000)).

sumOfSquares(N, [H|T]) when N > 0 ->
    case isSquareNum(H) of
        true -> H + sumOfSquares(N-1, T);
        false -> sumOfSquares(N, T)
end;
sumOfSquares(0, _) -> 0.



isSquareNum(N) -> isSquareNum(1, N).
isSquareNum(S, N) when S < N->
    case (S*S == N) of
        true -> true;
        false -> false or isSquareNum(S+1, N)
end;
isSquareNum(_S, _N) -> false.


isPrime(N) -> 
    L =[E || E <- lists:seq(2, N-1), N rem E == 0],
    length(L)==0.

primesBelow(N) -> primesBelow(N, lists:seq(2, N)).
primesBelow(_N, []) -> [];
primesBelow(N, [H|T]) ->
    case isPrime(H) of
        true -> [H] ++ primesBelow(N, T);
        _ -> primesBelow(N, T)
end.

% -- Use zip to only keep the elements of a list that occur at an even position.
% elemsAtEvenPos :: [a] -> [a]
% elemsAtEvenPos = undefined
% -- Examples: 
% -- - elemsAtEvenPos "Hello" = "Hlo"
% -- - elemsAtEvenPos "abcdef" = "ace"

elemsAtEvenPos(L) -> elemsAtEvenPos(L,1).
elemsAtEvenPos([], C) -> [];
elemsAtEvenPos([H|T], C) when C rem 2 == 0->
    [H] ++ elemsAtEvenPos(T, C+1);
elemsAtEvenPos([H|T], C) -> elemsAtEvenPos(T, C+1).


% -- Define a function `swapEvenOddPos :: [Int] -> [Int]` that swaps elements at
% -- even and odd positions:
% -- (You can assume that the length of the input list is even.)
% -- Example:
% --  swapEvenOddPos [1, 2, 3, 4, 5, 6] == [2, 1, 4, 3, 6, 5]
% -- Hint: use zip

swapEvenOddPos([]) -> [];
swapEvenOddPos([H1,H2|T]) -> [H2,H1] ++ swapEvenOddPos(T).


applyAllPar(L1, L2) -> applyAllPar(L1, L2, L2).

applyAllPar([_F|G],[], L) -> applyAllPar(G, L, L); 
applyAllPar([], _, _) -> []; 
applyAllPar([F|G], [H|T], L) ->
    [F(H)] ++ applyAllPar([F|G], T, L).


merge_sort(L) ->
   {L1, L2}= lists:split(length(L) div 2, L),
   L1New = lists:sort(L1),
   L2New = lists:sort(L2),
   lists:merge(L1New, L2New).





apply_alternately(F, G, []) -> [];  
apply_alternately(F, G, [H|T]) -> apply_alternately(F, G, [H|T], 1).
apply_alternately(F, G, [], C)-> [];
apply_alternately(F, G, [H|T], C) when C rem 2 == 1 ->
    try
        [F(H)] ++ apply_alternately(F, G, T, C+1)
    catch
        _:_ -> apply_alternately(F, G, T, C+1)
    end;
apply_alternately(F, G, [H|T], C) ->
    try
         [G(H)] ++ apply_alternately(F, G, T, C+1)
    catch
            _:_ -> apply_alternately(F, G, T, C+1)
    end.



fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-2) + fib(N-1).


