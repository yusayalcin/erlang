-module(x).
-compile(export_all).


applyAllPar(FS, LS) ->
    Main = self(),
    Pids = [spawn(fun() -> Main ! {self(), F(E)} end) || F <- FS, E <- LS],
    [receive
        {Pid, A} -> A
    end || Pid <- Pids].


fib(0) -> 0;
fib(1) -> 1;
fib(N) -> fib(N-1) + fib(N-2).


speculativeEval([], _) -> no_proper_result;
speculativeEval(_, []) -> no_proper_result;
speculativeEval(Fs, Ls) ->
    Main = self(),
    Pids = [spawn(fun() -> Main ! appl(F,E) end) || {F,E} <- zip(Fs, Ls)],
    Result=
            receive 
                Value when is_number(Value)  ->  Value
            end,    
    [receive
        A -> A
    end || _ <- lists:seq(1, length(Pids)-1)],
    Result.

zip(_, []) -> [];
zip([], _) -> [];
zip([H1|T1],[H2|T2]) ->
    [{H1,H2}] ++ zip(T1, T2).

appl(F,E) ->
    try
        F(E)
    catch
            _:_ -> ok
    end.


merge_sort([]) -> [];
merge_sort(L) when length(L) == 1-> L;
merge_sort(L)->
        Main = self(),
        {L1, L2} = lists:split(length(L) div 2, L),
        spawn(fun() -> Main ! merge_sort(L1) end),
        spawn(fun() -> Main ! merge_sort(L2) end),
        receive
         Val1 -> Val1
        end,
        receive
            Val2 -> Val2
        end,
        lists:merge(Val1,Val2).
