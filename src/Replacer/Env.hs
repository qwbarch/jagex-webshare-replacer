module Replacer.Env where

import Data.ByteString

newtype Env = Env
  { apiKey :: ByteString
  }