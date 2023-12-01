-module(y).
-compile(export_all).

applyAllPar(Fs, L) ->
    Main = self(),
    Pids = [spawn(fun() -> Main ! {self(), F(E)} end) || F <- Fs, E <- L],
    [receive
        {Pid, A} -> A
    end || Pid <- Pids].



speculativeEval([], _) -> no_proper_result;
speculativeEval(_, []) -> no_proper_result;
speculativeEval(Fs, L) ->
    Main = self(),
    Pids = [spawn(fun() -> Main ! appl(F,E) end) || {F, E} <- zip(Fs, L)],
    Result = receive
            Value when is_number(Value) -> Value
    end,
    [receive
        A -> A
    end || _ <- lists:seq(1, length(Pids)-1)],
    Result.



zip([], _) -> [];
zip(_,[]) -> [];
zip([H1|T1], [H2|T2]) ->
    [{H1,H2}] ++ zip(T1, T2).



    
appl(F, E) ->
    try
        F(E)
    catch
        _:_ -> ok
    end.


merge_sort([]) -> [];
merge_sort(L) when length(L) == 1 -> L;
merge_sort(L) ->
    Main = self(),
    {L1, L2} = lists:split(length(L) div 2, L),
    spawn(fun() ->  Main ! merge_sort(L1) end),
    spawn(fun() ->  Main ! merge_sort(L2) end),
    receive
        Val1 -> Val1 
    end,
    receive
        Val2 -> Val2
    end,
    lists:merge(Val1,Val2).

multi(F, L1, L2) ->
    Main = self(),
    Bool = checkTypes(L1, L2),
    case Bool == true of
        false -> {'EXIT',"Non matching types"};
        true ->
    Pids =[spawn(fun() -> Main ! {self(), ap(F, E1, E2)} end) || {E1, E2} <- zipp(L1, L2)],
    [receive
        {Pid, A} -> A
    end || Pid <- Pids]
end.

zipp([], _) -> [];
zipp(_, []) -> [];
zipp([H1|T1], [H2|T2]) -> 
    [{H1,H2}] ++ zipp(T1, T2).


ap(F,E1,E2) ->
    try 
        F(E1,E2)
    catch
        _:_ -> {'EXIT',"Non matching types"}
    end.

checkTypes(L1, L2) ->
    lists:all(fun({A, B}) -> is_number(A) and is_number(B) end, zipp(L1, L2)).



bucket_sort(L) ->
        bucket_sort(L, mean(L)).
    
bucket_sort([], _) ->
        [];
%bucket_sort(L, _Mean) when length(L) == 1-> L;
bucket_sort(L, Mean) ->
        {Bucket1, Bucket2} = divide(L, Mean),
        spawn(fun() -> bucket_sort(Bucket1, mean(Bucket1)) end),
        spawn(fun() -> bucket_sort(Bucket2, mean(Bucket2)) end),
        SortedBucket1 = receive Result -> Result end,
        SortedBucket2 = receive  Res -> Res end,
        merge(SortedBucket1, SortedBucket2).
    
divide([], _) ->
        {[], []};
divide([H|T], Mean) ->
        {Bucket1, Bucket2} = divide(T, Mean),
        if H < Mean -> {[H|Bucket1], Bucket2};
           true -> {Bucket1, [H|Bucket2]}
        end.
    
merge([], L) -> L;
merge(L, []) -> L;
merge([H1|T1], [H2|T2]) when H1 < H2 ->
        [H1 | merge(T1, [H2|T2])];
merge(L1, L2) ->
        merge(L2, L1).
    
mean(L) ->
            Len = length(L),
            if Len == 0 -> 0;
               true -> lists:sum(L) / Len
            end.


pany(F, L) ->
    Main = self(),
    NewL = lists:zip(lists:seq(1, length(L)), L),
    register(fun1, spawn(fun() -> pp(F, Main) end)),
    [fun1 ! {I, E} || {I, E} <- NewL],
    fun1 ! kill,
    receive
        {res, _I, true, E} -> {true, E};
        {res, _I, false, _E} -> false

    end.

pp(F, Main) -> 
    receive
        {I, E} -> Main ! {res, I, F(E), E},
        pp(F, Main);
        kill -> killed
    end.
             
% pp(F, Main) ->
%     receive
%         {From, I, E} ->
%             case F(E) of
%                 true -> Main ! {result, true, E};
%                 false -> ok
%             end,
%             From ! ok,
%             pp(F, Main);
%         done -> ok
%     end.


apply_alternately(F, G, L) ->
    Main = self(),
    NewL = lists:zip(lists:seq(1, length(L)), L),
    register(fun1, spawn(fun() -> calc(F, Main) end)),
    register(fun2, spawn(fun() -> calc(G, Main) end)),
    [fun1 ! {I, E} || {I, E} <- NewL, I rem 2 == 1],
    [fun2 ! {I, E} || {I, E} <- NewL, I rem 2 == 0],
    Result =[receive
        {res, I, A} -> A
    end || {I, _E} <- NewL],
    fun1 ! kill,
    fun2 ! kill,
    Result.


calc(F, Main) ->
    try
        receive
            {I, E} -> Main ! {res, I, F(E)},
            calc(F, Main);
            kill -> killed
        end
    catch
        _:_ -> calc(F, Main);
        kill -> killed
end.


fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-2) + fib(N-1).

 

