let
  inherit (import ./importlib.nix) nixpkgs haskell-nix;
  haskell = import haskell-nix.sources.nixpkgs-1909 haskell-nix.nixpkgsArgs;
  inherit (nixpkgs) mkShell cabal-install bashInteractive;
  inherit (import ./impl.nix {}) _shellInputs llvmPackages; #fucking calling conventions
in 

mkShell {
  buildInputs = _shellInputs ++ [
    cabal-install
    #haskell.ghc #sometings fucked with libc symbol stuff
    nixpkgs.ghc 

    # keep this line if you use bash
    bashInteractive

    llvmPackages.llvm
    ];
    #TODO can I just put libclang in buildinputs or something
    CLANG_PURE_LLVM_INCLUDE_DIR = "${llvmPackages.libclang.out}/include";
    CLANG_PURE_LLVM_LIB_DIR = "${llvmPackages.libclang.lib}/lib";
    
}
