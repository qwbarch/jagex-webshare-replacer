module Replacer.Env where

import Replacer.Config

newtype Env = Env
  { config :: Config
  }