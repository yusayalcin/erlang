-module(test1).
-compile(export_all).


-define(VEN, {vending_machine, 'server@yusayalcin'}).

start(Price) ->
    register(vending_machine, spawn_link(?MODULE, init, [Price])),
    ok.

init(Price) -> 
    InitState = {[], Price},
    loop(InitState).

loop(State={Beverage, Price}) ->
    io:format("Machine : The machine is ready to accept orders!~n"),
    receive
        stop ->  io:format("Machine : Closing the vending machine... Bye!~n");

        {refill_machine, List} ->  io:format("Adding elements to the machine:~p~n", [List]),
                                   loop({Beverage ++ List, Price});
       
        print_content          ->  io:format("Machine : Available beverages: ~p~n", [Beverage]),
                                   loop(State);

        print_price            ->  io:format("Machine : The price is set to: ~p~n", [Price]),
                                   loop(State);

        {change_price, NewPrice} -> loop({Beverage, NewPrice});

        {insert_coins, Amount, Pid} when Amount < Price -> Pid !  insufficient_founds,
                                                             loop(State);
        {insert_coins, Amount, Pid} when Amount >= Price    -> Pid ! {enough, lists:usort(Beverage)},
                                          receive
                                            cancel -> Pid ! {cancelled, Amount};
                                            {select_beverage, Order, Pid} -> 
                                                case lists:member(Order, Beverage) of
                                                    true -> Pid ! {serve, Order, Price-Amount};
                                                    false -> Pid ! unavailable
                                                end
                                                after 10000 ->  io:format("Ordering timed out!~n"),
                                                        loop(State)
                                          end,
                                          loop(State)
                                        

    end.


 %The client orders a drink from the selection (`select_beverage/1`): The machine serves the order and returns the additional money that was above the price of the drink. 
% For example, the amount $150$ was inserted and the price of drinks is $120$, then the drink and $30$ is returned. The machine continues accepting new orders.

refill_machine(List) ->
    ?VEN ! {refill_machine, lists:merge([[Beverage || _ <- lists:seq(1, Amount)]|| {Beverage, Amount} <- List])},
    ok.

print_content() ->
    ?VEN ! print_content,
    ok.

print_price() ->
    ?VEN ! print_price,
    ok.

change_price(Price) ->
    ?VEN ! {change_price, Price},
    ok.

stop() ->
    ?VEN ! stop,
    stop.


item_list() ->
        [{coke, 2}, {fanta, 3}, {sprite, 1}, {tonic, 1}, {water, 3}].
 

insert_coins(Amount) ->
    ?VEN ! {insert_coins, Amount, self()},
    receive
        insufficient_founds -> io:format("not enough money~n");
        {enough, List}      ->  io:format("Select an item from the list (waiting time 10 sec):~p~n",[List])
    end.


select_beverage(Order) ->
    ?VEN ! {select_beverage, Order, self()},
    receive
        {serve, Order, _Price} -> io:format("Requested drink: ~p~n",[Order]);
                   unavailable -> io:format("not available ~n")
                          
        end.

cancel() ->
    ?VEN ! cancel,
    receive
        {cancelled, Amount} -> io:format("Money returned: ~p~n", [Amount]),
        cancelled
    end.

%   - `select_beverage/1` -- The function gets an atom (name of some beverage) and sends a request to the server. The return value of the function can be:
%- the name of the requested drink, if the transaction succeeded

%- the atom `insufficient_founds`, if the user has not inserted coins previously

%- the atom `unavailable`, if there desired drink is not available in the machine