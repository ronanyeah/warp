module Main exposing (main)

import Browser
import Ports
import Types exposing (..)
import Update exposing (update)
import View exposing (view)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { seeds = []
      , activeSeed = Nothing
      , amount = 0.25
      , selectInProgress = False
      , txInProgress = False
      , priceInProgress = False
      , recipient = ""
      , sig = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    [ Ports.seedCb SeedCb
    , Ports.sigCb SigCb
    , Ports.authedCb AuthedCb
    , Ports.priceCb PriceCb
    ]
        |> Sub.batch
