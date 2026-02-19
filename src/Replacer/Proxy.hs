module Replacer.Proxy where

import Data.String.Interpolate
import Data.ByteString
import Data.Hashable
import GHC.Generics
import qualified Data.ByteString.Char8 as ByteString

data Proxy = Proxy
  { host :: ByteString
  , port :: Int
  , user :: ByteString
  , password :: ByteString
  } deriving (Show, Eq, Ord, Generic, Hashable)

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