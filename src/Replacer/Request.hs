module Replacer.Request where

import Control.Monad.IO.Class
import Data.String.Interpolate
import Data.ByteString
import Network.HTTP.Req
import Network.HTTP.Client.TLS
import qualified Network.HTTP.Client as HTTP
import qualified Data.ByteString.Base64 as Base64
import qualified Data.ByteString.Char8 as ByteString

data Proxy = Proxy
  { host :: ByteString
  , port :: Int
  , user :: ByteString
  , password :: ByteString
  } deriving Show

parseProxy input =
  case ByteString.split ':' input of
    [host, port, user, password] ->
      case ByteString.readInt port of
        Just (port', mempty) -> Just $ Proxy host port' user password
        _                  -> Nothing
    _ -> Nothing

formatProxy (Proxy host port user password) =
  [i|#{host}:#{port}:#{user}:#{password}|]

request body headers response method url =
  runReq defaultHttpConfig $ req method url body response headers

requestWithProxy proxy body scheme response method url = do
  let authHeader =
        ("Proxy-Authorization", "Basic " <> Base64.encode (proxy.user <> ":" <> proxy.password))
      managerSettings = tlsManagerSettings
        { HTTP.managerModifyRequest = \request ->
            pure request
              {  HTTP.requestHeaders = authHeader : HTTP.requestHeaders request }
        }
  manager <- liftIO $ HTTP.newManager managerSettings
  let config =
        defaultHttpConfig
          { httpConfigProxy = Just $ HTTP.Proxy proxy.host proxy.port
          , httpConfigAltManager = Just manager
          }
  responseBody <$> runReq config (req method url body response scheme)
