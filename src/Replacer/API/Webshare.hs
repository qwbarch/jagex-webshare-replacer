module Replacer.API.Webshare where

import qualified Data.ByteString.Char8 as ByteString
import qualified Data.Text as Text
import Control.Monad.Reader
import Data.Text
import Data.String.Interpolate
import Data.Aeson
import Data.Aeson.TH
import Data.Maybe
import Data.Text.Encoding
import Network.HTTP.Req
import Replacer.Env
import Replacer.Config
import Replacer.Request
import Replacer.Proxy
import qualified Data.HashSet as HashSet

base = https "proxy.webshare.io" /: "api"

newtype DownloadTokenResponse = DownloadTokenResponse
  { proxyListDownloadToken:: Text }
  deriving Show

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''DownloadTokenResponse

newtype ReplacementId = ReplacementId Int
  deriving newtype Show

deriveJSON defaultOptions ''ReplacementId

newtype CreateReplacementResponse = CreateReplacementResponse
  { id :: ReplacementId }
  deriving Show

deriveJSON defaultOptions ''CreateReplacementResponse

data GetReplacementResponse = GetReplacementResponse
  { state :: Text
  , proxiesAdded :: Maybe Int
  , error :: Maybe Text
  , errorCode :: Maybe Text
  } deriving Show

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''GetReplacementResponse

data GetPlanDetailsResponse = GetPlanDetailsResponse
  { id :: Int
  , status :: Text
  , proxyType :: Text
  , proxyCount :: Int
  , proxyReplacementsTotal :: Int
  , proxyReplacementsUsed :: Int
  , proxyReplacementsAvailable :: Int
  }

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''GetPlanDetailsResponse

requestWebshare body scheme response method url = do
  env <- ask
  let tokenHeader = header "Authorization" [i|Token #{apiKey $ config env}|]
  request body (scheme <> tokenHeader) response method url

getDownloadToken planId =
  proxyListDownloadToken <$> requestWebshare NoReqBody query jsonResponse GET url
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
          /: "direct"
          /: "-"
      query = "plan_id" =: (planId :: Int)
      parseProxies = do
          HashSet.fromList
            . catMaybes
            . fmap parseProxy
            . ByteString.split '\n'
            . ByteString.filter (/= '\r')
  parseProxies <$> requestWebshare NoReqBody query bsResponse GET url

createReplacement planId proxies = do
  env <- ask
  let url = base /: "v3" /: "proxy" /: "replace"
      query = "plan_id" =: (planId :: Int)
      requestBody =
        object
          [ "to_replace" .= object
              [ "type" .= ("ip_address" :: String)
              , "ip_addresses" .= (HashSet.map (decodeUtf8 . host) proxies)
              ]
          , "replace_with" .= env.config.replaceWith
          , "dry_run" .= False
          ]
  response :: CreateReplacementResponse <-
    requestWebshare (ReqBodyJson requestBody) query jsonResponse POST url
  pure $ response.id

getReplacement planId replacementId =
  requestWebshare NoReqBody query (jsonResponse @GetReplacementResponse) GET url
  where
    url = base /: "v3" /: "proxy" /: "replace" /: Text.show replacementId
    query = "plan_id" =: (planId :: Int)

getPlanDetails planId = requestWebshare NoReqBody mempty (jsonResponse @GetPlanDetailsResponse) GET url
  where
    url = base /: "v2" /: "subscription" /: "plan" /: Text.show planId