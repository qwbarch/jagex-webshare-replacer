module Replacer.Console (printText, color, Color(..), i) where

import qualified System.Console.Pretty as Pretty
import qualified Data.Text.IO as Text
import Control.Monad.IO.Class
import Data.Text
import Data.String.Interpolate
import System.Console.Pretty (Color(..))

printText :: MonadIO m => Text -> m ()
printText = liftIO . Text.putStrLn

color = Pretty.color @Text
