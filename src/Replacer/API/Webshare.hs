module Replacer.API.Webshare where

import Control.Monad.Reader
import Data.Text
import Data.String.Interpolate
import Data.Aeson
import Data.Aeson.TH
import Network.HTTP.Req
import Replacer.Env
import Replacer.Config
import Replacer.Request
import qualified Data.ByteString.Char8 as ByteString

base = https "proxy.webshare.io" /: "api"

newtype DownloadTokenResponse = DownloadTokenResponse
  { proxyListDownloadToken:: Text }
  deriving Show

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''DownloadTokenResponse

requestWebshare body scheme response method url = do
  apiKey <- asks (.config.apiKey)
  let tokenHeader = header "Authorization" [i|Token #{apiKey}|]
  request body (scheme <> tokenHeader) response method url

getDownloadToken planId =
  proxyListDownloadToken . responseBody
    <$> requestWebshare NoReqBody query jsonResponse GET url
  where
    url = base /: "v3" /: "proxy" /: "config"
    query = "plan_id" =: (planId :: Int)

getProxies planId = do
  token <- getDownloadToken planId
  let url =
        base
          /: "v2"
          /: "proxy"
          /: "list"
          /: "download"
          /: token
          /: "-"
          /: "any"
          /: "username"
          /: "backbone"
          /: "-"
      query = "plan_id" =: (planId :: Int)
      parseProxies = do
          fmap parseProxy
            . ByteString.split '\n'
            . ByteString.filter (/= '\r')
  parseProxies . responseBody <$> requestWebshare NoReqBody query bsResponse GET url