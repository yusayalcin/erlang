-module(zz).
-compile(export_all).


applyAllPar(Fs, L) -> 
    Main = self(),
    Pids =[spawn(fun() -> Main ! {self(), F(E)} end)|| F <- Fs, E <- L],
    [receive
        {Pid, E} -> E
    end || Pid <- Pids].


speculativeEval([], _) -> no_proper_result;
speculativeEval(_, []) -> no_proper_result;
speculativeEval(Fs, L) -> 
    Main = self(),
    Pids = [spawn(fun() -> Main ! app(F,E) end) ||{F, E} <- zip(Fs, L)],
    Result = receive Value when is_number(Value) -> Value end,
    [receive
        A -> A
    end || _ <- lists:seq(1, length(Pids)-1)],
    Result.

app(F, E) ->
    try 
        F(E)
    catch
        _:_ -> ok
    end.

zip([], _) -> [];
zip(_, []) -> [];
zip([H1|T1], [H2|T2]) -> 
    [{H1, H2}] ++ zip(T1, T2).


    fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-2) + fib(N-1).





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





multi(F, L1, L2) -> 
    Main = self(),
    Pids = [spawn(fun() -> Main ! xyz(F, E1, E2) end) || {E1, E2} <- zip(L1, L2)],
    [receive
        E -> E
    end || _ <- Pids].


xyz(F, E1, E2) ->
    try
        F(E1, E2)
    catch
        _:_ -> {'EXIT',"Non matching types"}
    end.


pany(F, L) -> 
    Main = self(),
    Pids =[spawn(fun()-> Main ! {F(E), E} end) || E <- L],
    Result =[
    receive
        {true, E} -> {true, E};
        {false, _E} -> false
    end || _ <- Pids],
    checkX(Result).

checkX([]) -> false;
checkX([H|T]) ->
    case H of
        {true, E} -> {true, E};
        false -> checkX(T)
    end.
    
finn(Pid) ->
    io:format("Finn: What time is it?~n"),
    Pid ! {what_time_is_it, self()},
    receive
        adventure_time -> io:format("Finn: That's right buddy~n")
    end.

jake() ->
    receive
        {what_time_is_it, Pid} -> io:format("Jake: Adventure time!~n"),
                                Pid ! adventure_time
    end.


begin_adventure() ->
    Pid = spawn(fun() -> jake() end),
    register(fin, spawn(fun() -> finn(Pid) end)).



%%%%%%%%%%%%%%%%%%%%%%

%ring:pipe/1

%Define a function pipe/1 that takes the process identifier of the successor process as argument, and receives messages. 
%Messages have two forms. Either {forward, N} where N is an integer or quit. 
%In the former case the function increases N by one and sends it forward to the next process and keeps waiting for further messages. 
%In the latter case the function simply forwards the message to the next process and returns.

pipe(Pid) ->
    receive
        {forward, N} -> Pid ! {forward, N + 1},
                        pipe(Pid);
        quit  -> Pid ! quit
    end.


start() ->
    P = self(),
    A = spawn(fun() -> pipe(P) end),
    B = spawn(fun() -> pipe(A) end),
    C = spawn(fun() -> pipe(B) end),
    D = spawn(fun() -> pipe(C) end),
    E = spawn(fun() -> pipe(D) end),
    E.


%Define a function start/0 that creates a ring of six processes, like P \rightarrow A \rightarrow B \rightarrow C \rightarrow D \rightarrow E \rightarrow P, where A sends the received message to B, P is the current process.
        
%The function returns an anonymous function that takes one argument. If the argument is quit the function simply forwards it to process A, and returns a received message. 
%Otherwise it sends the argument as a forward message and returns the received integer.




apply_alternately(F, G, L) ->
    Main = self(),
    NewL = lists:zip(lists:seq(1, length(L)), L),
    register(fun1, spawn(fun() -> yy(F, Main) end)),
    register(fun2, spawn(fun() -> yy(G, Main) end)),
    [fun1 ! {I, E} || {I, E} <- NewL, I rem 2 == 1],
    [fun2 ! {I, E} || {I, E} <- NewL, I rem 2 == 0],
    fun1 ! kill,
    fun2 ! kill,
    Result = [
        receive
            {res, I, A} -> A;
            {error, _} -> null
    end || {I, _E} <- NewL],
    lists:filter(fun(X) -> X /= null end, Result).




yy(F, Main) -> 
    receive
        {I, E} -> 
            try    
                 Main ! {res, I, F(E)},
                io:format("~n")
            catch
                _:_ -> Main ! {error, E}
            after
                    yy(F, Main)
            end;
            kill -> killed
    end.

    % zz:apply_alternately(fun(E) -> E + 1 end, fun(E) -> E*2 end, [1,2,apple,4,5]) == [2,4,8,6].

    % zz:apply_alternately(12, fun(E) -> E*2 end, [1,2,3,apple,4,5]) == [4,10].