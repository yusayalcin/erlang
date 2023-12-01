-module(jobserver).
-compile(export_all).

-define(SRV, {js, 'server@yusayalcin'}).

start(Max) ->
    register(js, spawn_link(?MODULE, init, [Max])).
stop() ->
    ?SRV ! stop.

init(_Max) ->
    process_flag(trap_exit, true),
    loop(#{}).

loop(State) ->
        receive
            stop ->
                io:format("Jobserver terminated~n");
            {request, Ref, {M, F, A}} ->
                Worker = spawn_link(fun() -> ?SRV ! {value, Ref, apply(M, F, A)} end),
                loop(State#{Ref=>{Worker, started}});
            {result, Ref, Pid} ->
                case State of
                    #{Ref:={_, started}} -> Pid ! {in_progress, Ref};
                    % #{Ref := error} -> ...
                    #{Ref:=Value} -> Pid ! {finished, Value, Ref};
                    _ -> Pid ! {invalid_id, Ref}
                end,
                loop(State);
            {value, Ref, Value} ->
                loop(State#{Ref=>Value});
            {'EXIT', Worker, Reason} when Reason/=normal ->
                Ref = maps:fold(fun(Key, {W, _}, _Acc) when W =:= Worker -> Key;
                                    (_, _, Acc) -> Acc
                                 end, ok, State ),
                loop(State#{Ref=>error})
        end.
    
    send_request(M, F, A) -> 
        ?SRV ! {request, Id = make_ref(), {M, F, A}},
        Id.
    
    ask_result(Id) ->
        ?SRV ! {result, Id, self()},
        receive
            {in_progress, Id} -> not_ready_yet;
            {invalid_id, Id} -> not_avalilable_job;
            {finished, Value, Id} -> Value
            % error -> 
        end.
    
    send_request(M, F, A, Node) -> 
        {js, Node} ! {request, Id = make_ref(), {M, F, A}},
        Id.


%  R = jobserver:send_request(lists, max, [[1,2,3]]. 
%  jobserver:ask_result(R).


% Map = #{apple => 3, pear => 4} 
% #{apple := Value} = Map.
% Value. -----> 3