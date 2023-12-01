-module(tracker).
-export([main/0]).
-export([loop/1]).

main() ->
    register(tracker, spawn_link(?MODULE, loop, [[]])).
    
loop(List) ->
    receive
        {get, Peer} ->
            case lists:member(Peer, List) of
                true ->
                    Peer ! {tracker_response, List},
                    loop(List);
                false ->
                    monitor(process, Peer),
                    NewList = List ++ [Peer],
                    Peer ! {tracker_response, NewList},
                    loop(NewList)
            end;
        {'DOWN', _, _, _, Peer, _} ->
            loop(lists:delete(Peer, List))
    end.
