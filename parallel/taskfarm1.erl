-module(taskfarm1). %% process pool
-export([run/2]).

-spec run(_, _) -> pid().
run(F, List) ->
    register(dispatcher, spawn(fun() -> dispatcher(List) end)),
    register(collector, spawn(fun() -> collector(#{}) end)),
    N = 2, %erlang:system_info(logical_processors_available),
 %   [dispatcher ! {ready, spawn(fun() -> worker(F) end)} || _ <- lists:seq(1,N)].
    WPids = [spawn(fun() -> worker(F) end) || _ <- lists:seq(1,N)],
    spawn_link(fun() -> supervisor_init(WPids, F) end).

supervisor_init(WPids, F) ->
    %process_flag(trap_exit, true), link(W)
    Refs = [monitor(process, W) || W <- WPids],
    supervisor(F, Refs).

supervisor(F, Refs) ->
    receive
        %{'EXIT', Pid, Reason} ->
        {'DOWN', Ref, process, _Pid, Reason} when Reason /= normal ->
            case lists:member(Ref, Refs) of
                true -> 
                    {_NewPid, NewRef} = spawn_monitor(fun() -> worker(F) end),
                    supervisor(F, [NewRef | lists:delete(Ref,Refs)]);
                false ->
                    io:format("Down signal arrived from unknown process...~n"),
                    supervisor(F, Refs)
            end
    end.

dispatcher([H|T]) ->
    receive
        {ready, Worker, Ref} -> 
            Worker ! {element, H, Ref},
            dispatcher(T)
    end;
dispatcher([]) ->
    io:format("Dispatcher terminates... ~n").

collector(State) ->
    receive
        {result, Orig, Result} ->
            collector(State#{Orig=>Result});
        {give_me, From} ->
            From ! {subresult, State},
            collector(State)
    end.

worker(F) ->
    UnRef = make_ref(),
    %monitor(process, SupPid),
    dispatcher ! {ready, self(), UnRef},
    receive
        {element, Data, UnRef} -> 
            collector ! {result, Data, F(Data)},
            %dispatcher ! {ready, self()},
            worker(F)
    end.

% process(State) ->
%     receive
%         msg1 -> 
%             do_sth,
%             process(State);
%         msg2 ->
%             NewState = do_sth_else,
%             process(NewState);   
%         stop ->
%             terminates
%     end.
