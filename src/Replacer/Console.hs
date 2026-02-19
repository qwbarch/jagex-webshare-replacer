module Replacer.Console (
  info,
  color,
  highlight,
  pluralPostfix,
  pluralProxy,
  Color (..)
) where

import Control.Monad.IO.Class
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.IO as IO
import System.Console.Pretty (Color (..))
import qualified System.Console.Pretty as Pretty

color = Pretty.color @Text

highlight c = color c . Text.show

info text = liftIO $ IO.putStrLn text
pluralPostfix count
  | count == 1 = mempty @Text
  | otherwise = "s"

pluralProxy count
  | count == 1 = "proxy" :: Text
  | otherwise = "proxies"