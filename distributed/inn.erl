-module(inn).
-compile(export_all).

-define(INN, {server, 'server@yusayalcin'}).

create_goblins(N) ->
    %register(server, spawn_link(?MODULE, init, [])),
    io:format("the inn is open with ~p goblin today ~n",[N]),
    %[spawn(fun() -> goblin(_Bed=free) end) || _ <- lists:seq(1, N)].
    %lists:foreach(fun(Goblin) -> register(goblin, Goblin) end, Goblins).
    Bed= free,
    [spawn(fun() -> goblin(Bed) end) || _ <- lists:seq(1,N)].
    
%[register(integer_to_list(I), spawn_link(?MODULE, goblin, [Bed])) || {I, _} <- lists:zip(lists:seq(1, N),lists:seq(1,N))].

traveler() ->
        io:format("hello hello, I am traveler ~n"),
        spawn(fun() -> inn_adventure() end).


        % asks all the goblins (use global:registered_names() to retrieve them)  if they let him pass to get to the inn bed ({use_bed,TravelerId}) .
        
        %     if half plus one DINSTINCT goblins allow it ({granted, GoblinId}) traveller can pass (traveller needs N/2+1 grants with N= amount of currently registered Goblins)
        %         if he succeeds he removes from the message box all the other messages from other goblins
        %         then he tells all the goblins he will sleep ({on_bed,TravelerId})
        %         he will Nap for 1 to 5 seconds (rand:uniform/1)
        %         finally, he will tell ALL the goblins he is leaving ({leaving_bed,TravelerId})
        %     otherwise, (N/2+1 goblin {grunted, GoblinId}), he will wait 3 seconds and try again
        
inn_adventure() ->
    Goblins=global:registered_names(),
    [El ! {use_bed,self()} || El <- Goblins],
    NeededNum = length(Goblins)/2 + 1,
    L = lists:filter(fun(El) -> {granted, El} end, Goblins),
    case length(L) =< NeededNum of
        true -> [El ! {on_bed, self()} || El <- Goblins],
                Sleep = rand:uniform(5),
                io:format("sleeping now"),
                timer:sleep(Sleep*1000),
                [El ! {leaving_bed,self()} || El <- Goblins],
                io:format("was good sleep tnx");
                %inn_adventure();
        
        false -> io:format("I need ~p more goblin to stay here~n",[NeededNum-length(L)]), 
                timer:sleep(3000),
                 inn_adventure()
    end.
        


goblin(Bed=free) ->
    receive
        {use_bed,TravelerId} -> io:format("Can I rest here ~p~n",[self()]),
                                handlebed(TravelerId, Bed, rand:uniform(6)),
                                goblin(Bed);

        {on_bed,TravelerId} ->  io:format("traveler ~p is resting ~n",[TravelerId]),
                                 goblin(TravelerId);

        {leaving_bed,TravelerId} -> case TravelerId==Bed of
                                        true -> io:format("traveler ~p left the bed ~n",[Bed]),
                                                goblin(free);
                                        _    -> goblin(Bed)
                                    end
    end.

handlebed(TravelerId, Bed, Dice) ->
    case Bed  of 
        free -> io:format("Nobody is sleeping here~n"),
                case Dice of 
                    1 ->  io:format("~p goblin didnt want me to stay ~n",[self()]),
                         TravelerId ! {grunted, self()};
                    _ -> io:format("~p goblin tnx for approving ~n",[self()]),
                        TravelerId ! {granted, self()}
                end;
        _    -> io:format("traveler ~p is not the on currently resting in bed. It is ~p~n",[TravelerId, Bed]),
            TravelerId ! {grunted, self()}

    end.
