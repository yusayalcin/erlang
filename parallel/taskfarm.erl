-module(taskfarm).
-compile(export_all).




run(F, List) ->
    register(dispatcher, spawn(fun() -> dispatcher(List) end)),
    register(collector, spawn(fun() -> collector(#{}) end)),
    N = erlang:system_info(logical_processors_available),
    _WPids = [spawn(fun() -> worker(F) end) || _ <- lists:seq(1, N)].
dispatcher([H|T]) -> 
    receive
        {ready, Pid} -> Pid ! {element, H},
                           dispatcher(T)
    end;
dispatcher([]) -> io:format("dispatcher terminated...~n").

collector(State) -> 
    receive
        {res, Orig, Result} -> collector(State#{Orig=>Result});
        {give_me, Pid} ->     Pid ! {subresult, State},
                               collector(State)
    end.
    

worker(F) -> 
    dispatcher ! {ready, self()},
    receive
        {element, H} -> collector ! {res, H, F(H)},
                             worker(F)
    end.


% process(State) ->
%     receive 
%         Msg ->
%             do_sth,
%             process(State);
%         msg2 ->
%             NewState = do_sth_else,
%             process(NewState);
%         stop -> terminates
%     end.

