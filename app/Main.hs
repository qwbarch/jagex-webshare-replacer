module Main where

import qualified Data.Text as Text
import Control.Monad.Reader
import Control.Retry
import Replacer
import Replacer.Env
import Replacer.Config
import Replacer.Console
import UnliftIO
import UnliftIO.Process (callCommand)

main = 
  handle @_ @SomeException (info . color Red . Text.pack . displayException) run
    >> callCommand "pause" -- Only works on Windows. Fine for now since I'm only building .exe anyways.
  where
    run = do
      let retryPolicy = fullJitterBackoff 1 <> limitRetries 10
      config <- loadConfig
      runReaderT replaceBlockedWebshareProxies (Env config retryPolicy)