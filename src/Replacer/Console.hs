module Replacer.Console (info, color, Color (..)) where

import Control.Monad.IO.Class
import Data.Text (Text)
import qualified Data.Text.IO as Text
import System.Console.Pretty (Color (..))
import qualified System.Console.Pretty as Pretty

color = Pretty.color @Text

info text = liftIO $ Text.putStrLn text