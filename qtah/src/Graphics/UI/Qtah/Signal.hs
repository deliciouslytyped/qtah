-- This file is part of Qtah.
--
-- Copyright 2015-2019 The Qtah Authors.
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

{-# LANGUAGE FlexibleContexts #-}

-- | General routines for managing Qt signals.
module Graphics.UI.Qtah.Signal (
  Signal (..),
  connect_,
  disconnect_,
  ) where

import Control.Monad (unless)
import Graphics.UI.Qtah.Core.Connection (Connection)

-- może stworzyć nową klasę na class z modułu hoppy. Metoda wewnątrz musiałaby mieć jako pierwszy parametr podstawienie (np. a)

-- instance signalClass (Signal object handler) where
--  metaConn signal = internalDisconnectSignal

-- | A signal that can be connected to an instance of the @object@ (C++) class,
-- and when invoked will call a function of the given @handler@ type.



data Signal object handler = Signal
  { internalConnectSignal :: object -> handler -> IO Connection
  , internalDisconnectSignal :: Connection -> IO Bool
  , internalName :: String
  }

 -- (ConnectionPtr object) => QtahSignal.Signal object (M50.QModelIndex -> HoppyP.IO ())
instance Show (Signal object handler) where
  show signal = concat ["<Signal ", internalName signal, ">"]

--instance Connection (Signal object handler) where
--  show signal = concat ["<Signal ", internalName signal, ">"]

-- | Registers a handler function to listen to a signal an object emits.
-- Returns true if the connection succeeded.
--connect :: object -> Signal object handler -> handler -> IO Connection
--connect = flip internalConnectSignal

-- | Registers a handler function to listen to a signal an object emits, via
-- 'connect'.  If the connection fails, then the program aborts.
connect_ :: object -> Signal object handler -> handler -> IO Connection
connect_ object signal handler = internalConnectSignal signal object handler

-- | Registers a handler function to listen to a signal an object emits, via
-- 'connect'.  If the connection fails, then the program aborts.
disconnect_ :: Connection -> Signal object handler -> object -> handler -> IO Bool
disconnect_ connection signal object handler = internalDisconnectSignal signal connection 
