-- This file is part of Qtah.
--
-- Copyright 2016 Bryan Gardiner <bog@khumba.net>
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

module Graphics.UI.Qtah.Internal.Interface.Gui.QInputEvent (
  aModule,
  c_QInputEvent,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Type (TBitspace, TULong),
  addReqIncludes,
  ident,
  includeStd,
  makeClass,
  mkConstMethod,
  )
import Foreign.Hoppy.Generator.Version (collect, just, test)
import Graphics.UI.Qtah.Internal.Flags (qtVersion)
import Graphics.UI.Qtah.Internal.Generator.Types
import Graphics.UI.Qtah.Internal.Interface.Core.QEvent (c_QEvent)
import Graphics.UI.Qtah.Internal.Interface.Core.Types (bs_KeyboardModifiers)

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModule ["Gui", "QInputEvent"]
  [ QtExportEvent c_QInputEvent
  ]

c_QInputEvent =
  addReqIncludes [includeStd "QInputEvent"] $
  makeClass (ident "QInputEvent") Nothing [c_QEvent]
  [] $
  collect
  [ just $ mkConstMethod "modifiers" [] $ TBitspace bs_KeyboardModifiers
  , test (qtVersion >= [5, 0]) $ mkConstMethod "timestamp" [] TULong
  ]