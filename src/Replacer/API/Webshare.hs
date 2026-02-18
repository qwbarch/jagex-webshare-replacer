module Replacer.API.Webshare where

import Control.Monad.Reader
import Data.Text
import Data.String.Interpolate
import Data.Aeson
import Data.Aeson.TH
import Network.HTTP.Req
import Replacer.Request

base = https "proxy.webshare.io" /: "api"

newtype DownloadTokenResponse = DownloadTokenResponse
  { proxyListDownloadToken:: Text }
  deriving Show

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''DownloadTokenResponse

requestWebshare body scheme s b = do
  apiKey <- asks (.apiKey)
  let tokenHeader = header "Authorization" [i|Token #{apiKey}|]
  request body (scheme <> tokenHeader) jsonResponse s b

getDownloadToken (planId :: Int) =
  proxyListDownloadToken . responseBody <$> requestWebshare NoReqBody query GET url
  where
    url = base /: "v3" /: "proxy" /: "config"
    query = "plan_id" =: planId