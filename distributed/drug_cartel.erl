-module(drug_cartel).
-compile(export_all).

-define(DR, {server, 'server@yusayalcin'}).

guard(Psw) ->
    register(server, spawn_link(?MODULE, init, [Psw])).

init(Psw) ->
    InitState = {#{}, Psw},
    loop(InitState).

loop(State={List, Psw}) -> 
    receive
        stop  -> io:format("stop~n");

        dump  -> io:format("The pids: ~p~n", [List]);

        {let_in, Who} -> Who ! whats_the_password,
                         loop(State);

        {password, Password, Who} when Password == Psw -> Who ! come_in,
                                       loop({maps:put(Who, come_in, List), Psw});
        
        {password, _Password, Who} -> Who ! go_away,
                                     loop(State);

         im_a_cop                 -> maps:foreach(fun(E, _) ->
                                        E ! {cops_are_here, "I'm outta here!"}
                                   end , List),
                                   io:format("RUN....~n")
    end.


bad_guy(Psw) -> 
    ?DR ! {let_in, self()},
    receive
        whats_the_password -> ?DR ! {password, Psw, self()},
                               receive
                                   go_away -> io:format("Guard didn't let me in.~n");
                                   come_in -> io:format("I am in~n"),
                                        receive
                                            {cops_are_here, Msg} -> Msg
                                        end
                                end
    end.

fbi() ->
    ?DR ! {let_in, self()},
    receive
        whats_the_password -> ?DR ! im_a_cop
    end.

stop() ->
    ?DR ! stop.



%Define a function bad_guy/1 that takes the password as argument. The function sends a 'let in' message with the identifier of the current process to a process registered as guard. 
% When the guard asks for the password, the function sends it to the guard. If the guard replies with 'come in', the function waits for the alert. 
% When the cops show up, the function returns the string "I'm outta here!".
%  Otherwise, if the guard replies with 'go away', the function returns the string"Guard didn't let me in.".