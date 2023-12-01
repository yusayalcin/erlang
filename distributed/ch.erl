-module(ch).
-compile(export_all).

-define(CHAT, {srv, 'server@yusayalcin'}).

start(Max) ->
    register(srv, spawn_link(?MODULE, init, [Max])).

init(Max) ->
    InitState = {#{}, 0, Max},
    loop(InitState).

loop(State={Clients, Num, Max}) -> 
    receive
        stop ->  io:format("Terminatin~n");
        dump ->  io:format("State.. ~p~n",[State]),
                 loop(State);

        {login, Pid, Nick} ->  link(Pid),
                         io:format("Logged in.. ~p~n",[Nick]),
                         Pid ! logged_in,
                         loop({Clients#{Pid=>Nick}, Num+1, Max});
                    
        {logout, Pid}      ->   io:format("Logged out.. ~p~n",[Pid]),
                                NewCl=maps:remove(Pid, Clients),
                                loop({NewCl, Num-1, Max})
    end.



login(Nick) when is_list(Nick) ->
    ?CHAT ! {login, self(), Nick},
    receive
        A -> A
    end.

logout() ->
    ?CHAT ! {logout, self()}.

stop() ->
    ?CHAT ! stop.

dump() ->
    ?CHAT ! dump.