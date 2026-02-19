module Replacer where

import qualified Data.Vector as Vector
import Replacer.Console
import Replacer.Config
import Replacer.Worker
import Replacer.Env
import Replacer.API.Jagex
import Replacer.API.Webshare
import Control.Monad.IO.Class
import Control.Monad.Reader
import Data.String.Interpolate
import UnliftIO
import Data.Foldable.Extra
import qualified Data.HashSet as HashSet
import Data.Text (Text)
import Replacer.Progress
import UnliftIO.Concurrent
import Data.Vector.Internal.Check (HasCallStack)
import Data.Bifunctor
import Data.Maybe
import Control.Monad.Extra

data ReplaceError = ReplaceError Text
  deriving (Show, Typeable)

instance Exception ReplaceError

replaceBlockedWebshareProxies :: (HasCallStack, MonadReader Env m) => MonadUnliftIO m => MonadIO m => m ()
replaceBlockedWebshareProxies =
  fetchPlanIds
    >>= traverse_ (replaceBlockedProxies mempty)
    >> info (color Green "Finished replacing all blocked proxies.")
  where
    -- These conversions don't look great, but:
    -- • HashSet does not have a traversable instance (needed for runWorkers)
    -- • Vector does not have set functions such as difference, union, etc.
    -- • No direct conversions between the two types.
    toSet = HashSet.fromList . Vector.toList
    vectorDifference a b =
      Vector.fromList
        . HashSet.toList
        $ HashSet.difference (toSet a) (toSet b)

    fetchPlanIds = do
      planIds <- asks (.config.planIds)
      let planCount = Vector.length planIds
      info [i|Loaded #{planCount} proxy plan#{pluralPostfix planCount}: #{planIds}\n|]
      return planIds

    replaceBlockedProxies checkedProxies planId = do
      config <- asks (.config)

      info [i|Fetching proxy list for plan #{highlight Yellow planId}|]
      proxies <- getProxies planId
      let proxyCount = Vector.length proxies
      info [i|Found #{highlight Cyan proxyCount} #{pluralProxy proxyCount} in plan #{highlight Yellow planId}|]

      let uncheckedProxies = vectorDifference proxies checkedProxies
          uncheckedCount = Vector.length uncheckedProxies
      
      info[i|Remaining #{highlight Cyan uncheckedCount} #{pluralProxy uncheckedCount} need to be checked.\n|]

      (blockedProxies, unblockedProxies) <-
        fmap (bimap (fmap fst) (fmap fst) . Vector.partition snd)
          . runWorkers isJagexBlocked uncheckedProxies
          $ Just [i|Checking #{pluralProxy proxyCount} for jagex block#{pluralPostfix proxyCount} |]

      let unblockedCount = Vector.length unblockedProxies
          blockedCount = Vector.length blockedProxies

      info [i|Proxies active: #{highlight Green unblockedCount}|]
      info [i|Proxies blocked: #{highlight Red blockedCount}\n|]

      when (blockedCount > 0) $ do
        withProgressBar_ "Attempting to replace blocked proxies" $
          waitUntilReplacementFinished planId =<< createReplacement planId blockedProxies
        
        withProgressBar "Waiting to start next attempt" config.waitSecondsAfterReplacement $ \progressBar ->
          for_ [1 .. config.waitSecondsAfterReplacement] . const $ do
            threadDelay 1_000_000
            tickProgress progressBar
        
        info "\n"
        replaceBlockedProxies (checkedProxies <> unblockedProxies) planId
      
    waitUntilReplacementFinished planId replacementId = do
      replacement <- getReplacement planId replacementId
      let onFinish = do
            let proxiesReplaced = fromMaybe 0 replacement.proxiesAdded
            if proxiesReplaced == 0
              then pure ()
              else
                info [i|\nReplaced #{highlight Cyan $ proxiesAdded replacement} proxies.|]
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