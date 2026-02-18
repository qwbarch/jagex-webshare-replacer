module Replacer.Proxy where

import Control.Monad.IO.Class
import Data.Aeson.TH
import Data.Text
import Data.String.Interpolate
import Data.ByteString
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

newtype IpAddress = IpAddress Text
  deriving newtype Show

deriveJSON defaultOptions ''IpAddress

data ProxyWithAddress = ProxyWithAddress
    { proxy :: Proxy
    , address :: IpAddress
    }