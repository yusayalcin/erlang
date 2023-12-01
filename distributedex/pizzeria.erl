-module(pizzeria).
-compile(export_all).

-define(PIZ, {server, 'server@yusayalcin'}).


start(Menu) ->
    register(server, spawn_link(?MODULE, init, [Menu])).

init(Menu) ->
    InitState = {Menu, #{}},
    loop(InitState).

loop(State={Menu, Refs}) ->
    receive
        {order, Ref, Name} ->     case maps:is_key(Name, Menu) of 
                                        true -> Time = maps:get(Name, Menu),
                                                spawn(fun() -> cook(Ref, Time) end),
                                                loop({Menu, maps:put(Ref, cooking, Refs)});
                                        
                                        false -> loop(State)
                                    end;
        {result, Ref}     ->   loop({Menu, maps:update(Ref, ready, Refs)});

        {ready, Ref, Pid}       ->   case maps:get(Ref, Refs, "X") of
                                           ready -> Pid ! {status, ready};
                                           cooking -> Pid ! {status, cooking};
                                           _       -> Pid ! {status, not_avaialble}
                                    end,
                                    loop(State);

        {menu, Pid}                  -> Pid ! {takeMenu, Menu},
                                        loop(State)
    end.


cook(Ref, Time) ->
    timer:sleep(Time*1000),
    ?PIZ ! {result, Ref}.


order(Name) ->
    Ref= make_ref(),
    ?PIZ ! {order, Ref, Name},
    Ref.

ready(Ref) ->
    ?PIZ ! {ready, Ref, self()},
    receive
        {status, Status} -> Status
    end.


menu() ->
    ?PIZ !{menu, self()},
    receive
        {takeMenu, Menu} -> Menu
    end.

waiting(N) ->
    Menu = menu(),
    Num = rand:uniform(maps:size(Menu)),
    Items= maps:keys(Menu),
    Item = [E || {I, E} <- lists:zip(lists:seq(1, length(Items)), Items), I==Num],
    I = hd(Item),
    Ref = order(I),
    timer:sleep(N*1000),
    Res = ready(Ref),
    case Res of
        ready -> io:format("Eating... ~p~n", [I]);
        cooking -> io:format("Slow... ~p~n", [I])
    end.




%Extend the implementation with a menu/0 function to ask for the menu. Then implement a waiting/1 function that takes a number N as an argument. 
%It asks for the menu and randomly selects an item from the menu (use rand:uniform/1 that takes a number as an argument). 
%Then it sends the order and waits N seconds and asks for the status of the order. If the pizza is not ready it returns "Slow...." otherwise "Eating...".