-module(pmfm).
-compile(export_all).



pmfm(_,_,_,[]) -> [];
pmfm(F, G, H, L) ->
    Main = self(),
    register(f, spawn(fun() -> f_helper(F) end)),
    register(g, spawn(fun() -> g_helper(G) end)),
    register(h, spawn(fun() -> h_helper(H, Main) end)),
    [f ! {fromMain, E} || E <- L],
    Res = [receive
        {fromH, E, true} -> E;
        {fromH, false} -> null
    end || _ <- L],
    f ! stop,
    g ! stop,
    h ! stop,
    lists:filter(fun(X) -> X /= null end, Res).    




f_helper(F) ->
    receive
        stop -> stopped;
        {fromMain, E} -> g ! {fromF, F(E)},
                         f_helper(F)
    end.

g_helper(G) ->
    receive
        stop -> stopped;
        {fromF, E} -> h ! {fromG, G(E), E},
                           g_helper(G)
    end.

h_helper(H, Main) ->
    receive
        stop -> stopped;
        {fromG, true, E} -> Main ! {fromH, H(E), true},
                            h_helper(H, Main);
        {fromG, false, _E} -> Main ! {fromH, false},
                              h_helper(H, Main)
    end.



    % pmfm:pmfm(fun(X)-> X end, fun erlang:is_atom/1, fun erlang:atom_to_list/1, []) ==[].

    % pmfm:pmfm(fun(X)-> X end, fun erlang:is_atom/1, fun erlang:atom_to_list/1, [1, apple, 2])==["apple"].
    
    % pmfm:pmfm(fun(X)-> X*2 end, fun(X)-> X rem 2 == 0 end, fun(X)-> X div 2 end, [1, 2, 3, 4, 5, 6]) ==[1, 2, 3, 4, 5, 6].
    
    % pmfm:pmfm(fun(X)-> X end, fun(X)-> X rem 2 == 0 end, fun(X)-> X div 2 end, [11, 12, 13, 14, 15, 16]) == [6,7,8].