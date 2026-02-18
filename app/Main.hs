module Main where

import Replacer.Env
import Replacer.Console
import Replacer.Config
import Replacer.API.Webshare
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
    for config.planIds $ \(planId :: Int) -> do
      proxies <- getProxies planId
      liftIO $ print proxies