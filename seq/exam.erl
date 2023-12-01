-module(exam).
-export([differences/2]).
-export([applyAll/2]).
-export([getPositions/2]).
-export([riffleShuffle/1]).


%differences([],_) -> [];
differences([],[]) -> [];
differences([],_) -> [];
differences(X,[]) -> X;
differences([H1|T1], [H2|T2]) when H1 /= H2-> 
    [H1] ++ differences(T1, T2);
differences([_H1|T1], [_H2|T2]) -> 
    differences(T1, T2).

applyAll(F, L) -> [G(E) || G <- F, E <- L].


getPositions(E, L) -> getCount(E, L, 1).

getCount(_E, [], _C) -> [];
getCount(E, [E|T], C) -> [C] ++ getCount(E, T, C+1);
getCount(E, [_H|T], C) -> getCount(E, T, C+1).


riffleShuffle([]) -> [];
riffleShuffle([X]) -> [X];
riffleShuffle(L) ->
    {L1,L2} = lists:split(length(L) div 2, L),

    case (length(L2) /= length(L1)) of
           true -> change(L1, L2);
           false -> mer(L1, L2)
    end.
    
change(L1, [H|T]) ->
    L2 = T ++ [H],
    mer(L1, L2).


mer([],[]) -> [];
mer([], [X]) -> [X]; 
mer([H1|T1],[H2|T2]) -> [H1,H2] ++ mer(T1, T2).
