-module(p).
-compile(export_all).

-define(PIZ, {server, 'pizzeria@yusayalcin'}).

% p:start(#{margherita=> 2, calzone => 15, mozzarella => 10, plain => 1}).
% Ref = p:order(plain).
% p:ready(Ref).

% Ref2 = p:order(calzone).
% p:ready(Ref2). 

% Ref3 = p:order(calzonellll).
% p:ready(Ref3).  

start(Args) ->
    register(server, spawn_link(?MODULE, init, [Args])).

init(Args) ->
    InitState = {Args, #{}},
    loop(InitState).

loop(State={Menu, Refs}) -> 
    receive
        stop                         -> io:format("stopped~n");

        {order, Pid, Ref, PizzaName} -> case maps:is_key(PizzaName, Menu) of 
                                            true -> Pid ! {ordered, Ref},
                                                    Time = maps:get(PizzaName, Menu),
                                                    spawn(fun() -> cook(Ref, Time) end),
                                                    loop({Menu, maps:put(Ref, cooking, Refs)});
                                            false -> Pid ! {ordered, Ref},
                                                     loop({Menu, maps:put(Ref, not_avaialble, Refs)})
                                        end;
        {cooked_or_not, ready, Ref}  -> loop({Menu, maps:update(Ref, ready, Refs)});

        {ready, Pid, Ref}            -> case maps:get(Ref, Refs, "X") of
                                            ready -> Pid ! {status, ready};
                                            cooking -> Pid ! {status, cooking};
                                            _     -> Pid ! {status, not_avaialble}
                                        end,
                                        loop(State);
        
        {waiting, Pid}                     -> Pid ! {getMenu, Menu}
                                         
    end.


cook(Ref, Time) ->
    timer:sleep(Time*1000),
    ?PIZ ! {cooked_or_not, ready, Ref}.

order(PizzaName) ->
    Ref = make_ref(),
    ?PIZ ! {order, self(), Ref, PizzaName},
    receive
        {ordered, Ref} -> Ref
    end.

ready(Ref) ->
    ?PIZ ! {ready, self(), Ref},
    receive
        {status, Status} -> Status
    end.

stop() ->
    ?PIZ ! stop.

waiting(N) -> 
    ?PIZ ! {waiting, self()},
    receive
        {getMenu, Menu} -> Menu
    end,
    A = rand:uniform(size(Menu)),
    Keys = maps:keys(Menu),
    Pizza = x(A, Keys),
    order(Pizza).

x(A, [_H|T]) when A > 1 ->
    x(A-1, T);

x(_A, [H|_T]) -> H.
