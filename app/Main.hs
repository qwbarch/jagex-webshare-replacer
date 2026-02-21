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

main = handle @_ @SomeException onError runMain >> waitToExit
  where
    retryPolicy = fullJitterBackoff 1 <> limitRetries 10
    onError = info . color Red . Text.pack . displayException
    runMain = runReaderT replaceBlockedWebshareProxies . fromConfig retryPolicy =<< loadConfig
    waitToExit = do
      info "\nPress any key to exit..."
      void . runInputT defaultSettings $ waitForAnyKey mempty