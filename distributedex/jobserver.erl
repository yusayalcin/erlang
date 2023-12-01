-module(jobserver).
-compile(export_all).

-define(JOB, {server, 'job@yusayalcin'}).


start() ->
    register(server, spawn_link(?MODULE, init, [])).

init() ->
    loop(#{}).

loop(State) ->
    receive
        {request, Ref, {M, F, A}} -> spawn(fun() -> ?JOB ! {value, Ref, apply(M, F, A)} end),
                                     loop(maps:put(Ref, started, State));

        {value, Ref, Value}       -> loop(maps:update(Ref, Value, State));

        {result, Ref, Pid}        -> case maps:get(Ref, State) of
                                        started -> Pid ! {in_progress, Ref};
                                        Value -> Pid ! {finished, Value, Ref}
                                    end
    end.


send_request(M, F, A) ->
    Ref = make_ref(),
    ?JOB ! {request, Ref, {M, F, A}},
    Ref.


ask_result(Ref) ->
    ?JOB ! {result, Ref, self()},
    receive
            {in_progress, Ref} -> not_ready_yet;
            {invalid_id, Ref} -> not_avalilable_job;
            {finished, Value, Ref} -> Value
        end.