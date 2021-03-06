module Views.Views exposing (chessBoardView, loopComponent, view, viewTile)

import Html exposing (Html, button, div, h1, img, span, text)
import Html.Attributes exposing (class, id, src, classList)
import Html.Events exposing (onClick)
import Models.ChessBoard exposing (..)
import Models.Data exposing (..)
import Updaters.Updaters exposing (..)
import Utils exposing (..)


pieceImageAddress : Piece -> String
pieceImageAddress piece =
    "/pieces/" ++ pieceToString piece ++ ".png"

viewTile : State -> Tile -> Html Msg
viewTile state tile =
    let
        piece =
            get tile state.board
        basicTile =
            div
                [ classList [("tile", True)
                , ("highlighted", member tile state.highlightedTiles)
                , ("attackable", member tile state.attackTiles)]
                , onClick (x tile, y tile)
                ]
    in
    case piece of
        Just concretePiece ->
            basicTile
                [ img [ class "pieceImage", src (pieceImageAddress concretePiece) ] []
                ]

        Nothing ->
            basicTile []


gridIndexToTile : Int -> Tile
gridIndexToTile index =
    ( (index - 1) // 8, modBy 8 (index - 1) )


loopComponent : a -> Int -> List a
loopComponent component n =
    if n /= 0 then
        component :: loopComponent component (n - 1)

    else
        []


viewTurn : Color -> Html Msg
viewTurn turn =
    let
        turnImg = if turn == White then "white.png" else "black.jpg"
    in
        div [] [ 
            div [] [ text ( "Who's Turn: " ++  (colorToString turn)) ]
            ]

view : State -> Html Msg
view state =
    div []
        [ h1 [] [ text "Elmo Chess" ]
        , div [ id "pageContainer"] [
            chessBoardView state
            , viewTurn state.turn
        ] ]

-- This creates a list like [57,58,59,60,61,62,63,64,49,50,51,52,53,54,55,56,41,42,43,44...]
-- This is to correct the orientation of the board where White is at the bottom and the position
-- (0, 0) is at the bottom left.
boardRows: List Int
boardRows = flatten (reverse (map (\x -> (range (1 + x * 8) ((1 + x * 8) + 7))) (range 0 7)))

chessBoardView : State -> Html Msg
chessBoardView state =
    addLabelsToBoard (div [ id "board" ] (map (viewTile state) (map gridIndexToTile boardRows)))

addLabelsToBoard: Html Msg -> Html Msg
addLabelsToBoard board = 
    div [ id "boardContainer" ] [
    div [ id "boardWithFileLabels" ]
    [ div [id "fileLabels"] (map (\x -> div [class "fileLabel"] [ text x ]) (reverse ["a", "b", "c", "d", "e", "f", "g", "h"]))
    , board
    ], div [id "rankLabels"] (map (\x -> div [class "rankLabel"] [ text (String.fromInt x) ]) (range 1 8))
    ]
