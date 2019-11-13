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

module Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamReader (
  aModule,
  c_QXmlStreamReader,
  e_Error,
  e_ReadElementTextBehaviour,
  e_TokenType,
  ) where

import Foreign.Hoppy.Generator.Spec (
  Export (ExportClass, ExportEnum),
  addReqIncludes,
  classSetEntityPrefix,
  ident,
  ident1,
  includeStd,
  makeClass,
  mkConstMethod,
  mkCtor,
  mkMethod',
  mkMethod,
  mkProp
  )
--import Graphics.UI.Qtah.Generator.Interface.Core.QStringRef (c_QStringRef)
import Graphics.UI.Qtah.Generator.Interface.Core.QString (c_QString)
import Graphics.UI.Qtah.Generator.Interface.Core.QByteArray (c_QByteArray)
import Graphics.UI.Qtah.Generator.Interface.Core.QIODevice (c_QIODevice)
import Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamNamespaceDeclaration (c_QXmlStreamNamespaceDeclaration, qXmlStreamNamespaceDeclarations)
import Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamEntityDeclaration (qXmlStreamEntityDeclarations)
import Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamEntityResolver (c_QXmlStreamEntityResolver)
import Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamNotationDeclaration (qXmlStreamNotationDeclarations)
import Graphics.UI.Qtah.Generator.Interface.Core.QXmlStreamAttributes (c_QXmlStreamAttributes)
import Foreign.Hoppy.Generator.Types (boolT, charT, voidT, enumT, constT, objT, ptrT, refT, toGcT)
import Foreign.Hoppy.Generator.Version (collect, just, test)
import Graphics.UI.Qtah.Generator.Flags (qtVersion)
import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModuleWithMinVersion)
import Graphics.UI.Qtah.Generator.Types
import Graphics.UI.Qtah.Generator.Interface.Core.Types (qint64)

{-# ANN module "HLint: ignore Use camelCase" #-}

aModule =
  AQtModule $
  makeQtModuleWithMinVersion ["Core", "QXmlStreamReader"] [4, 3] $
  collect
  [ just $ QtExport $ ExportClass c_QXmlStreamReader
  , just $ QtExport $ ExportEnum e_Error
  , test (qtVersion >= [4, 6]) $ QtExport $ ExportEnum e_ReadElementTextBehaviour
  , just $ QtExport $ ExportEnum e_TokenType
  ]

c_QXmlStreamReader =
  addReqIncludes [ includeStd "QXmlStreamReader" ] $
  classSetEntityPrefix "" $
  makeClass (ident "QXmlStreamReader") Nothing [] $
  collect
  [ just $ mkCtor "new" []
  , just $ mkCtor "newWithPtrChar" [ptrT $ constT charT]
  , just $ mkCtor "newWithQString" [refT $ constT $ objT c_QString]
  , just $ mkCtor "newWithBytearray" [refT $ constT $ objT c_QByteArray]
  , just $ mkCtor "newWithIODevice" [ptrT $ objT c_QIODevice]
  , just $ mkProp "namespaceProcessing" boolT
  , just $ mkMethod' "addData" "addDataBytearray" [refT $ constT $ objT c_QByteArray] voidT
  , just $ mkMethod' "addData" "addDataQString" [refT $ constT $ objT c_QString] voidT
  , just $ mkMethod' "addData" "addDataPtrchar" [ptrT $ constT charT] voidT
  , test (qtVersion >= [4, 4]) $ mkMethod "addExtraNamespaceDeclaration" [refT $ constT $ objT c_QXmlStreamNamespaceDeclaration] voidT
  , test (qtVersion >= [4, 4]) $ mkMethod "addExtraNamespaceDeclarations" [refT $ constT $ objT qXmlStreamNamespaceDeclarations] voidT
  , just $ mkConstMethod "atEnd" [] boolT
  , just $ mkConstMethod "attributes" [] $ toGcT $ objT c_QXmlStreamAttributes
  , just $ mkConstMethod "characterOffset" [] qint64
  , just $ mkMethod "clear" [] voidT
  , just $ mkConstMethod "columnNumber" [] qint64
  , just $ mkConstMethod "device" [] $ ptrT $ objT c_QIODevice
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "documentEncoding" [] $ objT c_QStringRef
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "documentVersion" [] $ objT c_QStringRef
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "dtdName" [] $ objT c_QStringRef
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "dtdPublicId" [] $ objT c_QStringRef
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "dtdSystemId" [] $ objT c_QStringRef
  , just $ mkConstMethod "entityDeclarations" [] $ toGcT $ objT qXmlStreamEntityDeclarations
  , test (qtVersion >= [4, 4]) $ mkConstMethod "entityResolver" [] $ ptrT $ objT c_QXmlStreamEntityResolver
  , just $ mkConstMethod "error" [] $ enumT e_Error
  , just $ mkConstMethod "errorString" [] $ objT c_QString
  , just $ mkConstMethod "hasError" [] boolT
  , just $ mkConstMethod "isCDATA" [] boolT
  , just $ mkConstMethod "isCharacters" [] boolT
  , just $ mkConstMethod "isComment" [] boolT
  , just $ mkConstMethod "isDTD" [] boolT
  , just $ mkConstMethod "isEndDocument" [] boolT
  , just $ mkConstMethod "isEndElement" [] boolT
  , just $ mkConstMethod "isEntityReference" [] boolT
  , just $ mkConstMethod "isProcessingInstruction" [] boolT
  , just $ mkConstMethod "isStandaloneDocument" [] boolT
  , just $ mkConstMethod "isStartDocument" [] boolT
  , just $ mkConstMethod "isStartElement" [] boolT
  , just $ mkConstMethod "isWhitespace" [] boolT
  , just $ mkConstMethod "lineNumber" [] qint64
--  , just $ mkConstMethod "name" [] $ objT c_QStringRef
  , just $ mkConstMethod "namespaceDeclarations" [] $ toGcT $ objT qXmlStreamNamespaceDeclarations
  --, just $ mkConstMethod "namespaceUri" [] $ objT c_QStringRef
  , just $ mkConstMethod "notationDeclarations" [] $ toGcT $ objT qXmlStreamNotationDeclarations
  --, test (qtVersion >= [4, 4]) $ mkConstMethod "prefix" [] $ objT c_QStringRef
  --, just $ mkConstMethod "processingInstructionData" [] $ objT c_QStringRef
  --, just $ mkConstMethod "processingInstructionTarget" [] $ objT c_QStringRef
  --, just $ mkConstMethod "qualifiedName" [] $ objT c_QStringRef
  , just $ mkMethod' "raiseError" "raiseError" [] voidT
  , just $ mkMethod' "raiseError" "raiseErrorWithMessage" [refT $ constT $ objT c_QString] voidT
  , test (qtVersion >= [4, 6]) $ mkMethod' "readElementText" "readElementText" [] $ objT c_QString
  , test (qtVersion >= [4, 6]) $ mkMethod' "readElementText" "readElementTextWithBehav" [enumT e_ReadElementTextBehaviour] $ objT c_QString
  , just $ mkMethod "readNext" [] $ enumT e_TokenType
  , test (qtVersion >= [4, 6]) $ mkMethod "readNextStartElement" [] boolT
  , just $ mkMethod "setDevice" [ptrT $ objT c_QIODevice] voidT
  , test (qtVersion >= [4, 4]) $ mkMethod "setEntityResolver" [ptrT $ objT c_QXmlStreamEntityResolver] voidT
  , test (qtVersion >= [4, 6]) $ mkMethod "skipCurrentElement" [] voidT
  --, just $ mkConstMethod "text" [] $ objT c_QStringRef
  , just $ mkConstMethod "tokenString" [] $ objT c_QString
  , just $ mkConstMethod "tokenType" [] $ enumT e_TokenType
  ]

e_Error =
  makeQtEnum (ident1 "QXmlStreamReader" "Error") [includeStd "QXmlStreamReader"]
  [ (0, ["no", "error"])
  , (1, ["unexpected", "element", "error"])
  , (2, ["custom", "error"])
  , (3, ["not", "well", "formed", "error"])
  , (4, ["premature", "end", "of", "document", "error"])
  ]

e_ReadElementTextBehaviour =
  makeQtEnum (ident1 "QXmlStreamReader" "ReadElementTextBehaviour") [includeStd "QXmlStreamReader"]
  [ (0, ["error", "on", "unexpected", "element"])
  , (1, ["include", "child", "elements"])
  , (2, ["skip", "child", "elements"])
  ]

e_TokenType =
  makeQtEnum (ident1 "QXmlStreamReader" "TokenType") [includeStd "QXmlStreamReader"]
  [ (0, ["no", "token"])
  , (1, ["invalid"])
  , (2, ["start", "document"])
  , (3, ["end", "document"])
  , (4, ["start", "element"])
  , (5, ["end", "element"])
  , (6, ["characters"])
  , (7, ["comment"])
  , (8, ["d", "t", "d"])
  , (9, ["entity", "reference"])
  , (10, ["processing", "instruction"])
  ]
