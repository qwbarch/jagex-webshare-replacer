module Replacer.API.Jagex where

import qualified Data.ByteString as ByteString
import Network.HTTP.Req
import Replacer.Request
import Network.HTTP.Types (Status(..))
import Network.HTTP.Client 
import UnliftIO
import Network.Connection

isJagexBlocked proxy = handleError =<< try sendRequest
  where
    sendRequest = 
      ByteString.isInfixOf "Sorry, you have been blocked"
        <$> requestWithProxy' modifyConfig proxy NoReqBody headers bsResponse GET url
    handleError = \case
      Left exception@(VanillaHttpException (HttpExceptionRequest _ (InternalException internalException))) ->
        case fromException @HostCannotConnect internalException of
          Just _ -> pure False -- Proxy doesn't work, do nothing and wait for it to come back up.
          Nothing -> throwIO exception
      Left exception -> throwIO exception
      Right result -> pure result
    modifyConfig config =
        config 
          { httpConfigCheckResponse = \_ response _ ->
              let code = statusCode $ responseStatus response
              in -- Don't throw on error 403 since that's the status code for when we get blocked.
                if code /= 403 && code >= 400
                  then Just $ StatusCodeException (response { responseBody = () }) mempty
                  else Nothing
          }
    url = https "account.jagex.com"
    headers =
      mconcat
        [ header "User-Agent" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0"
        , header "Sec-Fetch-Dest" "document"
        , header "Sec-Fetch-Mode" "navigate"
        , header "Sec-Fetch-Site" "same-origin"
        ]