module Replacer.Proxy where

import Data.Aeson.TH
import Data.Text
import Data.String.Interpolate
import Data.ByteString
import qualified Data.ByteString.Char8 as ByteString

data Proxy = Proxy
  { host :: ByteString
  , port :: Int
  , user :: ByteString
  , password :: ByteString
  } deriving Show

-- | Parse a proxy string of the format:
-- | HOST:PORT:USER:PASS
parseProxy input =
  case ByteString.split ':' input of
    [host, port, user, password] ->
      case ByteString.readInt port of
        Just (port', "") -> Just $ Proxy host port' user password
        _                  -> Nothing
    _ -> Nothing

-- | Format the proxy into a string of the format:
-- | HOST:PORT:USER:PASS
formatProxy (Proxy host port user password) =
  [i|#{host}:#{port}:#{user}:#{password}|]

newtype IpAddress = IpAddress Text
  deriving newtype Show

deriveJSON defaultOptions ''IpAddress

data ProxyWithAddress = ProxyWithAddress
    { proxy :: Proxy
    , address :: IpAddress
    }