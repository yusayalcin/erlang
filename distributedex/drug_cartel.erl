-module(drug_cartel).
-compile(export_all).

-define(GUARD, {server, 'guard@yusayalcin'}).

warehouse() ->
    Psw = 123,
    register(server, spawn_link(?MODULE, init, [Psw])),
    [spawn(fun() -> bad_guy(Psw) end) || _ <- lists:seq(1,2)],
    [spawn(fun() -> bad_guy(45) end) || _ <- lists:seq(1,2)],
    timer:sleep(1000),
    fbi().

init(Psw) ->
    InitState = {#{}, Psw},
    guard(InitState).
    %  After that, the function waits one second until it sends the FBI.

    % Hint: you can use timer:sleep/1 in order to suspend the current process.

guard(State={List, Psw}) ->
    receive
         {let_in, Who} -> Who ! whats_the_password,
                          guard(State);
                    
        {password, Password, Who} when Password == Psw -> Who ! come_in,
                                                    NewList = maps:put(Who, come_in, List),
                                                    guard({NewList, Psw});

        {password, _Password, Who} -> Who ! go_away,
                                     guard(State);
                
        im_a_cop ->                 maps:foreach(fun(El, _) ->
                                        El ! cops_are_here
                                    end , List)

    end.


bad_guy(Psw) ->
    ?GUARD ! {let_in, self()},
    receive
        whats_the_password -> ?GUARD ! {password, Psw, self()},
                                receive
                                    go_away -> io:format("Guard didn't let me in.~n");
                                    come_in ->   io:format("Trafficker In~n"),
                                                receive
                                
                                                    cops_are_here -> io:format("I'm outta here!~n")
                                                end
                                end
    end.

fbi() ->
    ?GUARD ! {let_in, self()},
    receive
        whats_the_password -> ?GUARD ! im_a_cop
    end.
