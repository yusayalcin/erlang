-module(chat).
-compile(export_all).

%-define(ADD(A, B), A+B). % bir yerde soldaki func kullanilirsa sagdaki islemi yapmis oluyor icerisinde
-define(CHAT, {chatsrv, 'server@yusayalcin'}). % bir yerde soldaki func kullanilirsa sagdaki islemi yapmis oluyor icerisinde

start(Args) ->
    register(chatsrv, spawn_link(?MODULE, init, [Args])). % spawn_link(chat, init, [Args])


init(Max) ->
    process_flag(trap_exit, true),
    InitState = {#{}, 0, Max},
    chat:loop(InitState).

loop(State={Clients, Num, Max}) ->
    receive
        stop -> io:format("server terminating... ~n");
        {log_in, Pid, Nick} when Num < Max ->   link(Pid),
                                                io:format("~p is connecting to the conversation~n", [Pid]),
                                                Pid ! logged_in,
                                                loop({Clients#{Pid=>Nick}, Num+1, Max});
        
        {log_in, Pid, _Nick}                -> Pid ! deny,
                                              loop(State);

            {log_out, Pid} ->   io:format("~p is leaving the conversation~n", [Pid]),
                                loop({maps:remove(Pid, Clients), Num-1, Max});

        {'EXIT', Pid, Reason} when Reason /= normal ->
                                io:format("~p is leaving the conversation~n", [Pid]),
                                loop({maps:remove(Pid, Clients), Num-1, Max});

        {send, Pid, Msg} ->     #{Pid:=Nick} = Clients,
                                NewMsg = Nick ++ ": " ++ Msg,
                                maps:foreach(fun(ClPid, _) -> 
                                                ClPid ! {msg, NewMsg},
                                                ClPid ! {msg, NewMsg}
                                            end, Clients),
                                loop(State);



        dump ->             io:format("Server state:~p~n", [State]),
                            chat:loop(State);
        Other        ->  io:format("unwanted  message arrived:~p~n", [Other]),
                        loop(State)
    end.

    
login(Nick) when is_list(Nick)-> % is_list to check if it is string
    ?CHAT ! {log_in, self(), Nick},
    receive
        A -> A 
    after
        5000 -> deny
    end;

login(_Nick) ->
    nick_error.

logout() ->
    ?CHAT ! {log_out, self()}.

send(Msg) ->
    ?CHAT ! {send, self(), Msg}.


stop() ->
    ?CHAT ! stop.

%c(chat).
% chat:start(11).
% chatsrv ! {log_in, self(), "Melinda"}.
% chatsrv ! dump.  % Server  state:{#{<0.78.0> => "Melinda"},1,11} -> there is one active user which is melinda
% chat:stop().
% flush(). -> should be logged in


% chatsrv ! {send, self(), "Hello"}.
% flush().


% chat:send("smg").

% erl -sname server