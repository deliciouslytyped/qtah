#! /usr/bin/env bash
cat <(cd $(nix eval '((import <nixpkgs> {}).qt5.qtbase.dev.outPath)' | tr -d '"')/include; find . -type f ! -name "*.h" -exec echo "{}" \; | grep -E "(QtGui|QtWidgets|QtCore)") > modlist.txt
