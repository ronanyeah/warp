port module Ports exposing (..)


type alias Seed =
    { pubkey : String
    , pubkeyBytes : List Int
    , balance : Float
    , auth : SeedAuth
    }


type alias SeedAuth =
    { name : String
    , authToken : Int
    }



-- OUT


port log : String -> Cmd msg


port copy : String -> Cmd msg


port deauthorize : Int -> Cmd msg


port refreshPrice : String -> Cmd msg


port authorizeSeeds : () -> Cmd msg


port fetchSeed : SeedAuth -> Cmd msg


port submitTx : { amount : Float, seed : Seed, recipient : String } -> Cmd msg



-- IN


port seedCb : (Maybe Seed -> msg) -> Sub msg


port priceCb : (Maybe Float -> msg) -> Sub msg


port sigCb : (Maybe String -> msg) -> Sub msg


port authedCb : (List SeedAuth -> msg) -> Sub msg
