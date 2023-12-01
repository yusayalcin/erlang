-module(par).
-compile(export_all).

smap(F, L) ->                %sixth:smap(fun(X) -> X + 1 end, [2,3,4]).
    %lists:map(F, L).
    [F(E) || E <- L].

pmap(F, L) ->
    MainPid = self(),
    [spawn(fun() -> MainPid ! F(E) end) || E <- L],
    [receive
        A -> A
    end  || _ <- L].


pmap_register(F, L) ->
  Main = self(),
  NewL = lists:zip(lists:seq(1, length(L)), L),
  register(func, spawn(fun() -> comp(F, Main)end)),
  [func ! {I, E} || {I, E} <- NewL],
  Result = [
  receive
        {res, I, A} -> A
  end || {I, _E} <- NewL],
  func ! kill,
  Result.


comp(F, Main) ->
    receive
        {I, E} -> Main ! {res, I, F(E)},
        comp(F, Main);
        kill -> killed
end.