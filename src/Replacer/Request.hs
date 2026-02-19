module Replacer.Request where

import Network.HTTP.Req
import qualified Network.HTTP.Client as HTTP
import qualified Data.ByteString.Base64 as Base64
import Control.Monad.Reader
import Replacer.Proxy 
import Network.HTTP.Client (Response(responseStatus))
import Network.HTTP.Types (Status(statusCode))

-- | Send an http request. Allows manager config modification before sending the request.
request' modifyConfig body scheme response method url = do
  env <- ask
  let retryStatusCodes = [408, 429, 502, 503, 504]
      config =
        modifyConfig
          defaultHttpConfig
            { httpConfigRetryPolicy = env.retryPolicy
            , httpConfigRetryJudge = \_ response ->
                statusCode (responseStatus response) `elem` retryStatusCodes
            }
  responseBody <$> runReq config (req method url body response scheme)

-- | Send an http request without a proxy.
request body = request' id body

-- | Send an http request with a proxy. Allows manager config modification before sending the request.
requestWithProxy' modifyConfig (proxy :: Proxy) body scheme = request' withProxy body $ proxyHeader <> scheme
  where
    withProxy config =
        modifyConfig $
          config { httpConfigProxy = Just $ HTTP.Proxy proxy.host proxy.port }
    proxyHeader =
      header "Proxy-Authorization"
        $ "Basic " <> Base64.encode (proxy.user <> ":" <> proxy.password)

-- | Send an http request with a proxy.
requestWithProxy proxy = requestWithProxy' id proxy