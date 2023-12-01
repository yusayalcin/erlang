-module(test).
-compile(export_all).

sfib(0) -> 1;
sfib(1) -> 1;
sfib(N) -> sfib(N-1) + sfib(N-2).

pfib(N, B) ->
    register(count, spawn(fun() -> count(N, B) end)),
    Res = pfib_c(N),
    count ! stop,
    Res.

pfib_c(0) -> 1;
pfib_c(1) ->1;
pfib_c(N) ->
    Main = self(),
    count ! {fromMain, Main},
    receive
        not_allowed -> sfib(N);
        allowed ->
            spawn(fun() -> Main ! pfib_c(N-1) end),
            spawn(fun() -> Main ! pfib_c(N-2) end),
            receive
                Val1 -> Val1
            end,
            receive
                Val2 -> Val2
            end,
            Val1+Val2
    end.

count(N, B) ->
    receive
        {fromMain, Pid} when N < B-2 -> Pid ! allowed,
                                        count(N+2, B);
        {fromMain, Pid}              -> Pid ! not_allowed,
                                        count(N, B);
        stop -> io:format("terminated......")
    end.

iterate(F, L, N) ->
    Last = lists:foldr(fun(_, Acc) ->
                        spawn(test, worker, [F, Acc]) end,
                    self(), lists:seq(1,N)),
    [Last ! {E, E} || E <- L],
    Last ! stop,
    [receive
        {res, B} -> B
    end || _ <- L].


worker(F, Next) ->
    receive
        {_Prev, Data} -> Next ! {res, F(Data)},
                      worker(F, Next);
        stop -> Next ! stop
    end.


run(F, L) ->
    register(dispatcher, spawn(fun() -> dispatcher(L) end)),
    register(collector, spawn(fun() -> collector(#{}) end)),
    [spawn(fun() -> w(F) end) || _ <- lists:seq(1, 2)].

dispatcher([H|T]) ->
    receive
        {fromWorker, Pid} -> Pid ! {fromDis, H},
                             dispatcher(T)
    end;
dispatcher([]) -> io:format("terminate...").

collector(State) ->
    receive
        {fromWorker, Old, New} -> collector(State#{Old=>New});
        {x, Pid} -> Pid ! {state, State},
                          collector(State)
    end.


w(F) ->
        dispatcher ! {fromWorker, self()},
        receive
            {fromDis, H} -> collector ! {fromWorker, H, F(H)},
                            w(F)
        end.



applyAllPar(Fs, L) ->
    Main = self(),
    Pids = [spawn(fun() -> Main ! {self(), F(E)} end) || F <- Fs, E <- L],
    [receive
        {Pid, E} -> E
    end || Pid <- Pids].


speculativeEval([],_) -> no_proper_result;
speculativeEval(_,[]) -> no_proper_result;
speculativeEval(Fs, L) ->
    Main = self(),
    Pids =[spawn(fun() -> Main ! appl(F, E) end) || {F, E} <- zip(Fs, L)],
    Result = receive Val when is_number(Val) -> Val end,
    [receive
        E -> E
    end || _ <- lists:seq(1, length(Pids)-1)],
    Result.

zip([],_) -> [];
zip(_,[]) -> [];
zip([H1|T1], [H2|T2]) -> 
    [{H1,H2}] ++ zip(T1,T2).
fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-1) + fib(N-2).

appl(F, E) ->
    try 
        F(E)
    catch
        _:_ -> "error"
    end.

merge_sort([]) -> [];
merge_sort(L) when length(L) == 1 -> L;
merge_sort(L) ->
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
    lists:merge(Val1, Val2).


pmfm(_F, _G, _H, []) -> [];
pmfm(F, G, H, L) ->
    Main = self(),
    register(f, spawn(fun() -> f(F) end)),
    register(g, spawn(fun() -> g(G) end)),
    register(h, spawn(fun() -> h(H, Main) end)),
    [f ! {E, E} || E <- L],
    Res= [receive
        {fromH, true, E} -> E;
        {fromH, false} -> null
    end || _ <- L],
    f ! stop,
    g ! stop,
    h ! stop,
    lists:filter(fun(X) -> X /= null end, Res).

f(F) ->
    receive   
        stop -> stopped;
        {_Prev, E} -> g ! {fromF, F(E)},
                     f(F)
    end.

g(G) ->
    receive
        stop -> stopped;
        {fromF, E} -> h ! {fromG, G(E), E},
                      g(G)
    end.

h(H, Main) -> 
    receive
        stop -> stopped;
        {fromG, true, E} -> Main ! {fromH, true, H(E)},
                         h(H, Main);
        {fromG, false, _E} -> Main ! {fromH, false},
                         h(H, Main)
    end.


 
apply_alternately(F, G, L) ->
    Main = self(),
    NewL = lists:zip(lists:seq(1, length(L)),L),
    register(fun1, spawn(fun() -> comp(F, Main) end)),
    register(fun2, spawn(fun() -> comp(G, Main) end)),
    [fun1 ! {I, E} || {I, E} <- NewL, I rem 2 == 1],
    [fun2 ! {I, E} || {I, E} <- NewL, I rem 2 == 0],
    Res = [receive
        {res, I, A} -> A
    end || {I, _E} <- NewL],
    fun1 ! stop,
    fun2 ! stop,
    Res.

comp(F, Main) ->
    receive
        stop -> stopped;
        {I, E} -> Main ! {res, I, F(E)},
                        comp(F, Main)
    end.


    % the divide process waits for jobs to perform in the form of a five-element tuple: {sort, Divide, Merge, Sort, InputList}. 
    % Once a job is received it divides the received InputList with the received Divide function, sends the sublists to the workers, and sends the Merge function to the merge process.

    % the merge process waits for the Merge function first and then waits for the sorted sublists from the workers. 
    %When both sublists have arrived, it evaluates the Merge function and stores the result in its arguments. 
    %The merge process has to store multiple results, so when storing the sorted list please identify somehow to which input it belongs.
    
    % the merge process might receive a request from the shell (or from any other process) to present the computed values. So it has a pattern {result, Pid} and sends the results to the Pid. 
    % the worker processes wait for the Sort function first and then they are waiting for a list to arrive, perform the sorting on the list and send the sorted list to the merge process.
    % all processes are recursive. Once they have done an iteration, they are waiting for the next job to arrive. 


run() ->
    Main = self(),
    register(divide, spawn(fun() -> divide() end)),
    register(merge, spawn(fun() -> merge(Main) end)),
    register(worker1, spawn(fun() -> worker1() end)),
    register(worker2, spawn(fun() -> worker2() end)).

merge(Main) ->
    receive
        stop -> io:format("bye");
        {fromDiv, Merge} -> Merge,
            receive
                {fromW1, L1} -> L1,
                receive
                    {fromW2, L2} -> merge ! {Merge(L1,L2), Main},
                                        merge(Main)
                end
            end;
            {Result, Pid} -> Pid ! Result,
                             merge(Main)
end.

divide() ->
    receive
        {sort, Divide, Merge, Sort, InputList} -> {L1, L2} = Divide(InputList),
                                                   worker1 ! {fromDiv, Sort, L1},
                                                   worker2 ! {fromDiv, Sort, L2},
                                                   merge   ! {fromDiv, Merge},
                                                   divide();
                            stop                -> worker1 ! stop,
                                                   worker2 ! stop,
                                                   merge   ! stop
    end.

worker1() ->
    receive
        stop -> io:format("bye");
        {fromDiv, Sort, L1} -> merge ! {fromW1, Sort(L1)},
                              worker1()
    end.

worker2() ->
        receive
            stop -> io:format("bye");
            {fromDiv, Sort, L2} -> merge ! {fromW2, Sort(L2)},
                                  worker2()
        end.