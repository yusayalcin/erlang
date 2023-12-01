-module(retake).
-compile(export_all).


fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-2) + fib(N-1).



run()->
    Main = self(),
    register(divide, spawn( fun()-> divide_helper() end)),
    register(merge, spawn(fun()->merge_helper(Main) end)),
    register(first, spawn( fun()->first_worker() end ) ),
    register(second, spawn( fun()->second_worker() end)).
  





divide_helper() ->
        receive
       {sort, Divide, Merge, Sort, InputList} ->  {List1,List2} = Divide(InputList),
                                                  first ! {fromDivide,Sort,List1}, 
                                                  second ! {fromDivide,Sort ,List2},
                                                  merge ! {fromDivide, Merge},
                                                  divide_helper();
                                          
                                          stop -> merge ! stop,
                                                  first ! stop,
                                                  second ! stop,
                                                  io:format("Divide: Bye ");
                        
                                     from_sub ->  io:format("Bye")

        end.

merge_helper(Main)->
    receive
     stop -> io:format(" Merge : Bye ~n");
     
        {fromDivide, Merge} -> Merge,
        receive
            stop                  -> io:format("Bye");
            {fromFirstWorker, L1} -> L1,
            receive
            {fromSecondWorker, L2} -> merge ! {  Merge(L1,L2) , Main },
                                      merge_helper(Main);
                              stop -> io:format("Bye") 
            end
        end;
        {Result,Pid} -> Pid ! Result, 
                        merge_helper(Main)
    end.
 
    


first_worker() ->
    receive 
    {fromDivide,SortFunction, List} -> merge ! {fromFirstWorker, SortFunction(List)}, 
                                       first_worker();
                               stop -> io:format(" Worker : Bye ~n")
    end.

second_worker()->
 receive 
    {fromDivide,SortFunction, List} -> merge ! {fromSecondWorker, SortFunction(List)},
                                       second_worker();
                                       stop->io:format("Worker : Bye ~n")
    end.