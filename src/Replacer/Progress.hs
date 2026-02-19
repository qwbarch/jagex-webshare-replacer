module Replacer.Progress where

import Control.Monad.IO.Class
import Data.String.Interpolate
import Replacer.Console
import System.ProgressBar
import UnliftIO

createProgressBar label max =
  liftIO $ newProgressBar style 15 $ Progress 0 max ()
  where
    style =
      defStyle
        { stylePrefix =
            mconcat
              [ msg [i|#{color Cyan label} |]
              , percentage
              ]
        , stylePostfix =
            mconcat
              [ exact
              , msg " Elapsed: "
              , elapsedTime renderDuration
              , msg "s Remaining: "
              , remainingTime renderDuration "?"
              , msg "s"
              ]
        }

-- | Creates a progress bar with a size of 1 that automatically ticks when finished.
-- | Warning: Don't call tickProgress or finishProgress yourself or the console can bug out.
-- | While ideally it'd be better to have this type-checked, I don't really care enough to do it.
withProgressBar_ label run =
  bracket (createProgressBar label 1) finishProgress (const run)

withProgressBar label max run = bracket (createProgressBar label max) (const $ pure ()) run

-- | Update a single tick of the progress bar.
tickProgress progress = liftIO $ incProgress progress 1

finishProgress progressBar =
  liftIO $
    updateProgress progressBar $ \progress ->
      progress { progressDone = progress.progressTodo }