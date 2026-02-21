module Main where

import qualified Data.Text as Text
import Control.Monad.Reader
import Control.Retry
import Data.Functor
import Replacer
import Replacer.Env
import Replacer.Config
import Replacer.Console
import UnliftIO
import System.Console.Haskeline 

main = do
  let retryPolicy = fullJitterBackoff 1 <> limitRetries 10
      onError = info . color Red . Text.pack . displayException
      runMain = do
        config <- loadConfig
        runReaderT replaceBlockedWebshareProxies (Env config retryPolicy)
  handle @_ @SomeException onError runMain
  info "\nPress any key to exit..."
  void . runInputT defaultSettings $ waitForAnyKey mempty