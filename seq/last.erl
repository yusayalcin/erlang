-module(last).
-export([]).
-export([first_n_abundant_nums/1, is_abundant/1]).
-export([upperLower/1]).

first_n_abundant_nums(N) -> first_n_abundant_nums(N, lists:seq(1, 10000)).

first_n_abundant_nums(0, _) -> [];
first_n_abundant_nums(N, [H|T]) ->
    case is_abundant(H) of
        true -> [H] ++ first_n_abundant_nums(N-1, T);
        false -> first_n_abundant_nums(N, T)
end.


is_abundant(N) -> 
    L = lists:seq(1, N-1),
    AbList =[E || E <- L, N rem E == 0],
    lists:sum(AbList) > N.



%     Test> 
% upperLower ('a') = 'A'
% Test2> 
% upperLower ('T')= 't' 
% Test3> 
% upperLower (',' )= ',' 

upperLower(N) ->
    case (lists:member(N, lists:seq($a, $z))) of 
        true -> string:to_upper(N);
        _ ->  case lists:member(N, lists:seq($A, $Z)) of
                    true -> string:to_lower(N);
                    false -> N
    end
end.