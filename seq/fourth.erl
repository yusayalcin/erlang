-module(fourth).
-export([freq/1, freq_if/2, freq_map/1]).


freq(L) ->
    freq(L, []).
freq([], Result) -> Result;

freq([H|T], Result) -> 
    case lists:keyfind(H, 2, Result) of 
        false ->  freq(T, [{ 1 + count(H, T),  H} |  Result]);
        _->  freq(T, Result)
    end.

count(E, L) ->
    count(E, L, 0).
count(E, [E | T], Count) ->
    count(E, T, Count+1);

count(E, [_H|T], Count) ->
    count(E, T, Count);

count(_, [], Count) -> Count.


freq_if ([], Result) -> Result;


freq_if([H|T], Result) -> 
    Cond = lists:keyfind(H, 2, Result),
    if is_tuple(Cond) -> freq_if(T, Result);
        true-> freq_if(T, [{ 1 + count(H, T),  H} |  Result])
    end.

freq_map(L) ->
    freq_map(L, #{}).

freq_map([H|T], Map) ->
    case Map of 
        #{H:=C} -> freq_map(T, Map#{H=>C+1});
        _ -> freq_map(T, Map#{H=>1})
    end;

freq_map([], Map) -> Map.