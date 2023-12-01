-module(x).
-export([search/2]).
-export([search_case/2]).
-export([search_prim/2]).
-export([count/2]).
-export([count_prim/2]).
-export([freq/1]).
-export([freq1/1]).

search(E, [H|T])  when E == H-> 
    true;
search(E, [H|T]) -> search(E, T);
search(E, []) -> false.




search_case(E, []) -> false;

search_case(E, [H|T]) ->
    case E == H of
        true -> true;
        false -> search_case(E, T)
    end.

   
search_prim(E, []) -> false;
search_prim(E, [H | T]) ->
    (E == H) or search_prim(E, T).
    

count(E, L) -> count(E, L, 0).

count(_E, [], C) -> C;
count(E, [H|T], C)  when H == E-> count(E, T, C +1);
count(E, [_H|T], C) -> 
    count(E, T, C). 



count_prim(E, [E|T])  ->
    1 + count_prim(E, T);
count_prim(E, [H|T])  ->
        count_prim(E, T);
count_prim(E,[]) -> 0.

freq(L) ->
    lists:usort(freq(L,L)). %usort makes it unique and sorted, no duplication
   
freq([H|T],L) ->
    [{count(H,L), H}] ++ freq(T, L);
freq([], L) -> [].
  
freq1([]) -> [];

freq1([H | T]) ->
    L = [E || E <- T, H /= E ],
    [{1+ count(H,T), H}] ++ freq1(L).
 

% count_del(E, [E|T]) ->
  
    
% freq2([H|T]) ->
    
