{stdenv, fetchgit, cmake, qt512, llvmPackages, python37, makeWrapper}:
  #see https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/python-modules/shiboken2/default.nix
  stdenv.mkDerivation {
    name = "apiExtractor";

    src = ./shiboken2-dev;

    nativeBuildInputs = [ cmake ];
    buildInputs = [ qt512.qtbase qt512.qtxmlpatterns llvmPackages.libclang python37 makeWrapper ];

    patches = [
      ./nix_compile_cflags.patch
      ];

    installPhase = ''
      mkdir -p $out/bin
      cp dumpcodemodel/dumpcodemodel $out/bin
      wrapProgram $out/bin/dumpcodemodel \
        --set CLANG_INSTALL_DIR "${llvmPackages.libclang.out}"
      '';

    CLANG_INSTALL_DIR = llvmPackages.libclang.out; #was this needed for cmake or runtime stuff, or both?

    cmakeFlags = [
      "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
      "-DCMAKE_CXX_FLAGS=-I${llvmPackages.libclang.out}/include"
      ];

    }
