{callPackage, requireFile, fetchurl, fetchpatch, ...}@args: let
    thruArgs = removeAttrs args ["callPackage" "requireFile" "fetchurl" "fetchpatch"];
in callPackage ./generic.nix (thruArgs // rec {
    version = "0.2.2";
    includesUnfreeROMs = true;
    src = rec {
        name = "pce-${version}.tar.gz";
        url = "http://www.hampa.ch/pub/pce/pce-${version}.tar.gz";
        hashWithROMs = "sha256-qMBWD8vwzBVMj1ASGG89OVKv29FEtBkSTAmlb5uquZk=";
        hashWithoutROMs = "sha256-z65BS+arlhem1Z0CN9W5S4p4M3onQNqX804kFeRonME=";
        withoutROMs = fetchurl {
            url = "https://media.githubusercontent.com/media/Rhys-T/nur-packages/f77995a2952eacba9bef8c0af1603119a906770a/pce-without-unfree-roms-${version}.tar.gz";
            hash = hashWithoutROMs;
        };
    };
    patches = [(fetchpatch {
        name = "0001-68000-Add-a-missing-extern-declaration.patch";
        urls = [
            "file://${./patches/0001-68000-Add-a-missing-extern-declaration.patch}"
            "http://git.hampa.ch/pce.git/patch/f9ebfc33107a10436506861601b162df98ca743e"
        ];
        # Fix the changes to the copyright header comment,
        # because otherwise the patch doesn't apply correctly.
        decode = "sed 's/(C) 2005-2018/(C) 2005-2009/'";
        hash = "sha256-T3Fc4yHANjpE1Peh7Fipuk5rqFrSCpGK1f5HWyz/Q5g=";
    })];
    supportsSDL2 = false;
    appNames = [
        "pbit"
        "pce-ibmpc"
        "pce-img"
        "pce-macplus"
        "pce-rc759"
        "pce-sim405"
        "pce-sim6502"
        "pce-simarm"
        "pce-sims32"
        "pfdc"
    ];
})
