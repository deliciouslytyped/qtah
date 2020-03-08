#! /usr/bin/env nix-shell
#! nix-shell -I nixkgs=channel:nixos-unstable -i bash -p clang -v
#export CLANG_INSTALL_DIR=/nix/store/d3gsn478zaxc7h4mlaadrig6cx36sk6i-clang-7.1.0
qtIncludes=/nix/store/683fblqihpz1wbrhibwbp02aq684plm7-qtbase-5.12.7-dev/include

include=$1
shift

./result/bin/dumpcodemodel -- -xc++ -I $qtIncludes/ $qtIncludes/$include $@

#TODO incomplete type signatures
#TODO for objects, doesnt list the constructor with no arguments?
