let
  # Look here for information about how to generate `nixpkgs-version.json`.
  #  → https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  pinnedVersion = builtins.fromJSON (builtins.readFile ./.nixpkgs-version.json);
  pinnedPkgs = import (builtins.fetchGit {
    inherit (pinnedVersion) url rev;

    ref = "nixos-unstable";
  }) {};
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? pinnedPkgs }:


pkgs.callPackage ({fetchgit, cmake, qt512, llvmPackages, python37, makeWrapper}:
let
  sources = {
    _5_12_3 = {
      url = "http://code.qt.io/pyside/pyside-setup.git";
      rev = "fef1bfb9069afb64761cdac7bc219b3a510fec19"; #needed for patch to work
      sha256 = "sha256:18p6hyvdgys45jhijlmgjpp48rkikr36hpsrly9rcr0vais3h5zz";
      };
    };
      #rev = "da93f708354168975e8f906080b64a323d439117"; #dev
      #rev = "d1604053e9ae354963a2b2447b3d196fc5dda73e"; #latest with bindgen
      #rev = "91accc79d8a9bfb7f7016871aa9cc62fd2dc406e"; #5.12.6 #TODO sould be 5.12.7?

in
  #see https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/python-modules/shiboken2/default.nix
  pkgs.stdenv.mkDerivation {
    name = "apiExtractor";

    src = fetchgit sources._5_12_3;

    nativeBuildInputs = [ cmake ];
    buildInputs = [ qt512.qtbase qt512.qtxmlpatterns llvmPackages.libclang python37 makeWrapper ];

    patches = [
      ./dumper.patch 
      ./more-dump.patch
      <nixpkgs/pkgs/development/python-modules/shiboken2/nix_compile_cflags.patch> # needs 5.12.3
      ];

    postPatch = ''
      cd sources/shiboken2
      '';

    installPhase = ''
      mkdir -p $out/bin
      cp tests/dumpcodemodel/dumpcodemodel $out/bin
      wrapProgram $out/bin/dumpcodemodel \
        --set CLANG_INSTALL_DIR "${llvmPackages.libclang.out}"
      '';

    CLANG_INSTALL_DIR = llvmPackages.libclang.out; #was this needed for cmake or runtime stuff, or both?

    cmakeFlags = [
      "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
      "-DBUILD_TESTS:BOOL=ON"
      "-DCMAKE_CXX_FLAGS=-I${llvmPackages.libclang.out}/include"
      #"--target " #TODO wtf
      ];

    }) {}

