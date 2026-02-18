module Main where

import Replacer
import Replacer.Env
import Replacer.Config
import Control.Monad.Reader

main = do
  config <- loadConfig

  flip runReaderT (Env config) $
    replaceBlockedProxies