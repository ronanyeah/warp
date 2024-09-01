module View exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FormatNumber
import FormatNumber.Locales exposing (usLocale)
import Helpers.View exposing (style, when, whenAttr)
import Html exposing (Html)
import Maybe.Extra exposing (unwrap)
import Types exposing (..)


view : Model -> Html Msg
view model =
    [ [ img "./logo.png" [ height <| px 45 ]
      , [ text "WARP"
            |> el
                [ Font.color black
                , titleFont
                , Font.size 50
                ]
        , "wallet"
            |> String.toList
            |> List.map (String.fromChar >> text)
            |> row [ spacing 12, centerX ]
        ]
            |> column []
      ]
        |> row
            [ spacing 20
            , centerX
            , padding 15
            , Border.width 2
            , Background.color white
            ]
    , model.activeSeed
        |> unwrap
            ([ [ [ text "Authorized Seeds"
                    |> el [ Font.bold, Font.size 24 ]
                 , spinner 22
                    |> when model.selectInProgress
                 ]
                    |> row [ width fill, spaceEvenly ]
               , model.seeds
                    |> List.map
                        (\seed ->
                            [ [ text ("▶  " ++ seed.name)
                              ]
                                |> paragraph []
                            , [ text "Select"
                                    |> pillBtn (Just <| FetchSeed seed) [ Font.size 17 ]
                              , text "Remove"
                                    |> btn (Just <| Deauth seed.authToken)
                                        [ Font.underline
                                        , Font.size 15
                                        ]
                              ]
                                |> row [ spacing 10 ]
                            ]
                                |> row [ width fill, spaceEvenly ]
                        )
                    |> column [ spacing 15, width fill ]
               ]
                |> column
                    [ spacing 15
                    , Background.color white
                    , width fill
                    , paddingXY 10 15
                    , fadeIn
                    , Border.width 2
                    ]
                |> when (List.isEmpty model.seeds |> not)
             , text "Authorize new seed"
                |> pillBtn (Just <| FetchSeeds) [ centerX ]
             , [ [ img "./github.png" [ height <| px 20 ]
                 , text "View Code"
                    |> el [ Font.size 20, Font.underline ]
                 ]
                    |> row [ spacing 10 ]
                    |> (\elem ->
                            newTabLink []
                                { url = "https://github.com/ronanyeah/warp"
                                , label = elem
                                }
                       )
               , text <| "v" ++ model.version
               ]
                |> row [ width fill, spaceEvenly, alignBottom ]
             ]
                |> column [ width fill, height fill, spacing 20 ]
            )
            (\seed ->
                [ [ [ [ text "Selected Seed:"
                            |> el [ Font.bold ]
                      , text seed.auth.name
                      ]
                        |> column [ spacing 5 ]
                    , text "Change"
                        |> btn (Just ChangeSeed) [ Font.underline, alignTop ]
                    ]
                        |> row [ width fill, spaceEvenly ]
                  , [ text "Sui Address:"
                        |> el [ Font.bold ]
                    , [ text (String.left 11 seed.pubkey ++ "..." ++ String.right 11 seed.pubkey)
                      , img "./clipboard.png" [ width <| px 18 ]
                      ]
                        |> row [ spacing 10 ]
                        |> btn (Just <| Copy seed.pubkey) []
                    ]
                        |> column [ spacing 5 ]
                  , [ text "Balance:"
                        |> el [ Font.bold ]
                    , text (formatFloat seed.balance ++ " SUI")
                    , img "./refresh.png"
                        [ spin
                            |> whenAttr model.priceInProgress
                        , height <| px 20
                        ]
                        |> btn (Just <| RefreshPrice seed.pubkey) []
                    ]
                        |> row [ width fill, spacing 10 ]
                  ]
                    |> column
                        [ spacing 10
                        , Background.color white
                        , width fill
                        , padding 10
                        , Border.width 2
                        ]
                , [ text "Transfer SUI"
                        |> el [ Font.bold ]
                  , [ img "./arrow.png" [ rotate (degrees 180), height <| px 50 ]
                        |> btn (Just <| MoveAmount -0.25) []
                    , model.amount
                        |> FormatNumber.format
                            { usLocale
                                | decimals = FormatNumber.Locales.Min 2
                            }
                        |> (\x -> x ++ " SUI")
                        |> text
                        |> el [ Font.size 30 ]
                    , img "./arrow.png" [ height <| px 50 ]
                        |> btn (Just <| MoveAmount 0.25) []
                    ]
                        |> row [ centerX, spacing 20 ]
                  , Input.text
                        [ Border.color black ]
                        { onChange = RecipientChange
                        , placeholder = Just <| Input.placeholder [] <| text "Wallet address or @SuiNS"
                        , text = model.recipient
                        , label =
                            text "Recipient:"
                                |> Input.labelAbove [ Font.bold ]
                        }
                  , text "Submit tx"
                        |> pillBtn (Just <| SendSui seed)
                            [ centerX
                            , spinner 22
                                |> el [ paddingXY 15 0, centerY ]
                                |> when model.txInProgress
                                |> onRight
                            ]
                  , model.sig
                        |> unwrap none
                            (\s ->
                                newTabLink ([ centerX, fadeIn ] ++ pillAttrs)
                                    { url = "https://suiscan.xyz/mainnet/tx/" ++ s
                                    , label = text "✅  View transaction"
                                    }
                            )
                  ]
                    |> column
                        [ spacing 15
                        , Background.color white
                        , width fill
                        , padding 15
                        , Border.width 2
                        ]
                ]
                    |> column [ spacing 10, width fill ]
            )
    ]
        |> column
            [ height fill
            , width fill
            , padding 20
            , spacing 20
            ]
        |> Element.layoutWith
            { options =
                [ Element.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ width fill
            , height fill
            , grad
            , mainFont
            , Font.size 20
            ]


pillAttrs : List (Attribute msg)
pillAttrs =
    [ Background.color grey
    , paddingXY 10 5
    , Border.shadow
        { offset = ( 2, 2 )
        , color = black
        , blur = 0
        , size = 1
        }
    , Border.rounded 10
    ]


pillBtn : Maybe msg -> List (Attribute msg) -> Element msg -> Element msg
pillBtn msg attrs elem =
    Input.button
        (attrs
            ++ pillAttrs
        )
        { onPress = msg
        , label = elem
        }


btn : Maybe msg -> List (Attribute msg) -> Element msg -> Element msg
btn msg attrs elem =
    Input.button attrs
        { onPress = msg
        , label = elem
        }


img : String -> List (Attribute msg) -> Element msg
img src attrs =
    image attrs
        { src = src
        , description = ""
        }


grad : Attribute msg
grad =
    Background.gradient
        { angle = degrees 30
        , steps =
            [ blue
            , purple
            ]
                |> List.reverse
        }


blue : Color
blue =
    rgb255 77 162 255


purple : Color
purple =
    rgb255 153 69 255


white : Color
white =
    rgb255 255 255 255


black : Color
black =
    rgb255 0 0 0


grey : Color
grey =
    rgb255 235 235 235


mainFont : Attribute msg
mainFont =
    Font.family [ Font.typeface "Montserrat" ]


titleFont : Attribute msg
titleFont =
    Font.family [ Font.typeface "Turret Road" ]


formatFloat : Float -> String
formatFloat =
    FormatNumber.format
        { usLocale
            | decimals = FormatNumber.Locales.Max 2
        }


fadeIn : Attribute msg
fadeIn =
    style "animation" "fadeIn 0.5s"


spin : Attribute msg
spin =
    style "animation" "rotation 0.7s infinite linear"


spinner : Int -> Element msg
spinner n =
    img "./notch.png" [ width <| px n ]
        |> el
            [ spin
            ]
