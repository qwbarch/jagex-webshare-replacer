module Replacer where

import qualified Data.Text as Text
import qualified Data.Vector as Vector
import Replacer.Console
import Replacer.Config
import Replacer.Worker
import Replacer.Env
import Replacer.API.Ipify
import Replacer.API.Jagex
import Replacer.API.Webshare
import Control.Monad.IO.Class
import Control.Monad.Reader
import Control.Concurrent
import Data.String.Interpolate
import UnliftIO

replaceBlockedProxies :: MonadReader Env m => MonadUnliftIO m => MonadIO m => m ()
replaceBlockedProxies = do
  env <- ask
  let highlight = color Yellow . Text.show
      planIds = env.config.planIds
  --info [i|Loaded #{highlight $ Vector.length planIds} proxy plans.|]
  info [i|Loaded #{Vector.length planIds} proxy plans.|]

  Vector.forM_ planIds $ \planId -> do
    info [i|\nProcessing proxies in proxy plan #{planId}.|]

    proxies <- getProxies planId
    info [i|Found #{highlight $ Vector.length proxies} proxies.|]

    -- runWorkers (Just "") (Vector.replicate 1000 5) $ \_ -> do
    --   liftIO $ threadDelay 500000

  --proxies <- getProxies 0
  --let proxyCount :: Int = Vector.length proxies
      --ps = Text.show proxyCount
