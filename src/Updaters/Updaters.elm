module Updaters.Updaters exposing (..)

import Dict exposing ( Dict )
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Models.ChessBoard exposing (..)
import Models.Data exposing (..)
import Utils exposing (..)

-- parsePosition : Position -> String
-- parsePosition position =
--     case position of
--         (x, y) ->
--             String.fromInt(x) ++ String.fromInt(y)

type alias Msg = (Int, Int)

update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case msg of
        (x, y) ->
            let
                position = (x, y)
                piece = get (x, y) state.board
            in
                case piece of
                    Just concretePiece ->  
                        let 
                            moves = getMoves state.board position
                            newHighlightedTiles = flatten (map (advancedValidMoves state.board position) moves)
                            newState = { state | highlightedTiles = newHighlightedTiles,
                                                 selectedPiecePosition = (piece, Just position)
                                        }
                        in
                        ( newState , Cmd.none )
                    Nothing ->
                        case state.selectedPiecePosition of
                            (Just concreteSelectedPiece, Just concretePiecePosition) ->
                                if member position state.highlightedTiles then
                                    let
                                        newBoard = movePiece state.board concretePiecePosition concreteSelectedPiece position
                                    in
                                        ( { state | highlightedTiles = [], board = newBoard,
                                            selectedPiecePosition = ( Nothing, Nothing ) } , Cmd.none )
                                else
                                    ( { state | highlightedTiles = [], selectedPiecePosition = ( Nothing, Nothing ) } , Cmd.none )
                            ( Nothing, Nothing ) ->
                                ( { state | highlightedTiles = [], selectedPiecePosition = ( Nothing, Nothing ) } , Cmd.none )
                            (_, _) ->
                                ( state, Cmd.none )

getPiece : ChessBoard -> Position -> List Piece
getPiece board position =
    let piece = get position board
    in
        case piece of
            Just concretePiece ->
                [ concretePiece ]
            Nothing ->
                []

getPositionIfPiecePresent : ChessBoard -> Position -> List Position
getPositionIfPiecePresent board position =
    let piece = get position board
    in
        case piece of 
            Just concretePiece ->
                [ position ]
            Nothing ->
                []


getMoves : ChessBoard -> Position -> List Move
getMoves board position =
    let piece = getPiece board position
    in
        flatten (map (\p -> movesForPiece p.pieceType) piece)


-- Move Implementation

{-
    Moves piece to specified destination
-}
movePiece : ChessBoard -> Position -> Piece -> Position -> ChessBoard
movePiece board prevPosition piece newPosition =
    insert newPosition piece (dictRemove prevPosition board)

-- Move Logic

basicValidMoves : ChessBoard -> Position -> Move -> List Position
basicValidMoves board position move =
    let
        piece = get position board
    in
        case piece of
            Just concretePiece ->
                case move of
                    Diagonal ->
                        let
                            left = reverse (range 0 (x position - 1))
                            right = range (x position + 1) 7
                            up =  range (y position + 1) 7
                            down = reverse (range 0 (y position - 1))
                        in
                        flatten (map (\x -> discardRest board x) [ zip left up, zip left down, zip right up, zip right down ])
                    RetardJump ->
                        let
                            addTwoToX = [ ( x position + 2, y position + 1 ), ( x position + 2, y position - 1 )
                                        , ( x position - 2, y position + 1 ), ( x position - 2, y position - 1 ) ]
                            addTwoToY = [ ( x position + 1, y position + 2 ), ( x position + 1, y position - 2 )
                                        , ( x position - 1, y position + 2 ), ( x position - 1, y position - 2 ) ]
                        in
                        addTwoToX ++ addTwoToY
                    File ->
                        let
                            down = discardRest board (map (\offset -> ( x position + offset, y position)) (reverse (range -7 -1)))
                            up = discardRest board (map (\offset -> ( x position + offset, y position)) (range 1 7))
                        in
                            down ++ up
                    Rank ->
                        let
                            left = discardRest board (map (\offset -> ( x position, y position + offset)) (reverse (range -7 -1)))
                            right = discardRest board (map (\offset -> ( x position, y position + offset)) (range 1 7))
                        in
                            left ++ right
                    RetardWalk ->
                        case concretePiece.color of
                            White ->
                                let
                                    moved = x position == 2
                                    forward = if moved then [ ( x position + 1, y position ) ] else
                                                            [ ( x position + 1, y position) , (x position + 2, y position )]
                                    diagonal = flatten ( map ( getPositionIfPiecePresent board )
                                                        [ ( x position + 1, y position + 1 ) , ( x position + 1, y position - 1 ) ] )
                                in
                                    forward ++ diagonal
                            Black ->
                                let
                                    moved = x position == 5
                                    forward = if moved then [ ( x position - 1, y position ) ] else
                                                            [ ( x position - 1, y position) , (x position - 2, y position )]
                                    diagonal = flatten ( map ( getPositionIfPiecePresent board )
                                                       [ ( x position - 1, y position + 1 ) , ( x position - 1, y position - 1 ) ] )
                                in
                                    forward ++ diagonal
                    Single moveType ->
                        filter (oneAway position) (basicValidMoves board position moveType)
            Nothing ->
                []


oneAway : Position -> Position -> Bool
oneAway posA posB =
    member (x posA) [ x posB + 1, x posB - 1 ] || member (y posA) [ y posB + 1, y posB - 1 ]


advancedValidMoves : ChessBoard -> Position -> Move -> List Position
advancedValidMoves board pos move =
    let
        basics =
            basicValidMoves board pos move
    in
        filter isValidPos basics


discardRest : ChessBoard -> List Position -> List Position
discardRest board lst =
    case lst of
        head :: tail ->
            if member head (keys board) then
                [head]
            else
                head :: discardRest board tail
        [] ->
            []