-module(test).
-compile(export_all).

-define(VEN, {vending_machine, 'vm@yusayalcin'}).

start(Price) ->
    register(vending_machine, spawn_link(?MODULE, init, [Price])),
    ok.


init(Price) ->
    InitState = {[], Price},
    loop(InitState).

loop(State={Items, Price}) ->
    io:format("Machine : The machine is ready to accept orders!~n"),
    receive
        print_content ->  io:format("Machine : Available beverages: ~p~n", [Items]),
                          loop(State);
        
        {refill_machine, List} -> io:format("Adding elements to the machine: ~p~n", [List]),
                                  loop({Items++List, Price});

        print_price            -> io:format("Machine : The price is set to: ~p~n", [Price]),
                                  loop(State);
        
        {change_price, NewPrice}  -> loop({Items, NewPrice});

        stop ->  io:format("Machine : Closing the vending machine... Bye!~n");

        {insert_coins, Pid, Amount} when Amount < Price-> Pid ! insufficient;

        {insert_coins, Pid, Amount} -> io:format("Select an item from the list (waiting time 10 sec): ~p~n", [Items]),
                                        Pid ! {sendList, lists:usort(Items)},
                                        receive
                                            {select, Pid, Name} -> Pid ! {success, Name, Amount-Price},
                                                                    loop({lists:delete(Name, Items), Price});
                                            
                                            {cancel, Pid}  -> Pid ! {cancelled, Amount},
                                                              loop(State)
                                            
                                            after 10000 -> io:format("Ordering timed out!~n"),
                                                            loop(State)
                                        end
                                             

    end.

print_content() ->
    ?VEN ! print_content,
    ok.

item_list() ->
    [{coke, 2}, {fanta, 3}, {sprite, 1}, {tonic, 1}, {water, 3}].

refill_machine(Items) ->
    ?VEN ! {refill_machine, lists:merge([[B   || _ <- lists:seq(1, A)]  || {B, A}  <- Items])},
    ok.

print_price() ->
    ?VEN ! print_price,
    ok.

change_price(NewPrice) ->
    ?VEN ! {change_price, NewPrice},
    ok.

stop() ->
    ?VEN ! stop.



insert_coins(Amount) ->
    ?VEN ! {insert_coins, self(), Amount},
    receive
        insufficient -> insufficient;
        {sendList, List} -> List
    end.

select_beverage(Name) ->
    ?VEN ! {select, self(), Name},
    receive
        {success, Drink, Amount} -> io:format("Ordering ~p was successful. Money returned: ~p~n",[Drink,Amount]),
                Drink;
        unavailable    -> unavailable
    end.

cancel() ->
    ?VEN ! {cancel, self()},
    receive
        {cancelled, Amount} -> io:format("Money returned: ~p~n",[Amount]),
                                cancelled
    end.