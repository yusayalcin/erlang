-module(p).
-compile(export_all).

-define(PIZ, {server, pizzeria@yusayalcin}).

open() ->
    register(server, spawn_link(?MODULE, init, [])).

init() ->
    pizzeria([]).

pizzeria(State) -> 
    receive
      close -> io:format("closed");

      {order, Client, Pizza} -> {_, Ref} = spawn_monitor(fun() -> cook(Pizza) end),
                                 pizzeria(State ++ [{Ref, Client, Pizza}]);

      {'DOWN', Ref, _, _, _} -> case lists:keyfind(Ref, 1, State) of
                                false -> ok;
                                {_, Cl, Pizza }  -> 
                                            Cl ! {delivered, Pizza},
                                            pizzeria(lists:keydelete(Ref, 1, State))
                                end;

        {what_takes_so_long, Client} -> case lists:keyfind(Client, 2, State) of
                                                false -> Client ! nothing_was_ordered;
                                                {_, _, Pizza } -> Client ! {cooking, Pizza}
                                        end,
                                        pizzeria(State)

    end.

    


order(Pizza) ->
    ?PIZ ! {order, self(), Pizza}.

close() ->
    ?PIZ ! close.


cook(margherita) -> timer:sleep(500);
cook(calzone) -> timer:sleep(600).

where_is_my_pizza() ->
    ?PIZ ! {what_takes_so_long, self()}.