module Replacer.API.Ipify where

import Replacer.Request
import Data.Text
import Data.Aeson.TH
import Network.HTTP.Req
import Control.Monad.IO.Class
import Replacer.Proxy

newtype IpAddressResponse = IpAddressResponse
  { ip :: IpAddress
  }

deriveJSON defaultOptions ''IpAddressResponse

getIpAddress :: MonadIO m => Proxy -> m IpAddress
getIpAddress proxy = ip <$> requestWithProxy proxy NoReqBody query jsonResponse GET url
  where
    url = https "api.ipify.org"
    query = "format" =: ("json" :: Text)