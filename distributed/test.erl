-module(test).
-compile(export_all).


-define(VEN, {vending_machine, 'vm@yusayalcin'}).

start(Price) ->
    register(vending_machine, spawn_link(?MODULE, init, [Price])),
    ok.

%    - the machine maintains a state of the available drinks (`Items`) and the unit price (`Price`). At startup, there are no available items, only the price is given.

init(Price) ->
    InitState = {[], Price},
    loop(InitState).

loop(State={Items, Price}) -> 
    io:format("Machine : The machine is ready to accept orders!~n"),
    receive
        stop -> io:format("Machine : Closing the vending machine... Bye! ~n");

        print_content -> io:format("Available beverages:~p~n",[Items]),
                                    loop(State);

        {refill_machine, List} -> io:format("Adding elements to the machine:~p~n",[List]),
                                  loop({Items++List, Price});
        
        print_price            -> io:format("Machine : The price is set to:~p~n",[Price]),
                                  loop(State);
        
        {change_price, NewPrice}  -> loop({Items, NewPrice});

        {insert_coins, Pid, Amount} when Amount < Price -> Pid !  insufficient_founds,
                                                            loop(State);

        {insert_coins, Pid, Amount}  -> Pid ! {success, lists:usort(Items)},
                                    receive
                                        {cancel, Pid} -> io:format("Money returned: ~p~n",[Amount]),
                                                Pid ! cancelled,
                                            loop(State);
                                        {beverage, Name} -> io:format("Select an item from the list (waiting time 10 sec):~p~n",[ists:usort(Items)]),
                                                            case lists:member(Name, Items) of
                                                                true -> io:format("Ordering ~p was successful. Money returned: ~p~n",[Name, Amount-Price]),
                                                                        Pid ! {req, Name, Amount-Price},
                                                                        loop({lists:delete(Name, Items), Price});
                                                                    %loop(maps:remove(Arg1, Arg2))
                                                                false -> Pid ! {req, unavailable},
                                                                        loop(State)
                                                            end
                                                        
                                                            %loop(State)
                                        after 10000 ->  io:format("Ordering timed out!~n"),
                                                    loop(State)
                                        
                                    end
    end.

% - The client orders a drink from the selection (`select_beverage/1`): The machine serves the order and returns the additional money that was above the price of the drink. 
%  For example, the amount $150$ was inserted and the price of drinks is $120$, then the drink and $30$ is returned. The machine continues accepting new orders.
stop() ->
    ?VEN ! stop,
    stop.

print_content() ->
    ?VEN ! print_content,
    ok.

refill_machine(List) ->
    ?VEN ! {refill_machine, lists:merge([[B  || _ <- lists:seq(1, A)] || {B, A} <- List])},
    ok.

item_list() ->
        [{coke, 2}, {fanta, 3}, {sprite, 1}, {tonic, 1}, {water, 3}].

print_price() ->
    ?VEN ! print_price,
    ok.

change_price(NewPrice) ->
    ?VEN ! {change_price, NewPrice},
    ok.


insert_coins(Amount) -> 
    ?VEN ! {insert_coins, self(), Amount},
    receive
        insufficient_founds -> insufficient_founds;
        {success, List} -> io:format("~p~n",[List])
    end.


select_beverage(Name) ->
    ?VEN ! {beverage, Name},
    receive
        {req, Drink, Price} -> Drink;
        {req, insufficient_founds} -> insufficient_founds;
        {req, unavailable} -> unavailable
    end.

cancel() ->
    ?VEN ! {cancel, self()},
    receive
        cancelled -> cancelled
    end.
%  - `select_beverage/1` -- The function gets an atom (name of some beverage) and sends a request to the server. The return value of the function can be:

%- the name of the requested drink, if the transaction succeeded

%- the atom `insufficient_founds`, if the user has not inserted coins previously

%- the atom `unavailable`, if there desired drink is not available in the machine