module Replacer where

import Replacer.Console
import Replacer.Worker
import Replacer.Env
import Control.Monad.IO.Class
import Control.Monad.Reader
import Control.Concurrent
import UnliftIO
import qualified Data.Vector as Vector

replaceBlockedProxies :: MonadReader Env m => MonadUnliftIO m => m ()
replaceBlockedProxies = do
  env <- ask
  runWorkers (Just "hello") (Vector.replicate 1000 5) $ \_ -> do
    liftIO $ threadDelay 500000