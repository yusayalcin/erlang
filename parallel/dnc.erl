-module(dnc).
-compile(export_all).



sfib(0) -> 1;
sfib(1) -> 1;
sfib(N) -> sfib(N-1) + sfib(N-2).


pfib(0) -> 1;
pfib(1) -> 1;
pfib(N) -> 
        Main = self(),
        spawn(fun() -> Main ! sfib(N-1) end),
        spawn(fun() -> Main ! sfib(N-2) end),
        receive
            Val1 -> Val1
        end,
        receive
            Val2 -> Val2
        end,
        Val1 + Val2.
        % receive
        %     Val1 -> 
        %            receive
        %               Val2 -> Val1 + Val2
        %            end
        % end.


pfib_map(N) -> 
    [Val1, Val2] = pmap(fun sfib/1, [N-1, N-2]),
    Val1 + Val2.
    



pmap(F, L) ->            % sorted starting by the fastest
    MainPid = self(),
    [spawn(fun() -> MainPid ! F(E) end) || E <- L],
    [receive
        A -> A
    end  || _ <- L].

pfib_dnc(0) -> 1;
pfib_dnc(1) -> 1;
pfib_dnc(N) when N < 30 -> 
    sfib(N);
pfib_dnc(N) -> 
        Main = self(),
        spawn(fun() -> Main ! pfib_dnc(N-1) end),
        spawn(fun() -> Main ! pfib_dnc(N-2) end),
        receive
            Val1 -> 
                   receive
                      Val2 -> Val1 + Val2
                   end
        end.



pfib_dnc_limit(N) -> pfib_dnc(N, 200).
pfib_dnc(0, _B) -> 1;
pfib_dnc(1, _B) -> 1;
pfib_dnc(N, B) when B < 2  -> 
    sfib(N);
pfib_dnc(N, B) -> 
        Main = self(),
        spawn(fun() -> Main ! pfib_dnc(N-1, B div 2) end), 
        spawn(fun() -> Main ! pfib_dnc(N-2, B div 2) end),
        receive
            Val1 -> 
                   receive
                      Val2 -> Val1 + Val2
                   end
        end.





% pfib_dnc_c(N, B) -> 
%     CountPid = spawn(fun() -> count(0, B)end),
%     pfib_dnc_counter(N, CountPid).
% pfib_dnc_counter(0, _) -> 1;
% pfib_dnc_counter(1, _) -> 1;
% pfib_dnc_counter(N, CountPid) -> 
%         Main = self(),
%         CountPid ! {allow_par, Main},
%         receive
%             not_allowed ->  sfib(N);
%             allowed ->
%                         spawn(fun() -> Main ! pfib_dnc_counter(N-1, CountPid )  end), % it can be just B too, its not really important
%                         spawn(fun() -> Main ! pfib_dnc_counter(N-2, CountPid) end),
%                         receive
%                             Val1 -> 
%                                 receive
%                                     Val2 -> Val1 + Val2
%                                 end
%                         end
%           end.


% count(Started, B) ->
%             receive
%                 {allow_par, From} when Started < B - 2 -> From ! allowed,
%                                                           count(Started+2, B);
%                 {allow_par, From}  ->     From ! not_allowed,
%                                           count(Started, B)
% end.

pfib_dnc_c(N, B) -> 
    register(count, spawn(fun() -> count(0, B)end)),
    Result = pfib_dnc_counter(N),
    count ! stop,
    Result.
pfib_dnc_counter(0) -> 1;
pfib_dnc_counter(1) -> 1;
pfib_dnc_counter(N) -> 
        Main = self(),
        count ! {allow_par, Main},
        receive
            not_allowed -> sfib(N);
            allowed ->
                        spawn(fun() -> Main ! pfib_dnc_counter(N-1) end), 
                        spawn(fun() -> Main ! pfib_dnc_counter(N-2) end),
                        receive
                            Val1 -> 
                                receive
                                    Val2 -> Val1 + Val2
                                end
                        end
        end.


count(Init, B) ->
            receive
                stop                               -> io:format("Counter process terminated...~n");
                {allow_par, Pid} when Init < B - 2 ->  Pid ! allowed,
                                                             count(Init + 2 , B);
                {allow_par, Pid}                   ->   Pid ! not_allowed,
                                                              count(Init, B)
end.
        


% merge_sort([]) -> [];
% merge_sort(L) when length(L) == 1-> L;
% merge_sort(L) -> 
%     Main = self(),
%     {L1, L2} = lists:split(length(L) div 2, L),
%     spawn(fun() -> Main ! merge_sort(L1) end),
%     spawn(fun() -> Main ! merge_sort(L2) end),
%     receive
%         Val1 -> Val1
%     end,
%     receive
%         Val2 -> Val2
%     end,
%     lists:merge(Val1, Val2).

% %     - Implement a function bucket_sort/1
% % - It takes a list as an argument L
% % - The return value is the sorted L
% % - There are only two buckets. You put an element into the first
% % bucket if it is smaller than the mean of the list, and put the
% % element into the second bucket otherwise.
% % - The buckets need to be sorted with the bucket_sort/1 function.
% % - The input list is unique (there are no duplicates in it).
% % - The parallelization must be carried out in a divide and conquer style.

% %bucket_sort(L::lists()) -> SortedResult::list()


% bucket_sort([]) -> [];
% bucket_sort([X])-> [X];
% bucket_sort(L) ->
%     Main = self(),
%     Mean = mean(L),
%     {L1, L2} = partition(L, Mean),
%     % L1 = lists:filter(fun(X) -> X < Mean end, L),
%     % L2 = lists:filter(fun(X) -> Mean =< X end, L),
%     spawn(fun() -> Main ! bucket_sort(L1) end),
%     spawn(fun() -> Main ! bucket_sort(L2) end),
%     receive
%         Val1 -> Val1
%     end,
%     receive
%         Val2 -> Val2
%     end,
%     lists:merge(Val1, Val2).

% partition([], _) -> {[], []};
% partition([X|Xs], Mean) ->
%         {L1, L2} = partition(Xs, Mean),
%         if X < Mean -> {[X|L1], L2};
%            true -> {L1, [X|L2]}
%         end.
    
% mean(L) -> lists:sum(L) div length(L).