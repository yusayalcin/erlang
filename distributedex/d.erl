-module(d).
-compile(export_all).

-define(GUARD, {server, 'server@yusayalcin'}).

warehouse() ->
    Psw="123",
    WrongPsw="12",
    register(server, spawn_link(?MODULE, guard, [[], Psw])),
    [spawn(fun() -> bad_guy(Psw) end) || _ <- lists:seq(1,3)],
    [spawn(fun() -> bad_guy(WrongPsw) end) || _ <- lists:seq(1,3)],
    timer:sleep(1000),
    fbi().



guard(List, Psw) ->
    receive
        {let_in, Who}  ->       io:format("Whats the password nig*a.~n"),
                                Who ! whats_the_password,
                                guard(List, Psw);

        {password, Password, Who}  when Password == Psw -> io:format("Correct welcome bref~n"),
                                                           Who ! come_in,
                                                           guard(List++[Who], Psw);

        {password, _Password, Who} -> io:format("F off~n"),
                                     Who ! go_away,
                                     guard(List, Psw);

        im_a_cop                -> io:format("Run away bref~n"),
                                    [El ! cops_are_here || El <- List]

    end.

bad_guy(Password) ->
    ?GUARD ! {let_in, self()},
    receive
        whats_the_password -> ?GUARD ! {password, Password, self()},
                                receive
                                    go_away -> io:format("Guard didn't let me in.~n");
                                    come_in ->
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

