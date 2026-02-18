module Replacer.Progress where

import Replacer.Console
import Control.Monad.IO.Class
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

updateProgressBar = flip incProgress 1