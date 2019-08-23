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

module Graphics.UI.Qtah.Generator.Interface.Core.QLoggingCategory (
  aModule,
  c_QLoggingCategory,
  categoryFilter,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Export (ExportClass),
  Operator (OpCall),
  Type,
  addReqIncludes,
  classSetEntityPrefix,
  ident,
  ident1,
  ident2,
  includeLocal,
  includeStd,
  makeClass,
  makeFnMethod,
  mkConstMethod,
  mkConstMethod',
  mkStaticMethod,
  mkStaticMethod',
  mkCtor,
  mkMethod',
  mkMethod
  )
import Graphics.UI.Qtah.Generator.Interface.Core.QString (c_QString)
import Foreign.Hoppy.Generator.Types (charT, voidT, boolT, enumT, bitspaceT, constT, objT, ptrT, refT, fnT)
import Foreign.Hoppy.Generator.Version (collect, just, test)
import Graphics.UI.Qtah.Generator.Flags (qtVersion)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModuleWithMinVersion)
import Graphics.UI.Qtah.Generator.Types
import Graphics.UI.Qtah.Generator.Interface.Core.Types (e_QtMsgType)

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModuleWithMinVersion ["Core", "QLoggingCategory"] [5, 2] $
  [QtExport $ ExportClass c_QLoggingCategory]

c_QLoggingCategory =
  addReqIncludes [ includeStd "QLoggingCategory" ] $
  classSetEntityPrefix "" $
  makeClass (ident "QLoggingCategory") Nothing [] $
  collect
  [ test (qtVersion >= [5, 4]) $ mkCtor "newWithMsgType" [ptrT $ constT charT, enumT e_QtMsgType]
  , just $ mkCtor "new" [ptrT $ constT charT]
  , just $ mkConstMethod "categoryName" [] $ ptrT $ constT charT
  , just $ mkStaticMethod "defaultCategory" [] $ ptrT $ objT c_QLoggingCategory
  , just $ mkStaticMethod "installFilter" [categoryFilter] categoryFilter
  , just $ mkConstMethod "isCriticalEnabled" [] boolT
  , just $ mkConstMethod "isDebugEnabled" [] boolT
  , just $ mkConstMethod "isEnabled" [enumT e_QtMsgType] boolT
  , test (qtVersion >= [5, 5]) $ mkConstMethod "isInfoEnabled" [] boolT
  , just $ mkConstMethod "isWarningEnabled" [] boolT
  , just $ mkMethod "setEnabled" [enumT e_QtMsgType, boolT] voidT
  , just $ mkStaticMethod "setFilterRules" [refT $ constT $ objT c_QString] voidT
  , just $ mkMethod' OpCall "call" [] $ refT $ objT c_QLoggingCategory
  , just $ mkConstMethod' OpCall "callConst" [] $ refT $ constT $ objT c_QLoggingCategory
  ]

categoryFilter :: Type
categoryFilter = ptrT $ fnT [ptrT $ objT c_QLoggingCategory] voidT
