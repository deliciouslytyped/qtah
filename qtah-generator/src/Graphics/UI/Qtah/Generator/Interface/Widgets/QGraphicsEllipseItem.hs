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

module Graphics.UI.Qtah.Generator.Interface.Widgets.QGraphicsEllipseItem (
  aModule,
  c_QGraphicsEllipseItem,
  ) where

import Foreign.Hoppy.Generator.Spec (
  addReqIncludes,
  classSetEntityPrefix,
  ident,
  includeStd,
  makeClass,
  mkCtor,
  np,
  )
import Graphics.UI.Qtah.Generator.Interface.Core.Types (qreal)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModule)
import Graphics.UI.Qtah.Generator.Interface.Widgets.QAbstractGraphicsShapeItem
  (c_QAbstractGraphicsShapeItem)
import Graphics.UI.Qtah.Generator.Types

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModule ["Widgets", "QGraphicsEllipseItem"]
  [ qtExport c_QGraphicsEllipseItem
  ]

c_QGraphicsEllipseItem =
  addReqIncludes [includeStd "QGraphicsEllipseItem"] $
  classSetEntityPrefix "" $
  makeClass (ident "QGraphicsEllipseItem") Nothing [c_QAbstractGraphicsShapeItem]
  [ mkCtor "new" np
  , mkCtor "newWithRaw" [qreal, qreal, qreal, qreal]
  ]
