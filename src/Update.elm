module Update exposing (update)

import Ports
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveAmount xs ->
            ( { model
                | amount =
                    model.amount
                        + xs
                        |> clamp 0.25 (1 / 0)
              }
            , Cmd.none
            )

        SetView v ->
            ( { model | view = v }
            , Cmd.none
            )

        AuthedCb xs ->
            ( { model | seeds = xs }
            , Cmd.none
            )

        RecipientChange xs ->
            ( { model | recipient = xs }
            , Cmd.none
            )

        PriceCb xs ->
            ( { model
                | priceInProgress = False
                , activeSeed =
                    model.activeSeed
                        |> Maybe.map
                            (\seed ->
                                { seed
                                    | balance =
                                        xs
                                            |> Maybe.withDefault seed.balance
                                }
                            )
              }
            , Cmd.none
            )

        SigCb xs ->
            ( { model
                | sig = xs
                , txInProgress = False
              }
            , Cmd.none
            )

        ChangeSeed ->
            ( { model
                | activeSeed = Nothing
                , sig = Nothing
              }
            , Cmd.none
            )

        SeedCb xs ->
            ( { model
                | activeSeed = xs
                , sig = Nothing
                , selectInProgress = False
              }
            , Cmd.none
            )

        Deauth n ->
            ( { model
                | seeds =
                    model.seeds
                        |> List.filter (\x -> x.authToken /= n)
                , activeSeed = Nothing
                , sig = Nothing
              }
            , Ports.deauthorize n
            )

        Copy x ->
            ( model
            , Ports.copy x
            )

        FetchSeeds ->
            ( model
            , Ports.authorizeSeeds ()
            )

        RefreshPrice wallet ->
            ( { model | priceInProgress = True }
            , Ports.refreshPrice wallet
            )

        FetchSeed xs ->
            ( { model | selectInProgress = True }
            , Ports.fetchSeed xs
            )

        SendSui seed ->
            if String.isEmpty model.recipient then
                ( model, Cmd.none )

            else
                ( { model
                    | sig = Nothing
                    , txInProgress = True
                  }
                , Ports.submitTx
                    { amount = model.amount
                    , seed = seed
                    , recipient = model.recipient
                    }
                )
