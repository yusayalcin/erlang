-module(client).
-compile(export_all).


start(Nick) ->
    case chat:login(Nick) of
        logged_in ->
            ClientPid = self(),
            spawn(fun() -> read(ClientPid) end),
            clientloop();
        deny -> 
            "Connection to the server failed";
        nick_eror ->
            "Nick name has to be an atom"
    end.

clientloop() ->
    receive
        {msg, Msg} ->
            io:format("~p~n", [Msg]),
            clientloop();
        {text, Msg} ->
            chat:send(Msg),
            clientloop();
        stop ->
            chat:logout()

    end.


read(Pid) -> 
    flush(),
    case lists:droplast(io:get_line("--> ")) of   %% droplast it to drop the new line from the end
            "exit" -> Pid ! stop; %chat:log_out();
        
             Msg   -> %chat:send(Msg),
                      Pid ! {text, Msg},
                      read(Pid)
    end.

flush() ->
    receive
            {msg, A} -> 
                io:format("~p~n", [A]),
                flush()
    after 0 -> ok
    end.


% create(N) ->
%     [register(x, spawn_link(?MODULE, init, [])) || _ <- lists:seq(1, N)].