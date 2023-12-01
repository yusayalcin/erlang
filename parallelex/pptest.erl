-module(pptest).
-compile(export_all).

iterate(F, L, N) ->
    Main = self(),
    Pids = [spawn(fun() -> worker(F) end) || _ <- lists:seq(1, N)],
    init(Pids ++ [Main]),
    [hd(Pids) ! {E, E} || E <- L],
    Last = lists:last(Pids),
    [receive
        {Last, E} ->E
    end || _ <- L].




init([_]) -> ok;
init([H1,H2 | T]) ->
    H1 ! H2,  % xx
    init([H2 | T]).

worker(F) ->
    receive
        Pid -> workerLoop(F, Pid)
    end.

workerLoop(F, Pid) ->
    receive
        {_Prev, E} -> Pid ! {self(), F(E)}, % xx
                     workerLoop(F, Pid)
    end.
                    

    % iterate(F, L, N) ->
    %     Last = lists:foldr(fun(_, Acc) ->
    %                         spawn(test, worker, [F, Acc]) end,
    %                     self(), lists:seq(1,N)),
    %     [Last ! {E, E} || E <- L],
    %     Last ! stop,
    %     [receive
    %         {res, B} -> B
    %     end || _ <- L].
    
    
    % worker(F, Next) ->
    %     receive
    %         {_Prev, Data} -> Next ! {res, F(Data)},
    %                       worker(F, Next);
    %         stop -> Next ! stop
    %     end.
    