-module(pizzeria1).
-compile(export_all).

-define(PIZ, {pizzeria, 'pizzeria@yusayalcin'}).

start(Menu) ->
    register(pizzeria, spawn_link(?MODULE, init, [Menu])).

init(Menu) ->
    InitState  = {Menu, #{}},
    loop(InitState).

loop(State={Menu, Refs}) ->
    receive
        {order, Ref, Pid, Name} ->  case maps:is_key(Name, Menu) of
                                        true -> Pid ! {ordered, Ref},
                                                Time = maps:get(Name, Menu),
                                                spawn(fun() -> cook(Ref, Time) end),
                                                loop({Menu, maps:put(Ref, cooking, Refs)});
                                        
                                        _   -> Pid ! {ordered, Ref},
                                               loop(State)
                                    end;

        {ready, Ref} ->     loop({Menu, maps:update(Ref, ready, Refs)});

        {is_ready, Pid, Ref} ->     case maps:is_key(Ref, Refs) of
                                    true -> Status = maps:get(Ref, Refs),
                                            Pid ! {status, Status},
                                            loop(State);

                                    _    -> Pid ! {status, not_available},
                                            loop(State)
                                    end;


        {menu, Pid}     -> Pid ! {getMenu, Menu},
                           loop(State)
    end.

cook(Ref, Time) ->
    timer:sleep(Time*1000),
    ?PIZ ! {ready, Ref}.

order(Name) -> 
    Ref = make_ref(),
    ?PIZ ! {order, Ref, self(), Name},
    receive
        {ordered, Ref} -> Ref
    end.



ready(Ref) ->
    ?PIZ ! {is_ready, self(), Ref},
    receive
        {status, Status} -> Status
    end.


menu() ->
    ?PIZ ! {menu, self()},
    receive
        {getMenu, Menu} -> Menu
    end,
    Menu.

waiting(N) ->
    Menu = menu(),
    %Menu = #{margherita=> 2, calzone => 15, mozzarella => 10, plain => 1},
    ItemNum = rand:uniform(maps:size(Menu)),
    Items = maps:keys(Menu),
    A = [Item || {I, Item} <- lists:zip(lists:seq(1, length(Items)), Items), I==ItemNum],
    ?PIZ ! {waiting, self(), hd(A), N}.
