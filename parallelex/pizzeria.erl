-module(pizzeria).
-compile(export_all).



pizzeria(L) ->
    receive
        {order, Client, Pizza} ->
            spawn(fun() -> Client ! cook(Pizza) end),
            NewL = L ++ [Pizza],
            pizzeria(NewL);
        {what_takes_so_long, Client} -> case lists:filter(fun({_O, C, _P}) -> C == Client end, L) of
                                        [] -> Client ! nothing_was_ordered,
                                              pizzeria(L);
                                        {_O, Pizza, _X} -> Client ! {cooking, Pizza},
                                             pizzeria(L)
                                        end;
         close -> io:format("Bye")
    end.


cook(margherita) -> timer:sleep(500);
cook(calzone)    -> timer:sleep(600).



open() ->
    register(pizzeria, spawn(fun() -> pizzeria([]) end)).


close() -> 
    pizzeria ! close.

order(E) ->
    pizzeria ! {order, self(), E}.


where_is_my_pizza() ->
    pizzeria !  {what_takes_so_long, self()}.

