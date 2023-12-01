-module(exam).
-compile(export_all).



applyAllPar(_F, []) -> [];
applyAllPar(Fs, L) ->
    Main = self(),
    Pids=[spawn(fun() -> Main ! {self(), F(E)}end) || F <- Fs, E <- L],
    [receive
        {Pid, A} -> A
    end || Pid <- Pids].


fib(0) -> 0;
fib(1) -> 1;
fib(N) -> fib(N-1) + fib(N-2).

zip([], []) -> [];
zip([], _) -> [];
zip(_, []) -> [];
zip([H1|T1], [H2|T2]) ->
    [{H1, H2} | zip(T1, T2)].



apply_fun(F, Arg) ->
    try
        F(Arg)
    catch
        error:_ -> ok
    end.    

speculativeEval([], []) ->
    no_proper_result;
speculativeEval([], _) ->
    no_proper_result;
speculativeEval(_, []) ->
    no_proper_result;
speculativeEval(FS, LS) ->
    MainPid = self(),
    Pids = [spawn(fun() -> MainPid ! apply_fun(F, L) end) || {F, L} <- zip(FS, LS)],
    Result = receive 
                Value when is_number(Value) -> Value 
            end,
    [
        receive 
            A -> A 
        end
    || _ <- lists:seq(1, length(Pids) - 1)
    ],
    Result.
    


getPositions(C, L) ->
    Main = self(),
    NewL = lists:zip(lists:seq(1, length(L)), L),
    Pids =[spawn(fun() -> Main ! {self(), I} end) || {I, E} <- NewL, E==C],
    [receive
        {Pid, A} -> A
    end || Pid <- Pids]. 


riffleShuffle(L) when length(L) rem 2 == 0 ->
    Main = self(),
    {L1, L2} = lists:split(length(L) div 2, L),
    NewL = [],
    [spawn(fun() -> Main ! x(NewL, E) end)|| E <- zipp(L1,L2)],
    [receive
                A -> A
        end || _ <- L];
    
riffleShuffle(L) ->
        Main = self(),
        {L1, L2} = lists:split(length(L) div 2, L),
        {L1, L2} = lists:split(length(L) div 2, L),
        NewL2 = reverse(L2),
        NewL = [],
        [spawn(fun() -> Main ! x(NewL, E) end)|| E <- zipp(L1,NewL2)],
        [receive
                A -> A
        end || _ <- L].

reverse([H|T]) -> T ++ [H].

aa(L1, L2) ->
    E1 = zipp(L1,L2),
    NewL = [],
    x(NewL, E1).



zipp(_, []) -> [];
zipp([], []) -> [];
zipp([], [X]) -> [X];
zipp([X], [Y]) -> [X, Y];
zipp([H1|T1],[H2|T2])  ->
    [H1,H2] ++ zipp(T1, T2).


x(L, E1) ->
     L++E1.
