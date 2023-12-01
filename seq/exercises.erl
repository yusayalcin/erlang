-module(exercises).
-export([difOfSquares/1, min/2, figure/1]).
-export([upperLower/1]).
-export([minimum/1]).
-export([zip/2]).
-export([tails/1]).
-export([tail/1]).
-export([primes/1]).

-export([lengh/1]).
-export([map/2]).
-export([reverse/1]).
-export([foldl/3]).
-export([foldr/3]).
-export([is_equal/2]).
-export([is_sublist/2]).
-export([is_superlist/2]).
-export([empty/0]).
-export([cons/2]).
-export([head/1]).
-export([count/1]).
-export([from_native_list/1]).
-export([to_native_list/1]).
-export([verse/1]).
-export([sing/2]).
-export([sing/1]).
-export([smallest/2]).
-export([largest/2]).

difOfSquares(N) ->
    L = lists:seq(1, N),
    X = lists:sum(L),
    Xx = X*X,
    Ls = [pow(E) || E <- L],
    Y = lists:sum(Ls),
    Xx-Y.


pow(E) -> E*E.


min(X, Y) when X =< Y -> X;
min(X, Y) when X > Y -> Y.



upperLower(X) when X >= $a, X =< $z 
        -> X - 32;
upperLower(X) when X >= $A, X =< $Z 
        -> X + 32;
upperLower(X) -> X.


    % 1)Using pattern matching only 

    % a)create a function that takes a tuple and recognise if it contains the sides of a triangle, a square or a rectangle, verifing that they are proper.
    
    % b)for triangle you should return if it is rectangle or not, and if it isosceles scalenus or equilateral.
    
    % Test> figure({1,2,3})= not_a_proper_triangle
    % Test> figure({2,2,3})= {isosceles,not_rectangle} 
    % Test> figure({2,2,2,2})= square


figure({A, B, C}) when A > 0, B > 0, C > 0  ->
        case {A == B, B == C, A == C} of
                {true, true, true} -> equilateral;
                _ -> triangle({A, B, C})
        end;

figure({A, B, C, D}) when A > 0, B > 0, C > 0, D > 0  ->
    case {A == B, B == C, B == D, A == C} of
        {true, true, true, true} -> square;
        {false, false, true, true} -> rectangle;
        _ -> not_proper_shape
        end.



triangle({A, B, C}) ->
            case {A == C, B == A, C == B} of
                {true, false, false} -> {isosceles,not_rectangle};
                {false, true, false} -> {isosceles,not_rectangle};
                {false, false, true} -> {isosceles,not_rectangle};
                _ -> scalenus({A,B,C})
        end.

scalenus({A, B, C}) ->
  case {A + B > C, B + C > A, A + C > B} of
        {true,true,true} -> scalenus;
        _  -> not_proper_triangle
    end.




    % 3)Using list comprehension and recursion

    % a)redefine the minimum function which returns the element with the smallest value in the list.
    
    % Test> 
    % minimum ([3,4,1,2]) = 1 

minimum([H,J|T]) when H < J ->
    minimum([H|T]);
minimum([_H,J|T]) ->
    minimum([J|T]);
minimum([H]) -> H.

% b)redefine the function for combining lists into a list of pairs (which is called zip).

% Test> 
% zip ([1,2], "abc")= [{1, 'a'}, {2, 'b'}]
    
zip([],[_]) -> [];
zip([_],[]) -> [];
zip([],[]) -> [];
zip([H1|T1], [H2|T2]) -> 
    [{H1,H2}] ++ zip(T1,T2). 


    % c)Generate all possible suffices for a list. 

    % Test> 
    % tails ("abc") =
    % ["abc", "bc", "c", []] 
    
    % Test2> 
    % tails ([1,2,3,4]) =
    % [[1, 2, 3, 4], [2, 3, 4], [3, 4], [4], []]


tails([H|T]) ->
    [[H|T]] ++ tails(T);

tails([]) -> [[]].


filter(F, L) -> 
    Ls = [ E || E <- L, F(E)==true],
    Ls.

lengh([_H|T]) ->
        1 + lengh(T);
    
lengh([]) -> 0.

map(F, L) -> 
    Ls = [F(E) || E <- L],
    Ls.

    reverse([H|T]) -> 
        reverse(T) ++ [H];
    reverse([]) -> [].

foldl(F, A, [H|T]) ->
        foldl(F, F(H, A), T);
foldl(_, A, []) ->
        A.

foldr(F, A, [H|T]) ->
        [X|Y] = reverse([H|T]),
        foldr(F, F(X, A), Y);
foldr(_, A, []) ->
        A.

        % foldr(Fun, Acc, [H|T]) ->
        %     Fun(H, foldr(Fun, Acc, T));
        % foldr(_, Acc, []) ->
        %     Acc.


aa(F, A, [H|T]) ->
            [X|Y] = reverse([H|T]),
            X.


          
        

         


is_equal([], []) -> true;
is_equal([H1|T1], [H2|T2]) -> 
    (H1 == H2) and is_equal(T1, T2);
is_equal(_, _) -> false.

is_sublist(L1, L2) when length(L1) < length(L2) ->
    L = [E || E<-L1, B <-L2, E== B],
    length(L) > 0;

is_sublist(_L1, _L2) ->
        false.


is_superlist(L1, L2)  when length(L1) > length(L2) ->
    L = [E || E<-L2, B <-L1, E== B],
    length(L) > 0;

is_superlist(_L1, _L2)  ->
    false.


relation(L1, L2) ->
        case is_equal(L1, L2) of
            true -> equal;
            false -> 
                case is_sublist(L1, L2) of
                    true -> sublist;
                    false -> not_equal
            end
        end.
        




        empty() -> [].

        cons(E, []) -> [E];
        cons(E, L) -> [E] ++ L.
        
        head([H|_T]) -> H.
        
        tail([_H|T]) -> T.
        
        
        count([]) -> 0;
        count([H|T]) -> 
            1 + count(T).
        
        to_native_list([]) -> [];
        to_native_list([H|_T]) -> [H].
        
        from_native_list([]) -> [];
        from_native_list(L) -> L.
        



verse(0) ->                        "No more bottles of beer on the wall, no more bottles of beer.\n" "Go to the store and buy some more, 99 bottles of beer on the wall.\n";
verse(1) ->                        integer_to_list(1) ++ " bottles of beer on the wall, "++  integer_to_list(1) ++ " bottles of beer.\n Take it down and pass it around, no more bottles of beer on the wall.\n";

verse(N) ->
             integer_to_list(N) ++ " bottles of beer on the wall, "++  integer_to_list(N) ++ " bottles of beer.\n Take one down and pass it around, " ++ integer_to_list(N-1) ++ " bottles of beer on the wall.\n".
        
        


sing(X, Y)  when X > Y -> 
                verse(X) ++ sing(X-1, Y);
sing(X, _Y) -> verse(X).

sing(N) when N > 1 ->
    verse(N) ++ sing(N-1);
sing(N) ->
    verse(N) ++ verse(N-1).
  
largest(Min, Max) when Min > Max ->
    "error result for largest if min is "
     "more than max";
largest(_Min, Max) when Max < 10 -> Max;
largest(Min, Max) when Min == Max ->
"empty result for largest if no palindrome "
     "in the range";

largest(Min, Max)  -> 
    A = integer_to_list(Max),
    case (A == reverse(A)) of
        true -> Max;
        _ -> largest(Min, Max-1)
    end.
    
smallest(Min, Max) when Min > Max ->
    "error result for smallest if min is "
     "more than max";

smallest(Min, Max) when Max < 10 ->
        Min;
smallest(Min, Max) when Min == Max ->
        "empty result for smallest if no palindrome "
     "in the range";

smallest(Min, Max)  -> 
        A = integer_to_list(Min),
        case (A == reverse((A))) of
            true -> Min;
            _ -> smallest(Min + 1, Max)

    end.




    primes(1) -> [];

    primes(N) when is_number(N) ->
    primes(N, generate(N)).
    
    primes(Max, [H|T]) when H * H =< Max ->
       [H | primes(Max, [R || R <- T, (R rem H) > 0])];
    
    primes(_, T) -> T.
    
    % Generate sequence 2..N
    generate(N) -> generate(N, 2).
    
    generate(Max, Max) -> [Max];
    
    generate(Max, X) -> [X | generate(Max, X + 1)].