module Replacer.Config where

import qualified Data.ByteString.Lazy as ByteString
import qualified Data.HashSet as HashSet
import Control.Monad
import Control.Monad.Extra
import Data.Aeson
import Data.Aeson.TH
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Aeson.QQ.Simple
import Data.Text (Text)
import Data.Typeable
import Data.HashSet
import System.Directory
import UnliftIO.Exception

configPath = "config.json"

data Config = Config
  { apiKey :: Text
  , planIds :: HashSet Int
  , maxThreads :: Int
  , replaceWith :: Value
  , waitSecondsAfterReplacement :: Int
  }

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''Config

defaultConfig = Config
  { apiKey = "YOUR_API_KEY_HERE"
  , planIds = mempty
  , maxThreads = 1000
  , replaceWith = [aesonQQ|[{"type": "country", "country_code": "US"}]|]
  , waitSecondsAfterReplacement = 15
  }

data ConfigError = ConfigError String
  deriving (Show, Typeable)

instance Exception ConfigError

-- | Loads the json config and creates the file with default values if missing.
loadConfig = do
  -- Warning: This is not atomic, but is good enough for our use-case.
  unlessM (doesFileExist configPath) $
    ByteString.writeFile configPath (encodePretty defaultConfig)

  config <-
    ByteString.readFile configPath
      >>= either (throwIO . ConfigError) pure . eitherDecode @Config
  
  when (config.apiKey == defaultConfig.apiKey) $
    throwIO $ ConfigError "Webshare API key is missing."

  when (HashSet.null config.planIds) $
    throwIO $ ConfigError "Webshare plan ids cannot be empty."

  pure config