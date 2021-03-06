# This file is part of Qtah.
#
# Copyright 2015-2019 The Qtah Authors.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

{ mkDerivation, base, Cabal, qt, qtah-generator, stdenv, lib
, forceParallelBuilding ? false
}:
mkDerivation {
  pname = "qtah-cpp";
  version = "0.6.1";
  src = ./.;
  libraryHaskellDepends = [ base Cabal qtah-generator ];
  librarySystemDepends = [ qt.qtbase ];
  homepage = "http://khumba.net/projects/qtah";
  description = "Qt bindings for Haskell - C++ library";
  license = stdenv.lib.licenses.lgpl3Plus;

  # TODO Does this make it to BuildFlags.buildNumJobs?
  preConfigure =
    if forceParallelBuilding then ''
      configureFlags+=" --ghc-option=-j$NIX_BUILD_CORES"
    '' else null;
}
