-module(pool).
-compile(export_all).

-define(POOL, {process_pool, 'server@yusayalcin'}).
worker() ->
    register(process_pool, spawn_link(?MODULE, loop, [])).

loop() ->
    receive
        {{JobFun,Args},Ticket,Customer} -> Customer ! {done, Ticket, apply(JobFun, Args)},
                                           ?POOL !  {done, self},
                                            loop();

                
        {JobFun,Ticket,Customer}      -> Customer ! {done, Ticket, apply(JobFun, [])},
                                        ?POOL !  {done, self},
                                        loop()

    end.

supervisor(FreeList, BusyList) ->
    receive
        {do_work, {Job, Ticket, Customer}} -> case FreeList of
                                                    [Worker | FreeList] -> Worker ! {Job, Ticket, Customer},
                                                                           NewFreeList = lists:delete(Worker, FreeList),
                                                                           NewBusyList= BusyList ++ [Worker],
                                                                           supervisor(NewFreeList, NewBusyList);
                                                    [] -> ok
                                              end;
                             
                             {done, Worker}   -> NewBusyList = lists:delete(Worker, BusyList),
                                                 NewFreeList = FreeList ++ [Worker],
                                                 supervisor(NewFreeList, NewBusyList);
                                
                            {destroy, Sender} -> List = lists:merge(FreeList, BusyList),
                                                 [exit(Worker, kill) || Worker <- List],
                                                 Sender ! destroyed;
                            
                                Msg -> io:format("Unexpected message: ~p~n", [Msg])
    end.

supervisor() ->
    Workers = [spawn(fun() -> worker() end) || _ <- lists:seq(1, 5)],
    supervisor(Workers, []).

