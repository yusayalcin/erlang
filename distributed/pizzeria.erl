-module(pizzeria).
-compile(export_all).

-define(PIZ, {server, 'pizzeria@yusayalcin'}).

% pizzeria:start(#{margherita=> 2, calzone => 15, mozzarella => 10, plain => 1}).
% Ref = pizzeria:order(plain).
% pizzeria:ready(Ref).         

% Ref2 = pizzeria:order(calzone).
% pizzeria:ready(Ref2).         

start(Args) ->
    register(server, spawn_link(?MODULE, init, [Args])).

init(Args) ->
    InitState = {Args, #{}},
    loop(InitState).

loop(_State={List, Refs}) ->
    receive
        {order, Pid, Ref, PizzaName} ->
            case maps:is_key(PizzaName, List) of
                true ->
                    Pid ! {ordered, Ref},
                    Time = maps:get(PizzaName, List),
                    spawn(fun() -> cook(Ref, Time) end),
                    loop({List, maps:put(Ref, cooking, Refs)})
                
            end;

        {ready, Ref} ->
            loop({List, maps:update(Ref, ready, Refs)});

        {check_ready, Ref, Pid} ->
            case maps:get(Ref, Refs) of
                cooking -> Pid ! {is_ready, cooking, Ref};
                ready -> Pid ! {is_ready, ready, Ref}
            end,
            loop({List, Refs})
    end.


cook(Ref, Time) ->
    timer:sleep(Time*1000),
    ?PIZ ! {ready, Ref}.




order(PizzaName) ->
    Id = make_ref(),
    ?PIZ ! {order, self(), Id, PizzaName},
    receive
        {ordered, Ref} -> Ref
    end.



ready(Ref) ->
    ?PIZ ! {check_ready, Ref, self()},
    receive
        {is_ready, Status, Ref} -> Status
    end.
