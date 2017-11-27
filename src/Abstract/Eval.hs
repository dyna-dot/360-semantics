{-# LANGUAGE AllowAmbiguousTypes, FlexibleContexts, DefaultSignatures, FlexibleInstances, MultiParamTypeClasses, ScopedTypeVariables, TypeApplications, TypeOperators, UndecidableInstances #-}
module Abstract.Eval where

import Abstract.Store
import Data.Proxy
import Data.Term
import Data.Union

import Control.Monad.Effect
import Control.Monad.Effect.Reader
import Data.Semigroup


-- Collecting evaluator
class Monad m => Eval l v m syntax ann constr where
  eval :: (Term syntax ann -> m v) -> constr (Term syntax ann) -> m v

  default eval :: (Term syntax ann -> m v) -> constr (Term syntax ann) -> m v
  eval = fail "default eval"

instance (Monad m, Apply (Eval l v m s a) fs) => Eval l v m s a (Union fs) where
  eval ev = apply (Proxy :: Proxy (Eval l v m s a)) (eval @l ev)

instance (Monad m, Eval l v m s a s) => Eval l v m s a (TermF s a) where
  eval ev In{..} = eval @l ev termOut


class Monad m => MonadGC l a m where
  askRoots :: m (Set (Address l a))

  extraRoots :: Set (Address l a) -> m b -> m b

instance (Ord l, Reader (Set (Address l a)) :< fs) => MonadGC l a (Eff fs) where
  askRoots = ask :: Eff fs (Set (Address l a))

  extraRoots roots' = local (<> roots')
