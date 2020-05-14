let
  sources = import ./sources.nix;
in {
  nixpkgs = import sources.nixpkgs {}; 
  haskell-nix = import sources.haskell-nix {};
  }
