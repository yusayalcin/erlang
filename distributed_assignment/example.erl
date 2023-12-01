-module(example).
-export([torrent/0,best_joke/0]).

torrent() ->
    [{announce, {tracker,'tracker@localhost'}},
     {info, [{name, "best_joke.txt"},
               {piece_length, 10}, 
               {pieces, [<<144,97,44,79,199,4,194,244,143,154,34,189,138,48,7,64,111,87,173,245>>,
                        <<255,96,175,159,164,156,87,196,239,110,24,64,40,161,249,1,163,46,107,36>>,
                        <<205,25,238,158,63,224,79,220,63,204,4,73,168,50,232,187,216,156,2,47>>]},
               {length, 3 * 8 + 2}]}].

best_joke() ->
    string:join([lists:duplicate(8, C) || C <- [$a, $b, $c]], "\n").