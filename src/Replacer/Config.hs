module Replacer.Config where

import qualified Data.Text as Text
import qualified Data.ByteString.Lazy as ByteString
import Control.Monad.Extra
import Control.Monad.IO.Class
import Control.Monad.Trans.Maybe
import Data.Aeson
import Data.Aeson.TH
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Text (Text)
import Data.Typeable
import Data.Functor
import Data.Foldable
import System.Directory
import System.Console.Haskeline
import Replacer.Console
import Text.Read
import UnliftIO.Exception
import Data.Char (toLower)
import Data.Default
import GHC.Generics
import Data.Maybe
import Optics

configPath = "config.json"

data Config = Config
  { apiKey :: Maybe Text
  , datacenterPlanId :: Maybe Int
  , staticPlanId :: Maybe Int
  , maxThreads :: Maybe Int
  , replaceProxyIfNotConnected :: Maybe Bool
  , replaceWith :: Maybe Value
  , waitSecondsAfterReplacement :: Maybe Int
  } deriving (Generic, Default)

deriveJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' }) ''Config

data ConfigError = ConfigError String
  deriving (Show, Typeable)

instance Exception ConfigError

loadConfig = runInputT @IO defaultSettings $ do
  let writeConfig config =
        liftIO
          $ ByteString.writeFile configPath (encodePretty config)
          $> config
      readConfig =
        liftIO
          $ ByteString.readFile configPath
          >>= either (throwIO . ConfigError) pure . eitherDecode @Config
      updateConfig field value = do
          config <- readConfig
          _ <- writeConfig $ config & field .~ value
          pure ()
      promptApiKey =
        Text.pack . fold <$> getPassword (Just '*') "Webshare API key: " >>= \case
          "" -> promptApiKey
          key -> pure key
      promptPlanId message = runMaybeT $ do
          input <- MaybeT $ getInputLine message
          guard . not $ null input
          maybe (MaybeT $ promptPlanId message) pure $ readMaybe input
      promptYesNo message =
          fmap toLower . fold <$> getInputLine message >>= \case
            "y" -> pure True
            "yes" -> pure True
            "" -> pure False -- Default value.
            "n" -> pure False
            "no" -> pure False
            _ -> promptYesNo message
      promptProxyPlan = do
        config <- readConfig
        when (isNothing config.staticPlanId && isNothing config.datacenterPlanId) $ do
          updateConfig #staticPlanId =<< promptPlanId "Static residential plan id (leave empty to skip): "
          updateConfig #datacenterPlanId =<< promptPlanId "Proxy server plan id (leave empty to skip): "
          promptProxyPlan
      defaultReplaceWith (countryCode :: String) =
        Just $
          toJSON @[Value]
            [ object
                [ "type" .= ("country" :: Text)
                , "country_code" .= (if null countryCode then "US" else countryCode)
                ]
            ]
      parseCountryCode = \case
        "" -> defaultReplaceWith "US"
        code -> defaultReplaceWith code

  config <-
    ifM
      (liftIO $ doesFileExist configPath)
      readConfig
      (writeConfig def)

  when (isNothing config.maxThreads) $
    updateConfig #maxThreads $ Just 1000

  when (isNothing config.waitSecondsAfterReplacement) $
    updateConfig #waitSecondsAfterReplacement $ Just 15
  
  when (isNothing config.apiKey) $ do
    updateConfig #apiKey . Just =<< promptApiKey

  promptProxyPlan

  when (isNothing config.replaceWith) $ do
    useRandomCountry <- promptYesNo "Replace proxy with a random country's? [y/N]"
    if useRandomCountry
      then
        updateConfig
          #replaceWith
          . Just
          $ object ["type" .= ("any" :: Text)]
      else 
        updateConfig #replaceWith
          . parseCountryCode
          . fold
          =<< getInputLine "Replacement country code [US]: "

  when (isNothing config.replaceProxyIfNotConnected) $
    updateConfig #replaceProxyIfNotConnected . Just =<< promptYesNo "Replace proxy if connection fails? [y/N]: "
      
  info mempty
  readConfig