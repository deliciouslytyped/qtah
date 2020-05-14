#With a recent nixpkgs. Needed because it automatically does wrapQtAppsHook
#If you run into errors like `Cannot mix incompatible Qt library (version 0x50c06) with this library (version 0x50c07)`, try a --pure shell
{ boot ? import <nixpkgs> {}
, __pkgs ? import <nixpkgs> {} #import (boot.fetchFromGitHub { owner = "nixos"; repo="nixpkgs"; rev="9d608a6f592144b5ec0b486c90abb135a4b265eb"; sha256="03brvnpqxiihif73agsjlwvy5dq0jkfi2jh4grp4rv5cdkal449k";}) {}
, fetchFromGitHub ? __pkgs.fetchFromGitHub
, needsGLFix ? false #I needed this at some point but it seems fine now?
}:
let
  pkgs = __pkgs;
in
let
  #Not sure why i need this, probably old nixpkgs thing - i need to parametrize this over qt versions
  nixGL = (import (fetchFromGitHub {
    owner = "guibou";
    repo = "nixGL";
    rev = "04a6b0833fbb46a0f7e83ab477599c5f3eb60564";
    sha256 = "0z1zafkb02sxng91nsx0gclc7n7sv3d5f23gp80s3mc07p22m1k5";
    }) { }).nixGLIntel;

  gammaray' = { wrapQtAppsHook, mkDerivation, lib, fetchFromGitHub, cmake, qtbase }: mkDerivation {
    name = "Gammaray";
    src = fetchFromGitHub {
      owner = "KDAB";
      repo = "GammaRay";
      rev = "4245ead89ff7cdc613f69d1d6a9192a5b054695e"; #outdated now probably
      sha256 = "1wk6lsfflz00is33kncjh62c8w7c3gzj8898kakh58m5wbid9c9v";
      };
    buildInputs = [ qtbase ];
    nativeBuildInputs = [ cmake ]; 
    };

  gammaray = pkgs.libsForQt5.callPackage gammaray' {}; #TODO clarify docs
in {
  inherit gammaray nixGL pkgs;
  integrated =
    if needsGLFix
      then
        pkgs.runCommand "gammaray" { buildInputs = [ pkgs.makeWrapper ]; } ''
          makeWrapper ${nixGL}/bin/nixGLIntel $out/bin/gammaray \
            --add-flags "${gammaray}/bin/gammaray"
          ''
      else
        gammaray;
  }

