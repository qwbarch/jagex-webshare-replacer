module Replacer.Env where

import Replacer.Config
import Control.Retry

data Env = Env
  { config :: Config
  , retryPolicy :: RetryPolicyM IO
  }