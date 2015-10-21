-- This file is part of Qtah.
--
-- Copyright 2015 Bryan Gardiner <bog@khumba.net>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License version 3
-- as published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- | Shared bindings for @\"Qtah*\"@ qualified imports in generated bindings.
-- Some classes use qualified imports that don't start with @\"Qtah\"@; such
-- imports are one-off and are not listed here.
module Graphics.UI.Qtah.Internal.Interface.Imports (
  importForChar,
  importForForeign,
  importForForeignC,
  importForPrelude,
  importForSignal,
  importForSupport,
  ) where

import Foreign.Hoppy.Generator.Spec (HsImportSet, hsQualifiedImport)

importForChar :: HsImportSet
importForChar = hsQualifiedImport "Data.Char" "QtahDC"

importForForeign :: HsImportSet
importForForeign = hsQualifiedImport "Foreign" "QtahF"

importForForeignC :: HsImportSet
importForForeignC = hsQualifiedImport "Foreign.C" "QtahFC"

importForPrelude :: HsImportSet
importForPrelude = hsQualifiedImport "Prelude" "QtahP"

importForSignal :: HsImportSet
importForSignal = hsQualifiedImport "Graphics.UI.Qtah.Signal" "QtahSignal"

importForSupport :: HsImportSet
importForSupport = hsQualifiedImport "Foreign.Hoppy.Runtime.Support" "QtahFHRS"
