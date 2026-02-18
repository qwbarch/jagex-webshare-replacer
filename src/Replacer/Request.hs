module Replacer.Request where

import Data.ByteString
import Network.HTTP.Req
import Network.HTTP.Client.TLS
import qualified Network.HTTP.Client as HTTP
import qualified Data.ByteString.Base64 as Base64

data Proxy = Proxy
  { host :: ByteString
  , port :: Int
  , user :: ByteString
  , password :: ByteString
  }

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
  manager <- HTTP.newManager managerSettings
  let config =
        defaultHttpConfig
          { httpConfigProxy = Just $ HTTP.Proxy proxy.host proxy.port
          , httpConfigAltManager = Just manager
          }
  responseBody <$> runReq config (req method url body response scheme)
