-module(practice).
-compile(export_all).








multi(_F, [], []) -> [];
multi(F, L1, L2) ->
    Main = self(),
    Pids =[spawn(fun() -> Main ! {self(), applyF(F, E1, E2)} end)||  {E1,E2} <- zip(L1, L2)],
    Result = [
    receive
        {Pid, A} -> A
    end || Pid <- Pids],
    Result.
   
zip([], []) -> [];
zip([], _) -> [];
zip(_, []) -> [];
zip([H1|T1], [H2|T2]) ->
    [{H1,H2}] ++ zip(T1, T2).

applyF(F,E1,E2) ->
        try
            F(E1,E2)
        catch
            _:_ ->  {'EXIT',"Non matching types"}
        end.
    
    

% combine([], _) -> [];
% combine(_, []) -> [];
% combine([H1|T1],[H2|T2]) ->
%     [H1,H2] ++ combine(T1,T2).

% compute(F, Main) ->
%     receive
%         {I1, E1} -> receive
%                         {I2, E2} ->  Main ! {res, I1, I2, F(E1,E2)},
%         compute(F, Main);
%         kill -> killed
%     end
% end.




% pany(F, L) ->
%     Main = self(),
%     Pids= [spawn(fun() -> Main ! F(E) end) || E <-L],
%     [receive
%         A -> case A of
%                 true -> {true, 1};
%                 false -> false
%             end
%     end || Pid <- Pids].







% pany(F, L) ->
%     Main = self(),
%     IndL = lists:zip(lists:seq(1, length(L)), L),
%     register(func, spawn(fun() -> pp(F, Main) end)),
%     [func ! {I, E} || {I,E} <- IndL],
%     func ! kill,
%     receive
%         {res, I, true, A} -> {true, A};
%         {res, I, _, _} -> false
%     end.


    pany(F,L)->
        MainPid = self(),
        Pids = [spawn(fun()-> MainPid ! {F(E), E} end) || E <- L],
        Res = [receive 
            {true, Elem} -> {true, Elem};
            {false, _} -> false
        end || _  <- Pids],
        checkIfTrue(Res).
    checkIfTrue([])-> false;
    checkIfTrue([H|T])->
        case H of
            {Bool,Val} -> {Bool,Val};
            false -> checkIfTrue(T)
        end.


pp(F, Main) ->
    receive 
        {I,E} ->  Main ! {res, I, F(E), E},
                  pp(F, Main);
                  kill -> killed
    end.







