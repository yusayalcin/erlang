-module(partest).
-compile(export_all).

smap(F, L) ->                %sixth:smap(fun(X) -> X + 1 end, [2,3,4]).
    %lists:map(F, L).
    [F(E) || E <- L].

pmap(F, L) ->            % sorted starting by the fastest
    MainPid = self(),
    [spawn(fun() -> MainPid ! F(E) end) || E <- L],
    [receive
        A -> A
    end  || _ <- L].

    
ord_pmap(F, L) ->    % sorted by the order
        MainPid = self(),
        Pids = [spawn(fun() -> MainPid ! {self(),F(E)} end) || E <- L],
        [receive
            {Pid, A} -> A
        end  || Pid <- Pids].


fib(0) -> 1;
fib(1) -> 1;
fib(N) -> fib(N-1) + fib(N-2).


