{ pkgs }:

with pkgs.lib; rec {
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
  mirrors = import ./mirrors.nix;
  # HACK to make <nixpkgs/maintainers/scripts/update.nix> work:
  inherit getVersion;
  
  addMetaAttrsDeep = m: p: let
    inherit (pkgs.lib) addMetaAttrs;
  in if p?overrideAttrs then p.overrideAttrs (old: addMetaAttrs m old) else addMetaAttrs m p;
  
  # Variation of `pkgs.lib.warnOnInstantiate` that also leaves my custom attributes alone.
  warnOnInstantiate =
    msg: drv:
    let
      drvToWrap = removeAttrs drv [
        "meta"
        "name"
        "type"
        "_Rhys-T"
      ];
    in
    drv // mapAttrs (_: warn msg) drvToWrap;
    
    oldestSupportedReleaseIsAtLeast = pkgs.lib.oldestSupportedReleaseIsAtLeast or pkgs.lib.isInOldestRelease;
    isDeprecated = {
      mame = oldestSupportedReleaseIsAtLeast 2505;
      pr419640 = oldestSupportedReleaseIsAtLeast 2511;
    };
    warnDeprecated = mapAttrs (deprType: isDepd: attr: pkg: myPkg: if isDepd then
      warnOnInstantiate "Rhys-T's `${attr}` package is deprecated. Please use ${
        if pkgs.lib.getName pkg == "hbmame" then
          "Rhys-T's main `hbmame` package"
        else
          "the `${attr}` package from Nixpkgs"
      } instead." pkg
    else myPkg) isDeprecated;
}
