module Replacer where

import qualified Data.HashSet as HashSet
import Control.Monad.Extra
import Control.Monad.IO.Class
import Control.Monad.Reader
import Data.Bifunctor
import Data.Maybe
import Data.Vector.Internal.Check
import Data.Foldable.Extra
import Data.Text
import Data.String.Interpolate
import Replacer.Console
import Replacer.Worker
import Replacer.Env
import Replacer.API.Jagex
import Replacer.API.Webshare
import Replacer.Progress
import UnliftIO
import UnliftIO.Concurrent
import qualified Data.Vector as Vector

data ReplaceError = ReplaceError Text
  deriving (Show, Typeable)

instance Exception ReplaceError

replaceBlockedWebshareProxies :: (HasCallStack, MonadReader Env m) => MonadUnliftIO m => MonadIO m => m ()
replaceBlockedWebshareProxies = run
  where
    run = do
      env <- ask
      traverse_ (replaceBlockedProxies mempty "Proxy Server") env.datacenterPlanId 
      traverse_ (replaceBlockedProxies mempty "Static residential") env.staticPlanId
      info $ color Green "Finished replacing all blocked proxies."

    replaceBlockedProxies checkedProxies (planName :: Text) planId = do
      env <- ask

      info [i|Fetching proxies for #{color Yellow planName} plan.|]
      proxies <- getProxies planId
      let proxyCount = HashSet.size proxies
      info [i|Found #{highlight Cyan proxyCount} #{pluralProxy proxyCount} for #{color Yellow planName} plan.|]

      let uncheckedProxies = Vector.fromList . toList $ HashSet.difference proxies checkedProxies
          uncheckedCount = Vector.length uncheckedProxies
      
      info[i|Remaining #{highlight Cyan uncheckedCount} #{pluralProxy uncheckedCount} need to be checked.\n|]

      let toHashSet = HashSet.fromList . Vector.toList . fmap fst
      (blockedProxies, unblockedProxies) <-
        fmap (bimap toHashSet toHashSet . Vector.partition snd)
          . runWorkers isJagexBlocked uncheckedProxies
          $ Just [i|Checking #{pluralProxy proxyCount} for jagex block#{pluralPostfix proxyCount} |]

      let unblockedCount = HashSet.size unblockedProxies + HashSet.size checkedProxies
          blockedCount = HashSet.size blockedProxies

      info [i|Proxies active: #{highlight Green unblockedCount}|]
      info [i|Proxies blocked: #{highlight Red blockedCount}|]

      planDetails <- getPlanDetails planId
      let replacementsAvailable = proxyReplacementsAvailable planDetails
      info [i|#{planName} has #{highlight Yellow replacementsAvailable} replacements remaining.\n|]

      when (blockedCount > 0 && replacementsAvailable > 0) $ do
        withProgressBar_ "Attempting to replace blocked proxies" $
          waitUntilReplacementFinished planId =<< createReplacement planId blockedProxies
        
        withProgressBar "Waiting to start next attempt" env.waitSecondsAfterReplacement $ \progressBar ->
          for_ [1 .. env.waitSecondsAfterReplacement] . const $ do
            threadDelay 1_000_000
            tickProgress progressBar
        
        info mempty
        replaceBlockedProxies (checkedProxies <> unblockedProxies) planName planId
      
    waitUntilReplacementFinished planId replacementId = do
      replacement <- getReplacement planId replacementId
      let proxiesReplaced = fromMaybe 0 replacement.proxiesAdded
          onFinish = info [i|\nReplaced #{highlight Cyan proxiesReplaced} proxies.|]
          wait = threadDelay 200_000
      case replacement.state of
        "completed" -> onFinish
        "validated" -> onFinish
        "processing" -> wait
        "validating" -> wait
        "failed" ->
          case replacement.errorCode of
            Just "no_proxies_to_be_replaced" ->
              info . highlight Yellow $ "No proxies were replaced."
            Just _ ->
              throwIO $ ReplaceError [i|Failed to replace proxies: #{errorCode replacement}|]
            Nothing ->
              throwIO
                . ReplaceError
                $ [i|Something unexpected occurred.\nReplacement response: #{replacement}|]
        state -> throwIO $ ReplaceError [i|Unexpected state while fetching replacement: #{state}|]