module Main where

import Replacer
import Replacer.Env
import Replacer.Config
import Control.Monad.Reader
import Control.Retry

main =
    runReaderT replaceBlockedWebshareProxies
      . (flip Env retryPolicy)
      =<< loadConfig
  where
    retryPolicy = fullJitterBackoff 1 <> limitRetries 10