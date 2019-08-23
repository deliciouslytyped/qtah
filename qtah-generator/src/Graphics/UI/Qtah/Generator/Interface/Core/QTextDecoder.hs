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

module Graphics.UI.Qtah.Generator.Interface.Core.QTextDecoder (
  aModule,
  c_QTextDecoder,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Export (ExportClass),
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
import Foreign.Hoppy.Generator.Types (intT, charT, voidT, enumT, bitspaceT, constT, objT, ptrT, refT)
import Foreign.Hoppy.Generator.Version (collect, just, test)
import Graphics.UI.Qtah.Generator.Flags (qtVersion)
import Graphics.UI.Qtah.Generator.Interface.Core.QTextCodec (c_QTextCodec)
import Graphics.UI.Qtah.Generator.Interface.Core.QString (c_QString)
import Graphics.UI.Qtah.Generator.Interface.Core.QByteArray (c_QByteArray)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModule)
import Graphics.UI.Qtah.Generator.Types

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModule ["Core", "QTextDecoder"] $
  [QtExport $ ExportClass c_QTextDecoder]

c_QTextDecoder =
  addReqIncludes [ includeStd "QTextDecoder" ] $
  classSetEntityPrefix "" $
  makeClass (ident "QTextDecoder") Nothing [] $
  collect
  [ just $ mkCtor "new" [ptrT $ constT $ objT c_QTextCodec]
   -- TODO QTextDecoder::QTextDecoder(const QTextCodec *codec, QTextCodec::ConversionFlags flags)
  , just $ mkMethod' "toUnicode" "toUnicode" [ptrT $ constT $ charT, intT] $ objT c_QString
  , just $ mkMethod' "toUnicode" "toUnicodeWithByte" [refT $ constT $ objT c_QByteArray] $ objT c_QString
  , just $ mkMethod' "toUnicode" "toUnicodeWithStr" [ptrT $ objT c_QString, ptrT $ constT $ charT, intT] voidT
  ]
