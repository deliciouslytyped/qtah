#TODO clang version
#      isTruthy = v: ((v  != "") && (v != null) && (v != false) && (v != [])); #TODO unused?
#TODO check everything against default2
{
__pkgs ? (import ./importlib.nix).nixpkgs,
lib ? __pkgs.lib
}:
let
  zero = extern: self: { superpkgs = __pkgs; inherit extern; lib = (import ./lib.nix self) // {}; };

  layer1 = self: super: let inherit (self.superpkgs.stdenv) glibc; inherit (self.superpkgs) libglvnd qt5 writeText applyPatches fetchFromGitHub; in {
    config = { #*this* variant isnt great because of the distance between parameters and body...
      gen_header = {
        range = ":"; #full range
        };

      qt_headers = {
        paths = with qt5; [ qtbase.dev ];
        };

      #TODO not sure if this is exactly correct but it works?
      clang_headers = [
        "${self.llvmPackages.libcxx}/include/c++/v1" #c++ must be before glibc or things break (stupid include resolution order name conflict brittleness
        "${glibc.dev}/include"
        "${libglvnd.dev}/include" #for GL/gl.h for qopengl
        "${self.qt_headers}/include"
        # will warn about duplicate because already included by clang - I think I had this because i passed some flag to disable default includes?
        #TODO libclang in haskell is fucky?b
        #"${self.clang-unwrapped}/lib/clang/${(builtins.parseDrvName self.clang-unwrapped.name).version}/include" #TODO hack?
        ];

      clang_args = [
        "-xc++"
        "-fsyntax-only"
        "-v"
        "-fPIC" #qt wants this for some reason
        "-Xclang" "-detailed-preprocessing-record"
        ];

      #TODO clang has a .python output
      py_clang_binding_path = "${self.lib.unpackSrc self.clang-unwrapped}/bindings/python";

      inspect-qt-ast = {
        #[ testFile "--" ] ++ args ++ (builtins.map (v: " -I " + v + "/include") headers);
        initialCommand =
          let inherit (self.config) inspect-qt-ast clang_headers clang_args; in
          clang_args ++ (builtins.map (v: "-I" + v) clang_headers); #TODO factor out
          #++ [ "--" ]; #TODO for some reason this is bad here #empty compilaition database to avoid error message, see todo; #TODO https://eli.thegreenplace.net/2014/05/21/compilation-databases-for-clang-based-tools
        testFile = self.qt_aggregated_header_full;
        cmdFile = let inherit (self.config.inspect-qt-ast) testFile initialCommand; in
          writeText "cmdfile" "${testFile}\n${self.superpkgs.lib.concatStringsSep "\n" initialCommand}";
        };

      #TODO there are still header errors for some reason
      query-qt = {
        clang-query = "${self.llvmPackages.clang-unwrapped}/bin/clang-query";
        testFile = self.qt_aggregated_header_full;
        #headers = [ glibc.dev self.qt_headers self.llvmPackages.libcxx ]; #TODO why arent these using /include? - aha? note its inocnsistent in initialCommand
        #searchPath = self.superpkgs.lib.makeSearchPath "/include" self.config.query-qt.headers;
        args = [ "--preload=<(echo set output detailed-ast)" ]; #clang 7.1.0 is too old for this
        #initialCommand = args ++ (builtins.map (v: "-I " + v) searchPath) ++ [ testFile ];
        initialCommand = let inherit (self.config) clang_headers clang_args; inherit (self.config.query-qt) args testFile; in
          args ++
          (builtins.map (v: "--extra-arg=${v}") (clang_args ++ (builtins.map (v: "-I" + v) clang_headers))) ++ #TODO factor out
          [ testFile 
            "--" #empty compilaition database to avoid error message, see todo; #TODO https://eli.thegreenplace.net/2014/05/21/compilation-databases-for-clang-based-tools
            ];
        };

      ast-viewer = {
        patches = [
          ./pyclasvi/pyclasvi_crashfix.patch
          #./pyclasvi/pyclasvi_argspassthru.patch #dont need this, i misunderstood the interface
          ];
        bin = "/bin/ast-viewer";
        #nix-shell -p nix-prefetch-github --run "nix-prefetch-github FraMuCoder PyClASVi > pyclasvi/pyclasvi.json"
        src = applyPatches { src = fetchFromGitHub (with builtins; fromJSON (readFile ./pyclasvi/pyclasvi.json)); inherit (self.config.ast-viewer) patches; };
        };

      };
    };

  layer3 = self: super: let inherit (self.superpkgs) enableDebugging python3 gdb writeText writeShellScriptBin runCommand makeWrapper applyPatches fetchFromGitHub qt5 symlinkJoin; in {
    debugpy = let
      self = enableDebugging (
        #output '/nix/store/fip9hficzysnpa4g3nkykp0p06bfm33v-python3-3.7.6' is not allowed to refer to the following paths:
        #  /nix/store/bs24q7v5hzg92zq5l56r7yhnp5ljzjv0-openssl-1.1.1d-dev
        python3.overrideAttrs (old: { disallowedReferences = []; }) #TODO bit of a hack? debug symbols or something probably ends up referring to openssl
        );
      in
        python3.override { inherit self; };

    gdb = runCommand "gdb-withpy" { buildInputs = [ makeWrapper ]; } ''
      mkdir -p "$out/bin"
      makeWrapper "${gdb}/bin/gdb" "$out/bin/gdb" \
        --add-flags '-ex "source ${self.lib.unpackSrc self.debugpy}/Tools/gdb/libpython.py"'
      '';

    inherit (self.superpkgs) llvmPackages;      
    inherit (self.llvmPackages) clang-unwrapped;

    pyWithClang = 
      runCommand "py-with-clang-bind" { buildInputs = [ makeWrapper ]; } ''
        #TODO is there a terser way to do this?
        mkdir -p "$out"/bin
        makeWrapper "${self.debugpy.withPackages (p: [ p.tkinter ])}"/bin/python "$out/bin/python" \
          --prefix PYTHONPATH ":" "${self.config.py_clang_binding_path}"
        '';

    ast-viewer = let inherit (self.config.ast-viewer) bin src; in
      (runCommand "pyclasvi" { buildInputs = [ makeWrapper ]; } ''
        mkdir -p "$out"
        makeWrapper "${self.pyWithClang}/bin/python" "$out/${bin}" \
          --add-flags "${src}/pyclasvi.py \
          ` #--prefix LD_LIBRARY_PATH ":" "${self.superpkgs.lib.makeLibraryPath [ self.llvmPackages.libclang ]}"  #TODO why did the other script have this variant?` \
          -l \"${self.superpkgs.lib.makeLibraryPath [ self.llvmPackages.libclang ]}/libclang.so\"" `#see pyclasvi doc`
        '') // { passthru = { inherit bin; }; };

    inspect-qt-ast = writeShellScriptBin "inspect-qt-ast" ''
      ${self.ast-viewer}/${self.ast-viewer.passthru.bin} ${self.config.inspect-qt-ast.cmdFile} 
      '';  

    query-qt = let inherit (self.config.query-qt) clang-query initialCommand; in
       runCommand "query-qt" { buildInputs = [ makeWrapper ]; } ''
          mkdir -p "$out"/bin
          makeWrapper "${clang-query}" "$out/bin/query-qt" \
            --add-flags '${self.superpkgs.lib.concatStringsSep " " initialCommand}' $@
          '';

    #TODO refactor this section
    qt_headers = symlinkJoin { name = "headers"; inherit (self.config.qt_headers) paths; };

    #a subset for testing
    qt_aggregated_header_full = let
        headers = self.qt_headers;
        #could use python3 instead of debugpy
        res = runCommand "agg-header" { buildInputs = [ self.debugpy ]; } ''
          mkdir -p "$out"
          #The trailing slash is important so the <%s> strings come out right
          python -c 'from pathlib import Path; root = "${headers}/include/"; print("\n".join(list(sorted(["#include <%s>" % str(pth).replace(root, "") for pth in Path(root).glob("Qt*/Q*") if "Platform" not in str(pth)]))[${self.config.gen_header.range}]))' > $out/hdr.cpp
          '';
      in
        "${res}/hdr.cpp";

    #TODO should probably refactor this out...
    #TODO tihs is where this model breaks down in that you cant call the same thing multiple times with different variants (well, you could if you pass `extend` back into the fixpoint
    #NOTE should probably avoid this when possible
#    qt_aggregated_header = (self.extern.extend (self: super:
#      { config = self.lib.ru super.config { gen_header.range = "100:200"; }; }
#      )).qt_aggregated_header_full;
#      qt_aggregated_header_full = super.extern.qt_aggregated_header;

    #TODO since gammaray has tight versioning requirements for qt versions, we coupleit directly yo the things we're building <?>
    gammaray = self.superpkgs.libsForQt5.callPackage ./gammaray.nix {}; #TODO
    };

  layer8 = self: super: let inherit (self.superpkgs) qt5 mkShell; in {
      config = self.lib.ru super.config {
#        inspect-qt-ast = { headers = self.config.qt_headers.paths; };
#        qt_headers = { paths = (super: old: old ++ [ qt5.qtxmlpatterns.dev __pkgs.llvmPackages.libclang.out ]); };
        };

      #TODO not super happy with how the version choice happens
      #TODO figure out how the hell the llvm set works and do this properly (Ericson)
      # Patched llvm so we have tab completion in clang-query
      # LineEditor comes from llvm, so we have to add libedit to llvm, not to clang
      llvmPackages = let _llvmPackages = self.superpkgs.llvmPackages_10; in
        _llvmPackages.extend (_: super2: {
          llvm = super2.llvm.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ [ self.superpkgs.libedit ];
#            buildInputs = old.buildInputs ++ [ ];
            doCheck = false; #takes really long...
            });
          }) // { inherit (_llvmPackages) libcxx; }; #TODO this override is a huge hack to deal with the incomprehensible fuckup that is the llvm .extend-s, and it kidn of works for us because we only overrride for tab completion

      _shellInputs = with self; [ ast-viewer gdb inspect-qt-ast query-qt
        gammaray.gammaray #TODO
        ];
      allShell = mkShell { buildInputs = self._shellInputs; };
      };

  layers = self: l: __pkgs.lib.foldl (a: b: a.extend b) (lib.makeExtensible 
    ((builtins.head l) self) # pass the external fixpoint back into the zeroth layer
    ) (builtins.tail l);
  #So we can pass it back into the fixpoint
  self = layers self [zero layer1 layer3 layer8];
in
  self


