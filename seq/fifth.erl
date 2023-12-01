-module(fifth).
-export([apply_twice/2, inc/1, a/2,count_del/2, b/2, h/1, even_list/2]).
-export([eval/3]).
-export([x/2]).

apply_twice(F, Arg) ->
    X = F(Arg),
    F(X).     %F(F(Arg)).

inc([H|T]) ->
    [H+1 | inc(T)];

inc([]) ->
    [].


count_del(E, L) ->
    lists:foldl(fun(H, {Count, Rem}) when H == E->  {Count + 1, Rem};
                   (H, {Count, Rem}) -> {Count, [H|Rem]}    
     end, {0, []}, L).

    %  count_del(E, [E|T]) ->
    %     {Count, Rem} = count_del(E, T),
    %     {Count+1, Rem};
    % count_del(E, [H|T])->
    %     {Count, Rem} = count_del(E, T),
    %     {Count, [H | Rem]};
    % count_del(_E, []) ->
    %     {0, []}.


% > lists:mapfoldl(fun(X, Sum) -> {2*X, X+Sum} end,
% 0, [1,2,3,4,5]).
% {[2,4,6,8,10],15}

a(X, LS) ->
    L = [E*2 || E <- LS],
    S = lists:sum(LS),
    {L, S}.

% > lists:mapfoldl(fun(X, Sum) -> {2+X, X*Sum} end,
% 0, [1,2,3,4,5]).
% {[3,4,5,6,7], 3*4*5..}

b(X, LS) ->
    L = [E + 2 || E <- LS ],
    S = mul(L),
    {L, S}.


mul([H|T]) ->
    H * mul(T);
mul([]) ->
    1.

h([]) -> [];
h([H|T]) ->
    h(T) ++  [H].



even_list(F, [H|T]) when H rem 2 == 0 ->
    [H | even_list(F, T)];

even_list(F, [_H|T])  ->
    even_list(F, T);

even_list(_F, []) -> [].


eval(M, F, Arg) -> % m = erlang    fifth:eval(erlang, length, [1,2,3]).   
  try
      M:F(Arg) + 1
  of 
      Value -> {rerturn_value, Value}
  catch
    error:function_clause -> "The func has no matching def";   %fifth:eval(lists, max, []). 
    _:undef -> "the function is not defined";     %fifth:eval(lists, maasdx, [])
    _:badarith -> "The return value is not a number";
    _:_ -> "unexpected error occured"
  end.

%   decode(EncodeRes) -> 
% 	try
% 		CodeTable = element(1, hd([EncodeRes])),
% 		Res = [],
% 		Seq = element(2, hd([EncodeRes])),
% 		{[H], T} = decoding(Seq, 1, CodeTable),
% 		Newlist = lists:append([Res, [H]]),
% 		decode(T, CodeTable, Newlist)
% 	catch
%         error:ErrorType -> {error, ErrorType, "The type of the argument is not matching"};
%         _:_ -> error;
%         _ -> throwederror
%     after 
%         io:format("~n")
%     end.

x(F, []) -> [];
x(F,[H|T]) ->
    try 
        [F(H)] ++ x(F, T)
    catch
        _:_ -> "bad_fun_argument"
    end.