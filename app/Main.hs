module Main where

import Replacer
import Replacer.Env
import Replacer.Console
import Replacer.Config
import Replacer.API.Webshare
import Replacer.API.Ipify
import Control.Monad 
import Control.Monad.Reader
import Control.Monad.IO.Class
import Control.Concurrent 
import Data.Foldable 
import Data.Traversable
import System.ProgressBar 

main = do
  _ <- printText [i|hello world! my name is #{color Yellow "bob"}|]

  config <- loadConfig

  flip runReaderT (Env config) $
    replaceBlockedProxies