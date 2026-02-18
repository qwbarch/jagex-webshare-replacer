module Replacer.Progress where

import Control.Monad.IO.Class
import Data.String.Interpolate
import Replacer.Console
import System.ProgressBar

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
              , remainingTime renderDuration mempty
              , msg "s"
              ]
        }

-- | Update a single tick of the progress bar.
updateProgressBar = flip incProgress 1