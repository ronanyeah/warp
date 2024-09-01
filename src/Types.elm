module Types exposing (..)

import Ports exposing (..)


type alias Model =
    { seeds : List SeedAuth
    , activeSeed : Maybe Seed
    , amount : Float
    , recipient : String
    , sig : Maybe String
    , selectInProgress : Bool
    , txInProgress : Bool
    , priceInProgress : Bool
    , version : String
    , view : View
    }


type alias Flags =
    { version : String
    }


type Msg
    = SeedCb (Maybe Seed)
    | PriceCb (Maybe Float)
    | FetchSeed SeedAuth
    | ChangeSeed
    | FetchSeeds
    | Deauth Int
    | RecipientChange String
    | RefreshPrice String
    | Copy String
    | SendSui Seed
    | SigCb (Maybe String)
    | MoveAmount Float
    | AuthedCb (List SeedAuth)
    | SetView View


type View
    = ViewTransfer
    | ViewBridge
    | ViewGenesis
