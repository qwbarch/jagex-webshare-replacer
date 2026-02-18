module Replacer.Worker where

import qualified Data.Vector as Vector
import Control.Monad.Reader
import Data.Maybe
import UnliftIO
import Replacer.Env
import Replacer.Config
import Replacer.Progress

-- | Run the given effect for each param.
-- | If given a progress label, will also display a progress bar.
runWorkers Nothing params runParam = do
  env :: Env <- ask
  pooledMapConcurrentlyN_ env.config.maxThreads runParam params
runWorkers (Just progressLabel) params runParam = do
  progressBar <- createProgressBar progressLabel $ Vector.length params
  let trackProgress param = do
        runParam param
        liftIO $ updateProgressBar progressBar
  runWorkers Nothing params trackProgress