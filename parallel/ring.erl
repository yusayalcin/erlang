-module(ring).
-compile(export_all).


run(N) ->   %timer:tc(ring, run, [100]).
    First  = lists:foldr(fun(_, Acc) ->  
                            spawn(ring, worker, [Acc])  
                        end, self(), lists:seq(1, N)),
    First ! ok,
    receive
        ok -> finished
    end.

worker(Next) ->  % this Acc is from the Acc above
    receive
        ok -> Next ! ok
    end.


    % run(N) ->
    %     First  = lists:foldr(fun(_, Acc) -> 
    %                             spawn(fun() -> receive
    %                                                 ok -> Acc ! ok 
    %                                             end 
    %                                   end)
    %                         end, self(), lists:seq(1, N)),
                            
    %     First ! ok,
    %     receive
    %         ok -> finished
    %     end.
    