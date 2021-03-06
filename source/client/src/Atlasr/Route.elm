module Atlasr.Route exposing (Route, toRoute)

import Atlasr.Position exposing (Position)
import Http
import Json.Decode
import Task
import Url.Builder exposing (absolute, string)


type alias Route =
    { points : List Position
    }


type alias RawRoute =
    { points : List Point
    }


type alias Point =
    { longitude : Float
    , latitude : Float
    }


emptyRoute : Route
emptyRoute =
    { points = [] }


{-| Get a route from a list of position.
-}
toRoute : (Result Http.Error Route -> msg) -> List Position -> Cmd msg
toRoute outputType positions =
    let
        task =
            if List.length positions <= 1 then
                Task.succeed emptyRoute

            else
                positionsToRouteRequest positions
                    |> Http.toTask
                    |> Task.map
                        (\route ->
                            Route
                                (List.map
                                    (\point ->
                                        ( point.longitude, point.latitude )
                                    )
                                    route.points
                                )
                        )
    in
    Task.attempt outputType task


{-| Create an HTTP request to get the route between positions.
-}
positionsToRouteRequest : List Position -> Http.Request RawRoute
positionsToRouteRequest positions =
    let
        url =
            absolute
                [ "api/route" ]
                ([ string "points_encoded" "false"
                 , string "vehicle" "car"
                 ]
                    ++ List.map
                        (\position ->
                            let
                                ( longitude, latitude ) =
                                    position
                            in
                            string "point" (String.fromFloat latitude ++ "," ++ String.fromFloat longitude)
                        )
                        positions
                )
    in
    Http.get url decodeRoute


{-| Decoder for the route payload from the HTTP service.
-}
decodeRoute : Json.Decode.Decoder RawRoute
decodeRoute =
    Json.Decode.at [ "paths", "0" ]
        (Json.Decode.map
            RawRoute
            (Json.Decode.at [ "points", "coordinates" ]
                (Json.Decode.list
                    (Json.Decode.map2
                        Point
                        (Json.Decode.field "0" Json.Decode.float)
                        (Json.Decode.field "1" Json.Decode.float)
                    )
                )
            )
        )
