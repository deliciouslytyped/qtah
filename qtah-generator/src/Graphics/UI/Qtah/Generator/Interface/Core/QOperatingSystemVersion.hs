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

module Graphics.UI.Qtah.Generator.Interface.Core.QOperatingSystemVersion (
  aModule,
  c_QOperatingSystemVersion,
  e_OSType,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Export (ExportClass, ExportEnum),
  addReqIncludes,
  classSetConversionToGc,
  classSetEntityPrefix,
  ident,
  ident1,
  includeStd,
  makeClass,
  mkConstMethod,
  mkConstMethod',
  mkStaticMethod,
  mkCtor,
  )
import Foreign.Hoppy.Generator.Spec.ClassFeature (
    ClassFeature (Copyable),
    classAddFeatures,
    )
import Foreign.Hoppy.Generator.Types (intT, enumT, objT)
import Foreign.Hoppy.Generator.Version (collect, just)
import Graphics.UI.Qtah.Generator.Interface.Core.QString (c_QString)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModuleWithMinVersion)
import Graphics.UI.Qtah.Generator.Types

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModuleWithMinVersion ["Core", "QOperatingSystemVersion"] [5, 9] $
  collect
  [ just $ QtExport $ ExportClass c_QOperatingSystemVersion
  , just $ QtExport $ ExportEnum e_OSType
  ]

c_QOperatingSystemVersion =
  addReqIncludes [ includeStd "QOperatingSystemVersion" ] $
  classSetConversionToGc $
  classAddFeatures [Copyable] $
  classSetEntityPrefix "" $
  makeClass (ident "QOperatingSystemVersion") Nothing [] $
  collect
  [ just $ mkCtor "new" [enumT e_OSType, intT]
  , just $ mkCtor "newWithVMinor" [enumT e_OSType, intT, intT]
  , just $ mkCtor "newWithVMinorVMicro" [enumT e_OSType, intT, intT, intT]
  , just $ mkStaticMethod "current" [] $ objT c_QOperatingSystemVersion
  , just $ mkStaticMethod "currentType" [] $ enumT e_OSType
  -- TODO bool QOperatingSystemVersion::isAnyOfType(std::initializer_list<OSType> types) const
  , just $ mkConstMethod "majorVersion" [] intT
  , just $ mkConstMethod "microVersion" [] intT
  , just $ mkConstMethod "minorVersion" [] intT
  , just $ mkConstMethod "name" [] $ objT c_QString
  , just $ mkConstMethod "segmentCount" [] intT
  , just $ mkConstMethod' "type" "typeOSType" [] $ enumT e_OSType
  ]

e_OSType =
  makeQtEnum (ident1 "QOperatingSystemVersion" "OSType") [includeStd "QOperatingSystemVersion"]
  [ (0, ["unknown"])
  , (1, ["windows"])
  , (2, ["mac", "o", "s"])
  , (3, ["i", "o", "s"])
  , (4, ["tv", "o", "s"])
  , (5, ["watch", "o", "s"])
  , (6, ["android"])
  ]
