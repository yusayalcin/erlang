-module(chat).
-compile(export_all).
-define(CHAT, {server, 'server@yusayalcin'}).

start(Max) ->
    register(server, spawn_link(?MODULE, init, [Max])).

init(Max) ->
    InitState = {#{}, 0, Max},
    loop(InitState).

loop(State={Clients, Num, Max}) ->
    receive
        {login, Pid, Nick} -> link(Pid),
                              Pid ! logged_in,
                              NewClients= maps:put(Pid, Nick, Clients),
                              loop({NewClients, Num+1, Max});

        deny               -> io:format("error~n"),
                              loop(State);

        {logout, Pid}             ->    io:format("logged out~n"),
                                        NewClients= maps:remove(Pid, Clients),
                                        loop({NewClients, Num-1, Max});

        dump                      -> io:format("current state: ~p~n",[State]),
                                     loop(State);
        
        {msg, Msg, Pid}                -> Nick = maps:get(Pid, Clients),
                                          NewMsg = Nick ++ ": " ++ Msg,
                                            maps:foreach(fun(Cl, _) ->
                                                Cl ! {get, NewMsg}   
                                            end, Clients),
                                        loop(State)
        
    end.




login(Nick) when is_list(Nick) ->
    ?CHAT ! {login, self(), Nick},
    receive
        A -> A 
    end;

login(_Nick) ->
    ?CHAT ! deny.

logout() ->
    ?CHAT ! {logout, self()}.

send(Msg) ->
    ?CHAT ! {msg, Msg, self()}.

get() ->
    receive
        {get, NewMsg} -> NewMsg
    end.