-module(vending_machine).

%% client interface
-export([
    test1/0,test2/0,test3/0,test4/0,  insert_coins/1,select_beverage/1, cancel/0,    student/1,queuing/1, queuing/2, item_list/0, connect_to_server/0
]).

%% Server interface
-export([
    start/1,    stop/0,    init/1,    initialize_state/1,    refill_machine/1,    change_price/1,    print_content/0,print_price/0
]).

-define(SRV, {vending_machine, 'vm@localhost'}).

start(PriceUnit) ->
    register(vending_machine, spawn_link(?MODULE, init, [PriceUnit])),
    ok.

stop() ->
    ?SRV ! stop.

init(Args) ->
    InitState = ?MODULE:initialize_state(Args),
    loop(InitState).

refill_machine(List) ->
    ?SRV !
        {refill_machine,
            lists:merge([[Beverage || _ <- lists:seq(1, Amount)] || {Beverage, Amount} <- List])}.

change_price(P) -> ?SRV ! {change_price, P}.

print_content() ->
    ?SRV ! print_content,
    ok.
print_price() ->
    ?SRV ! print_price,
    ok.

loop(State) ->
    {Beverages, Price} = State,
    io:format("Machine : The machine is ready to accept orders!~n"),
    receive
        stop ->
            terminate(State);
        {refill_machine, NewBeverages} ->
            io:format("Adding elements to the machine:~p~n",[NewBeverages]),
            loop({NewBeverages, Price}),
            ok;
        {change_price, NewPrice} ->
            loop({Beverages, NewPrice});
        print_content ->
            io:format("Machine : Available beverages: ~p~n", [Beverages]),
            loop(State);
        print_price ->
            io:format("Machine : The price is set to: ~p~n", [Price]),
            loop(State);
        {request, select_beverage, Pid, _} ->
            Pid ! {response, insert_money_first, Price},
            loop(State);
        {request, insert_coins, Pid, Amount} ->
            case Amount < Price of
                true ->
                    io:format("Insufficient founds! Items cost ~p. Money returned: ~p~n", [Price, Amount]),
                    Pid ! {response, not_enough_money},
                    loop(State);
                false ->
                    io:format("Machine : Accepting order only from ~p~n", [Pid]),
                    Pid ! {response, lists:usort(Beverages)},
                    receive
                        {request, select_beverage, Pid, Beverage} ->
                            case lists:member(Beverage, Beverages) of
                                true ->
                                    io:format("Ordering ~p was successful. Money returned: ~p~n", [Beverage, Amount - Price]),
                                    Pid ! {response, Beverage, Amount - Price},
                                    loop({lists:delete(Beverage, Beverages), Price});
                                false ->
                                    Pid ! {response, not_enough_beverage},
                                    loop(State)
                            end;
                        {request, cancel, Pid} ->
                            Pid ! {response, canceled, Amount},
                            loop(State)
                    after 10000 ->
                        Pid ! {response, canceled, Amount},
                        loop(State)
                    end
            end
    end.

initialize_state(PriceUnit) ->
    {[], PriceUnit}.

terminate(_State) ->
    io:format("Machine : Closing the vending machine... Bye!~n"),
    stop.
%----------------- CLIENT -----------------

insert_coins(Amount) ->
    ?SRV ! {request, insert_coins, self(), Amount},
    receive
        {response, not_enough_money} ->
            io:format("My money is not enough to buy anything, going home!:(~n"),
            not_enough_money;
        {response, Beverages} ->
            io:format("Select an item from the list (waiting time 10 sec): ~p~n", [Beverages]),
            Beverages
    end.

select_beverage(Beverage) ->
    io:format("I have selected ~p.~n", [Beverage]),
    ?SRV ! {request, select_beverage, self(), Beverage},
    receive
        {response, insert_money_first, Amount} ->
            io:format("Insert money first. Amount: ~p~n", [Amount]),
            insert_money_first;
        {response, Beverage, Amount} ->
            io:format("I bought a ~p. I am happy!:)~n", [Beverage]),
            [Beverage, Amount];
        {response, not_enough_beverage} ->
            io:format("Not enough beverage.~n"),
            not_enough_beverage;
        {response, canceled, Amount} ->
            io:format("Cancelled. Your money back: ~p~n", [Amount]),
            canceled
    end.

cancel() ->
    ?SRV ! {request, cancel, self()},
    receive
        {response, canceled, Amount} -> io:format("Cancelled. Your money back: ~p~n", [Amount])
    end.

item_list() ->
    [{coke, 2}, {fanta, 3}, {sprite, 1}, {tonic, 1}, {water, 3}].

student(Money) ->
    RandomValue = rand:uniform(1000),
    timer:sleep(RandomValue),
    Result = insert_coins(Money),
    case Result of
        not_enough_money ->
            ok;
        [] ->
            io:format("No beverage available.~n");
        Beverages ->
            SelectResult = select_beverage(
                lists:nth(rand:uniform(length(Beverages)), Beverages)
            ),
            case SelectResult of
                [Beverage, Amount] ->
                    io:format("Student: Here is your ~p. Your change: ~p~n", [Beverage, Amount]);
                not_enough_beverage ->
                    io:format("Student: Not enough beverage.~n");
                not_enough_money ->
                    io:format("Student: Not enough money.~n");
                canceled ->
                    io:format("Student: Cancelled.~n");
                insert_money_first ->
                    io:format("Student: Insert money first.~n")
            end
    end.

connect_to_server() ->
    net_adm:ping('vm@Andays-MacBook-Pro.local').

queuing(List) ->
    [spawn(fun() -> student(Money) end) || Money <- List].

queuing(List, Nodes) ->
    [spawn(Node, fun() -> student(Money) end) || Money <- List, Node <- Nodes].

test1() ->
    ?MODULE:start(120),
    ?MODULE:print_content(),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:print_content(),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:print_content(),
    ?MODULE:print_price(),
    ?MODULE:change_price(150),
    ?MODULE:print_price(),
    ?MODULE:stop().

test2() ->
    ?MODULE:start(120),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:insert_coins(150),
    ?MODULE:select_beverage(coke),
    ?MODULE:insert_coins(150),
    ?MODULE:cancel(),
    ?MODULE:insert_coins(150),
    ?MODULE:stop().


test3() ->
    ?MODULE:start(90),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:queuing([100,120,60,80,150]).

test4() ->
    ?MODULE:start(100),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:refill_machine(?MODULE:item_list()),
    ?MODULE:queuing([100,120,60,80,150,160,90,99,101,180,300,30]).