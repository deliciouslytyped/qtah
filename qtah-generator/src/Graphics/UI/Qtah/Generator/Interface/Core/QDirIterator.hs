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

module Graphics.UI.Qtah.Generator.Interface.Core.QDirIterator (
  aModule,
  c_QDirIterator,
  e_IteratorFlag,
  bs_IteratorFlags,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Export (ExportClass, ExportBitspace, ExportEnum),
  addReqIncludes,
  classSetEntityPrefix,
  ident,
  ident1,
  includeStd,
  makeClass,
  mkConstMethod,
  mkCtor,
  mkMethod
  )
import Foreign.Hoppy.Generator.Types (boolT, bitspaceT, constT, objT, refT)
import Foreign.Hoppy.Generator.Version (collect, just)
import Graphics.UI.Qtah.Generator.Interface.Core.QString (c_QString)
--import Graphics.UI.Qtah.Generator.Interface.Core.QFileInfo (c_QFileInfo)
import Graphics.UI.Qtah.Generator.Interface.Core.QStringList (c_QStringList)
import Graphics.UI.Qtah.Generator.Interface.Core.QDir (c_QDir, bs_Filters)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModuleWithMinVersion)
import Graphics.UI.Qtah.Generator.Types

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModuleWithMinVersion ["Core", "QDirIterator"] [4, 3] $
  collect
  [ just $ QtExport $ ExportClass c_QDirIterator
  , just $ QtExport $ ExportEnum e_IteratorFlag
  , just $ QtExport $ ExportBitspace bs_IteratorFlags
  ]

c_QDirIterator =
  addReqIncludes [ includeStd "QDirIterator" ] $
  classSetEntityPrefix "" $
  makeClass (ident "QDirIterator") Nothing [] $
  collect
  [ just $ mkCtor "new" [refT $ constT $ objT c_QDir]
  , just $ mkCtor "newWithDirAndFlags" [refT $ constT $ objT c_QDir, bitspaceT bs_IteratorFlags]
  , just $ mkCtor "newWithString" [refT $ constT $ objT c_QString]
  , just $ mkCtor "newWithStringAndFlags" [refT $ constT $ objT c_QString, bitspaceT bs_IteratorFlags]
  , just $ mkCtor "newWithStringAndFilters" [refT $ constT $ objT c_QString, bitspaceT bs_Filters]
  , just $ mkCtor "newWithStringAndFiltersAndFlags" [refT $ constT $ objT c_QString, bitspaceT bs_Filters, bitspaceT bs_IteratorFlags]
  , just $ mkCtor "newWithStringAndStringList" [refT $ constT $ objT c_QString, refT $ constT $ objT c_QStringList]
  , just $ mkCtor "newWithStringAndStringListAndFilters" [refT $ constT $ objT c_QString, refT $ constT $ objT c_QStringList, bitspaceT bs_Filters]
  , just $ mkCtor "newWithStringAndStringListAndFiltersAndFlags" [refT $ constT $ objT c_QString, refT $ constT $ objT c_QStringList, bitspaceT bs_Filters, bitspaceT bs_IteratorFlags]
  --, just $ mkConstMethod "fileInfo" [] $ objT c_QFileInfo
  , just $ mkConstMethod "fileName" [] $ objT c_QString
  , just $ mkConstMethod "filePath" [] $ objT c_QString
  , just $ mkConstMethod "hasNext" [] boolT
  , just $ mkMethod "next" [] $ objT c_QString
  , just $ mkConstMethod "path" [] $ objT c_QString
  ]

(e_IteratorFlag, bs_IteratorFlags) =
  makeQtEnumBitspace (ident1 "QDirIterator" "IteratorFlag") "IteratorFlags" [includeStd "QDirIterator"]
  [ (0x0, ["no", "iterator", "flags"])
  , (0x2, ["subdirectories"])
  , (0x1, ["follow", "symlinks"])
  ]