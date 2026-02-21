module Replacer.Env where

import Control.Retry
import Data.Text
import Data.Aeson
import Data.Maybe

data Env = Env
  { apiKey :: Text
  , datacenterPlanId :: Maybe Int
  , staticPlanId :: Maybe Int
  , maxThreads :: Int
  , replaceProxyIfNotConnected :: Bool
  , replaceWith :: Value
  , waitSecondsAfterReplacement :: Int
  , retryPolicy :: RetryPolicyM IO
  }

fromConfig retryPolicy config =
    Env
      { apiKey = fromJust config.apiKey
      , datacenterPlanId = config.datacenterPlanId
      , staticPlanId = config.staticPlanId
      , maxThreads = fromJust config.maxThreads
      , replaceProxyIfNotConnected = fromJust config.replaceProxyIfNotConnected
      , replaceWith = fromJust config.replaceWith
      , waitSecondsAfterReplacement = fromJust config.waitSecondsAfterReplacement
      , retryPolicy = retryPolicy
      }