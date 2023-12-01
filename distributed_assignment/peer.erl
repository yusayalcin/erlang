-module(peer).
% -export([peer/1, seeder/1]).
% -export([peer_init/1, seeder_init/1, loop/6]).
-compile(export_all).

peer(Torrent) ->
    spawn_link(?MODULE, peer_init, [Torrent]).

peer_init([{announce, {tracker,Tracker}},
        {info, Info}]) ->
    FileName = proplists:get_value(name, Info),
    Pieces = proplists:get_value(pieces, Info),
    timer:send_interval(2000, {tracker, Tracker}, {get, self()}),
    receive
        {tracker_response, List} ->
            {ok, File} = file:open(FileName, [write]),
            Indices = lists:seq(1,length(Pieces)),
            [Pid ! {have_pieces, [], self()} || Pid <- List, Pid /= self()],
            loop(Info, List, #{}, [], Indices, File)
    end.

seeder(Torrent) ->
    spawn_link(?MODULE, seeder_init, [Torrent]).

seeder_init([{announce, {tracker,Tracker}},
        {info, Info=[{name, FileName},
        {piece_length, _PieceLength}, 
        {pieces, Pieces},
        {length, _Length}]}]) ->
    timer:send_interval(2000, {tracker, Tracker}, {get, self()}),
    receive
        {tracker_response, List} ->
            {ok, File} = file:open(FileName, [read]),
            Indices = lists:seq(1,length(Pieces)),
            [Pid ! {have_pieces, Indices, self()} || Pid <- List, Pid /= self()],
            loop(Info, List, #{}, Indices, [], File)
    end.

loop(Info, PeersList, DownloadSt, DownloadedPieces, RemPieces, File) ->
    receive
        {tracker_response, Peers} ->
            [Pid ! {have_pieces, DownloadedPieces, self()} || Pid <- Peers, Pid /= self()],
            NewDownloadSt = update_download_status(maps:iterator(DownloadSt), Peers, #{}), 
            loop(Info, Peers, NewDownloadSt, DownloadedPieces, RemPieces, File);
        {have_pieces, PieceIndices, Peer} ->
            NewDownloadSt = update_pieces_status(PieceIndices, Peer, DownloadSt),
            Pid = self(),
            Peer ! {have_pieces_response, DownloadedPieces, self()},
            spawn_monitor(?MODULE, download_random_piece, [Info, NewDownloadSt, RemPieces, File, Pid]),
            loop(Info, PeersList, NewDownloadSt, DownloadedPieces, RemPieces, File);
        {have_pieces_response, PieceIndices, Peer} ->
            NewDownloadSt = update_pieces_status(PieceIndices, Peer, DownloadSt),
            Pid = self(),
            spawn_monitor(?MODULE, download_random_piece, [Info, NewDownloadSt, RemPieces, File, Pid]),
            loop(Info, PeersList, NewDownloadSt, DownloadedPieces, RemPieces, File);
        {have, PieceIndex, Peer} ->
            NewDownloadSt = update_piece_status(PieceIndex, Peer, DownloadSt),
            loop(Info, PeersList, NewDownloadSt, DownloadedPieces, RemPieces, File);
        {request, PieceIndex, Peer} ->
            Offset = file_offset(PieceIndex, Info),
            PieceLength = proplists:get_value(piece_length, Info),
            {ok, Piece} = read_piece(Offset, PieceLength, File),
            Peer ! {piece, Piece},
            loop(Info, PeersList, DownloadSt, DownloadedPieces, RemPieces, File);
        {downloaded, PieceIndex} ->
            notify_peers(PeersList, PieceIndex),
            Pid = self(),
            spawn_monitor(?MODULE, download_random_piece, [Info, DownloadSt, RemPieces, File, Pid]),
            loop(Info, PeersList, DownloadSt, DownloadedPieces ++ [PieceIndex], lists:delete(PieceIndex, RemPieces), File);
        {'DOWN', _MonitorRef, _Type, _Object, {download_failed, PieceIndex}} ->
            NewRemPieces = RemPieces ++ [PieceIndex],
            Pid = self(),
            spawn_monitor(?MODULE, download_random_piece, [Info, DownloadSt, NewRemPieces, File, Pid]),
            loop(Info, PeersList, DownloadSt, DownloadedPieces, NewRemPieces, File)
    end.

update_download_status(I, List, Acc) ->
    case maps:next(I) of
        none -> Acc;
        {K, V, It} -> 
            NewList = lists:filter(fun(E) -> lists:member(E, List) end, V),
            update_download_status(It, List, Acc#{K=>NewList})
    end.


check_hash(Piece, Hsum) ->
    Hsum == crypto:hash(sha, Piece).

download_piece(Index, Peer) ->
    Peer ! {request, Index, self()},
    receive
        {piece, Piece} -> Piece
    after
        2000 ->
            exit({download_failed, Index})
    end.

save_piece(Piece, Offset, File) ->
    % file:pwrite(file:open(File, write), Offset, Piece).
    file:pwrite(File, Offset, Piece).

download_next_piece(Index, Hsum, Peer, Pid) ->
    case download_piece(Index, Peer) of
        Piece ->
            case check_hash(Piece, Hsum) of
                true ->
                    Pid ! {downloaded, Index},
                    Piece;
                false -> exit({download_failed, Index})
            end
    end.

select_next_piece(_, []) -> [];
select_next_piece(DownloadSt, RemPieces) ->
    % Index = lists:last(RemPieces),
    Index = lists:nth(rand:uniform(length(RemPieces)), RemPieces),
    Peer = maps:fold(fun(Key, Val, _Acc) when Key == Index -> lists:nth(1, Val);
                        (_, _, Acc) -> Acc
                    end, ok, DownloadSt),
    {Peer, Index}.

file_offset(Index, Info) ->
    PieceLength = proplists:get_value(piece_length, Info),
    (Index-1) * PieceLength.

download_random_piece(Info, DownloadSt, RemPieces, File, Pid) ->
    case select_next_piece(DownloadSt, RemPieces) of
        [] -> RemPieces;
        {Peer, Index} ->
            Pieces = proplists:get_value(pieces, Info),
            HashSum = lists:nth(Index, Pieces),
            Piece = download_next_piece(Index, HashSum, Peer, Pid),
            Offset = file_offset(Index, Info),
            save_piece(Piece, Offset, File)
    end.

notify_peers(Peers, Index) ->
    [Peer ! {have, Index, self()} || Peer <- Peers].
    
read_piece(Offset, Size, File) -> 
    % file:pread(file:open(File, read), Offset, Size).
    file:pread(File, Offset, Size).

update_piece_status(Index, Peer, DownloadSt) ->
    % #{Index := List} = DownloadSt,
    maps:update_with(Index, fun(List) -> 
                                case lists:member(Peer, List) of
                                    false -> List ++ [Peer];
                                    true -> List 
                                end
                            end, [Peer], DownloadSt).

update_pieces_status([], _Peer, DownloadSt) -> DownloadSt; 
update_pieces_status([Ind | T], Peer, DownloadSt) ->
    NewSt = update_piece_status(Ind, Peer, DownloadSt),
    update_pieces_status(T, Peer, NewSt).
