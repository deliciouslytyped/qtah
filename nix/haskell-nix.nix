let
  tarb = (builtins.fetchTarball https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz);
  tb = import tarb;
  theoverlay = self: super: { qtbase = self.qt5.qtbase; };
  _pkgs = (import (tarb + "/nixpkgs")) ({nixpkgs-pin = "release-19.09";} // { overlays = tb.overlays ++ [ theoverlay ]; config = tb.config; });
  pkgs = _pkgs;
in
#{pkgs? _pkgs}:
  pkgs.haskell-nix.stackProject {
    src = pkgs.haskell-nix.haskellLib.cleanGit { src = ./.; };
  }
