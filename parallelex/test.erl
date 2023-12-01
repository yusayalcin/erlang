-module(test).
-compile(export_all).

run() ->
    Main = self(),
    register(divide, spawn(fun() -> divideHelper() end)),
    register(merge, spawn(fun() -> mergeHelper(Main) end)),
    register(worker1, spawn(fun() -> worker1Helper() end)),
    register(worker2, spawn(fun() -> worker2Helper() end)).



divideHelper() -> 
    receive
        {sort, Divide, Merge, Sort, InputList} -> {L1, L2} = Divide(InputList),
                                                  worker1 ! {fromDivide, Sort, L1},
                                                  worker2 ! {fromDivide, Sort, L2},
                                                  merge   ! {fromDivide, Merge}
    end. 

mergeHelper(Main) -> 
    receive
        {fromDivide, Merge} -> Merge,
        receive
            {fromWorker1, L1} -> L1,
            receive
                {fromWorker2, L2} -> merge ! {Merge(L1, L2), Main},
                                    mergeHelper(Main)
            end
        end;
        {result, Pid} -> Pid ! result,
                         mergeHelper(Main)
    end.
   
%the worker processes wait for the Sort function first and then they are waiting for a list to arrive, perform the sorting on the list and send the sorted list to the merge process.
worker1Helper() -> 
    receive
        {fromDivide, Sort, L1} -> merge ! {fromWorker1, Sort(L1)},
                                  worker1Helper()
    end.
                                  

worker2Helper() -> 
    receive
        {fromDivide, Sort, L2} -> merge ! {fromWorker2, Sort(L2)},
                                    worker2Helper()
    end.