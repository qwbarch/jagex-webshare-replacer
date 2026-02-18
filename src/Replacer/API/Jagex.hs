module Replacer.API.Jagex where

import qualified Data.ByteString as ByteString
import Network.HTTP.Req
import Replacer.Request

isJagexBlocked proxy =
  ByteString.isInfixOf "Sorry, you have been blocked"
    <$> requestWithProxy proxy NoReqBody headers bsResponse GET url
  where
    url = https "account.jagex.com"
    headers =
      mconcat
        [ header "User-Agent" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0"
        , header "Sec-Fetch-Dest" "document"
        , header "Sec-Fetch-Mode" "navigate"
        , header "Sec-Fetch-Site" "same-origin"
        ]