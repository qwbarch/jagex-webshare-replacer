module Main where

import Replacer.Console
import Replacer.Env
import Control.Monad 
import Control.Concurrent 
import System.ProgressBar 
import Data.Foldable 
import System.ProgressBar (Style(stylePostfix))
import Replacer.Config

main = do
  _ <- printText [i|hello world! my name is #{color Yellow "bob"}|]

  config <- loadConfig
  
  pure ()