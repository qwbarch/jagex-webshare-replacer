module Replacer.Worker where

import qualified Data.Vector as Vector
import Control.Monad.Reader
import UnliftIO
import Replacer.Progress

-- | Run the given effect for each param.
-- | If given a progress label, will also display a progress bar.
runWorkers runParam params = \case
  Nothing -> pooledMap runParam
  Just label ->
    withProgressBar label (Vector.length params) $ \progressBar ->
      pooledMap $ \param -> do
        result <- runParam param
        tickProgress progressBar
        pure result
  where
    pooledMap run = do
        env <- ask
        results <- pooledMapConcurrentlyN env.config.maxThreads run params
        pure $ Vector.zip params results
