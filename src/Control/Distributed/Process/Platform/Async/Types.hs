{-# LANGUAGE DeriveDataTypeable        #-}
{-# LANGUAGE TemplateHaskell           #-}
{-# LANGUAGE StandaloneDeriving        #-}
{-# LANGUAGE RankNTypes                #-}
{-# LANGUAGE ExistentialQuantification #-}

-- | shared, internal types for the Async package
module Control.Distributed.Process.Platform.Async.Types
 ( -- * Exported types
    Async(..)
  , AsyncRef
  , AsyncTask(..)
  , AsyncResult(..)
  ) where

import Control.Distributed.Process
import Control.Distributed.Process.Platform.Time
import Control.Distributed.Process.Serializable (Serializable, SerializableDict)
import Data.Binary
import Data.DeriveTH
import Data.Typeable (Typeable)

data Async a = Async {
    h_poll :: Process (AsyncResult a)
  , h_check :: Process (Maybe (AsyncResult a))
  , h_wait :: Process (AsyncResult a)
  , h_waitCheckTimeout :: TimeInterval -> Process (AsyncResult a)
  , h_waitTimeout :: TimeInterval -> Process (Maybe (AsyncResult a))
  , h_cancel :: Process ()
  , h_cancelWait :: Process (AsyncResult a)
  , h_cancelWith :: (Serializable b) => b -> Process ()
  , h_cancelKill :: String -> Process ()
  , asyncWorker :: ProcessId
  }

-- | A reference to an asynchronous action
type AsyncRef = ProcessId

-- | A task to be performed asynchronously.
data AsyncTask a =
    AsyncTask {
        asyncTask :: Process a -- ^ the task to be performed
      }
  | AsyncRemoteTask {
        asyncTaskDict :: Static (SerializableDict a)
          -- ^ the serializable dict required to spawn a remote process
      , asyncTaskNode :: NodeId
          -- ^ the node on which to spawn the asynchronous task
      , asyncTaskProc :: Closure (Process a)
          -- ^ the task to be performed, wrapped in a closure environment
      }

-- | Represents the result of an asynchronous action, which can be in one of
-- several states at any given time.
data AsyncResult a =
    AsyncDone a                 -- ^ a completed action and its result
  | AsyncFailed DiedReason      -- ^ a failed action and the failure reason
  | AsyncLinkFailed DiedReason  -- ^ a link failure and the reason
  | AsyncCancelled              -- ^ a cancelled action
  | AsyncPending                -- ^ a pending action (that is still running)
    deriving (Typeable)
$(derive makeBinary ''AsyncResult)

deriving instance Eq a => Eq (AsyncResult a)
deriving instance Show a => Show (AsyncResult a)
