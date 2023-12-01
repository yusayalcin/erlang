-module(third).
-export([search/2, search_prim/2, count_prim/2, count/2, freq/1, freq1/1, count_del/2, freq2/1,search_case/2]).

search(E, [H | _T]) when E == H->
         true;

search(E, [_H| T]) -> %% when E/= H ustten asagi geldigi icin yazmaya gerek yok
    search(E, T);

search(_E, []) -> 
        false.

search_case(E, L) ->
    case L of 
        [E | _T] -> true;
        [_H | T] -> search(E, T);
        [] -> false
    end.

search_prim(E, [H | T]) ->
    (E == H) or search_prim(E, T);

search_prim(_E, []) ->
    false.

count(E, L) ->
    count(E, L, 0).

% count(E, [H|T], Count) when E == H->
count(E, [E | T], Count) ->
    count(E, T, Count+1);

count(E, [_H|T], Count) ->
    count(E, T, Count);

count(_, [], Count) -> Count.

count_prim(E, [H|T]) when E == H ->
    1 + count_prim(E, T);
    
count_prim(E, [_H|T]) ->
        count_prim(E, T);

count_prim(_, []) ->  0.


freq(L) ->
    lists:usort(freq(L,L)). %usort makes it unique and sorted, no duplication
freq([H | T], Orig) ->
    [{count(H, Orig), H} | freq(T, Orig)];

freq([], _) ->
    [].

freq1([H | T]) ->
    NewRem = [ E || E <- T, E /= H],
    [{1 + count(H, T), H} | freq1(NewRem)];

freq1([]) ->
    [].

count_del(E, [E|T]) ->
    {Count, Rem} = count_del(E, T),
    {Count+1, Rem};
count_del(E, [H|T])->
    {Count, Rem} = count_del(E, T),
    {Count, [H | Rem]};
count_del(_E, []) ->
    {0, []}.
    
freq2([H|T]) ->
    {Count, Rem} = count_del(H, T),
    [{Count+1, H} | freq2(Rem)];
freq2([]) ->
    [].


