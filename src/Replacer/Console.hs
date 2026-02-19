module Replacer.Console (
  info,
  color,
  highlight,
  pluralPostfix,
  pluralProxy,
  Color (..)
) where

import qualified Data.Text as Text
import qualified Data.Text.IO as IO
import qualified System.Console.Pretty as Pretty
import Control.Monad.IO.Class
import Data.Text (Text)
import System.Console.Pretty (Color (..))

color = Pretty.color @Text

highlight c = color c . Text.show

info text = liftIO $ IO.putStrLn text
pluralPostfix count
  | count == 1 = mempty @Text
  | otherwise = "s"

pluralProxy count
  | count == 1 = "proxy" :: Text
  | otherwise = "proxies"