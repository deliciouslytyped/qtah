let
  # Look here for information about how to generate `nixpkgs-version.json`.
  #  → https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  pinnedVersion = builtins.fromJSON (builtins.readFile ./upstream/nixpkgs-version.json);
  pinnedPkgs = import (builtins.fetchGit {
    inherit (pinnedVersion) url rev;

    ref = "nixos-unstable";
  }) {};
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? pinnedPkgs }: {
  #TODO also generate local includes directory and stuff so eclipse tab completion works
  eclipse = pkgs.mkShell { #TODO this should proably be tacked ont apidumper
    name = "apiex-devver";
    CLANG_INSTALL_DIR = pkgs.llvmPackages.libclang.out;
    buildInputs = [ pkgs.git pkgs.nix pkgs.eclipses.eclipse-cpp pkgs.clang pkgs.cmake pkgs.qt5.qtbase pkgs.qt5.qtxmlpatterns pkgs.llvmPackages.libclang ]; #TODO just add buildinputs?
    shellHook = "${builtins.unsafeDiscardStringContext (builtins.toString ./.)}/add-headers.sh";
    };
  #TODO just use buildInputs from apidumper?
  headers = pkgs.symlinkJoin { name = "headers"; paths = with pkgs.qt5; [ qtbase.dev qtxmlpatterns.dev pkgs.llvmPackages.libclang.out ]; };
  apidumper-local = pkgs.callPackage ./apidumper-local.nix {};
  apidumper-upstream = #TODO test because i just refactored
    let
      sources = {
        _5_12_3 = {
          url = "http://code.qt.io/pyside/pyside-setup.git";
          rev = "fef1bfb9069afb64761cdac7bc219b3a510fec19"; #needed for old patch to work
          sha256 = "sha256:18p6hyvdgys45jhijlmgjpp48rkikr36hpsrly9rcr0vais3h5zz";
          };
        _5_12_6 = {
          url = "http://code.qt.io/pyside/pyside-setup.git";
          rev = "91accc79d8a9bfb7f7016871aa9cc62fd2dc406e"; #new patch
          sha256 = "sha256:0mbayrnf50ha3fp081ijnmilclhzmgy6h16vaj9as1fdrqi1v7c9";
          };
        #rev = "da93f708354168975e8f906080b64a323d439117"; #dev
        #rev = "d1604053e9ae354963a2b2447b3d196fc5dda73e"; #latest with bindgen
        #rev = "91accc79d8a9bfb7f7016871aa9cc62fd2dc406e"; #5.12.6 #TODO sould be 5.12.7?
        };
    in
      (pkgs.callPackage ./apidumper-local.nix {}).overrideAttrs (old: {
        src = pkgs.fetchgit sources._5_12_6;

        patches = [
          ./upstream/dumper-backport.patch 
          ./upstream/more-dump.patch
          ./upstream/nix_compile_cflags.patch
          #<nixpkgs/pkgs/development/python-modules/shiboken2/nix_compile_cflags.patch> # needs 5.12.3
          ];

        #todo, easy fix: cp: cannot stat 'tests/dumpcodemodel/dumpcodemodel': No such file or directory
        installPhase = builtins.replaceStrings [ "dumpcodemodel/dumpcodemodel" ] [ "tests/dumpcodemodel/dumpcodemodel" ] old.installPhase;

        cmakeFlags = old.cmakeFlags ++ [
          "-DBUILD_TESTS:BOOL=ON"
          #"--target " #TODO wtf
          ];

        });
  }
