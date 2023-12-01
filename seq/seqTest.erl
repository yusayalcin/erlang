-module(exam).
-export([]).
-export([differences/2]).


%differences([],_) -> [];
differences([],[]) -> [];
differences([],_) -> [];
differences(X,[]) -> X;
differences([H1|T1], [H2|T2]) when H1 /= H2-> 
    [H1] ++ differences(T1, T2);
differences([_H1|T1], [_H2|T2]) -> 
    differences(T1, T2).
