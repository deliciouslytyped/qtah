self: let 
  inherit (self.superpkgs) runCommand;
in {
  #https://stackoverflow.com/questions/51333232/nixos-how-do-i-get-get-a-python-with-debug-info-included-with-packages
  unpackSrc = drv: runCommand "${drv.name}-unpacked" { inherit (drv) src; } ''
    unpackPhase
    mv "$sourceRoot" "$out"
    '';

  #same as lib but now we have leaf attrs with an (old: ...) function, if you want to pass a lambda anyway, use (f: f)
  recursiveUpdateUntil2 = with builtins; with self.superpkgs.lib; pred: lhs: rhs:
    let f = attrPath:
      zipAttrsWith (n: values:
        let here = attrPath ++ [n];
            _l = tail values;
            r = head values;
            #this is what's different from nixpkgs lib
            new = if (typeOf r == "lambda") && (n != "__functor")
                    then r lhs (head _l)
                    else r;
        in
      
        if _l == [] || pred here (head _l) r then
          new
        else
          f here values
        );
    in f [] [rhs lhs];

  recursiveUpdate2 = with builtins; lhs: rhs:
    self.lib.recursiveUpdateUntil2 (path: lhs: rhs:
      !((isAttrs lhs && isAttrs rhs))
      ) lhs rhs;

  #TODO redundant
  ru = sett: override: self.lib.recursiveUpdate2 sett override;
  }
