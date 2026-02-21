module Replacer.Config where

import qualified Data.Text as Text
import qualified Data.ByteString.Lazy as ByteString
import Control.Monad.Extra
import Control.Monad.IO.Class
import Control.Monad.Trans.Maybe
import Control.Applicative
import Data.Aeson
import Data.Aeson.TH
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Aeson.QQ.Simple
import Data.Text (Text)
import Data.Typeable
import Data.Functor
import Data.Foldable
import System.Directory
import System.Console.Haskeline
import Replacer.Console
import Text.Read
import UnliftIO.Exception

configPath = "config.json"

data Config = Config
  { apiKey :: Text
  , datacenterPlanId :: Maybe Int
  , staticPlanId :: Maybe Int
  , maxThreads :: Int
  , replaceWith :: Value
  , waitSecondsAfterReplacement :: Int
  }

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''Config

defaultConfig = Config
  { apiKey = "YOUR_API_KEY_HERE"
  , datacenterPlanId = Nothing
  , staticPlanId = Nothing
  , maxThreads = 1000
  , replaceWith = [aesonQQ|[{"type": "country", "country_code": "US"}]|]
  , waitSecondsAfterReplacement = 15
  }

data ConfigError = ConfigError String
  deriving (Show, Typeable)

instance Exception ConfigError

-- | Loads the json config and creates the file with default values if missing.
loadConfig = runInputT defaultSettings $ do
  ifM (liftIO $ doesFileExist configPath)
    (readConfig)
    (writeConfig =<< promptConfig)
  where
    writeConfig config =
      liftIO 
        $ ByteString.writeFile configPath (encodePretty config)
        $> config
    readConfig =
      liftIO
        $ ByteString.readFile configPath
        >>= either (throwIO . ConfigError) pure . eitherDecode @Config

promptConfig = do
  let promptApiKey =
        Text.pack . fold <$> getPassword (Just '*') "Enter Webshare API key: " >>= \case
          "" -> promptApiKey
          key -> pure key
      promptPlanId message = runMaybeT $ do
          input <- MaybeT $ getInputLine message
          if null input
            then empty
            else maybe (MaybeT $ promptPlanId message) pure $ readMaybe input
  apiKey <- promptApiKey
  staticPlanId <- promptPlanId "Enter static residential plan id (leave empty if none): "
  datacenterPlanId <- promptPlanId "Enter proxy server plan id (leave empty if none): "
  countryCode <- fold <$> getInputLine "Enter replacement country code (default: US): "
  info mempty
  pure @(InputT IO) Config
    { apiKey = apiKey
    , datacenterPlanId = datacenterPlanId
    , staticPlanId = staticPlanId
    , maxThreads = 1000
    , replaceWith = 
        toJSON
          [ object
              [ "type" .= ("country" :: Text)
              , "country_code" .= (if null countryCode then "US" else countryCode)
              ]
          ]
    , waitSecondsAfterReplacement = 15
    }