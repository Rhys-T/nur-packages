# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> {} }:

let result = pkgs.lib.makeScope pkgs.newScope (self: let
    inherit (self) callPackage;
in {
    # The `lib`, `modules`, and `overlays` names are special
    # Renamed here to avoid shadowing their builtin nixpkgs counterparts in callPackage
    myLib = import ./lib { inherit pkgs; }; # functions
    myModules = import ./modules; # NixOS modules
    myOverlays = import ./overlays; # nixpkgs overlays
    
    _Read-Me-link = pkgs.runCommandLocal "___Read_Me___" rec {
        message = ''
        This is not a real package.
        It's just here to add a Read Me link for this repo on the NUR site.
        See <${meta.homepage}> for the actual Read Me.
        Or for the local copy: ${toString ./README.md}
        '';
        meta = {
            homepage = "https://github.com/Rhys-T/nur-packages#readme";
            knownVulnerabilities = [message];
        };
    } ''
        echo -E "$message" >&2
        exit 1
    '';
    
    maintainers = import ./maintainers.nix;
    
    lix-game-packages = callPackage ./pkgs/lix-game/packages.nix {};
    lix-game = self.lix-game-packages.game;
    lix-game-server = self.lix-game-packages.server;
    lix-game-libpng = if pkgs.hostPlatform.isDarwin then (self.lix-game-packages.overrideScope (self: super: {
        convertImagesToTrueColor = false;
    })).game else self.lix-game;
    lix-game-issue-431 = if pkgs.hostPlatform.isDarwin then (self.lix-game-packages.overrideScope (self: super: {
        convertImagesToTrueColor = false;
        disableNativeImageLoader = false;
    })).game else self.lix-game;
    lix-game-CIImage = if pkgs.hostPlatform.isDarwin then (self.lix-game-packages.overrideScope (self: super: {
        convertImagesToTrueColor = false;
        disableNativeImageLoader = "CIImage";
    })).game else self.lix-game;
    _ciOnly.lix-game = pkgs.lib.recurseIntoAttrs {
        assets = (self.lix-game-packages.overrideScope (self: super: {
            convertImagesToTrueColor = false;
        })).assets;
        assets-PNG32 = (self.lix-game-packages.overrideScope (self: super: {
            convertImagesToTrueColor = true;
        })).assets;
        inherit (self.lix-game-packages) highResTitleScreen;
    };
    
    xscorch = callPackage ./pkgs/xscorch {};
    
    pce = callPackage ./pkgs/pce {};
    pce-with-unfree-roms = self.pce.override { enableUnfreeROMs = true; };
    pce-snapshot = callPackage ./pkgs/pce/snapshot.nix {};
    
    bubbros = callPackage ./pkgs/bubbros {};
    
    flatzebra = callPackage ./pkgs/flatzebra {};
    burgerspace = callPackage ./pkgs/flatzebra/burgerspace.nix {};
    
    hfsutils = callPackage ./pkgs/hfsutils {};
    hfsutils-tk = self.hfsutils.override { enableTclTk = true; };
    
    minivmac36 = callPackage ./pkgs/minivmac/36.nix {};
    minivmac37 = callPackage ./pkgs/minivmac/37.nix {};
    minivmac = self.minivmac36;
    minivmac-unstable = self.minivmac37;
    
    minivmac-ii = self.minivmac.override { macModel = "II"; };
    minivmac-ii-unstable = self.minivmac-unstable.override { macModel = "II"; };
    
    mame = callPackage (pkgs.callPackage ./pkgs/mame {}) {};
    mame-metal = self.mame.override { darwinMinVersion = "11.0"; };
    hbmame = callPackage ./pkgs/mame/hbmame.nix {};
    hbmame-metal = self.hbmame.override { mame = self.mame-metal; };
    
    pacifi3d = callPackage ./pkgs/pacifi3d {};
    pacifi3d-mame = self.pacifi3d.override { romsFromMAME = self.mame; };
    pacifi3d-hbmame = self.pacifi3d.override { romsFromMAME = self.hbmame; };
    _ciOnly.pacifi3d-rom-xmls = pkgs.lib.recurseIntoAttrs {
        mame = self.pacifi3d-mame.romsFromXML;
        hbmame = self.pacifi3d-hbmame.romsFromXML;
    };
    
    konify = callPackage ./pkgs/konify {};
    
    asciiportal = callPackage ./pkgs/asciiportal {};
    asciiportal-git = callPackage ./pkgs/asciiportal/git.nix {};
    
    xorcurses = callPackage ./pkgs/xorcurses {};
    xorcurses-git = callPackage ./pkgs/xorcurses/git.nix {};
    
    powder = callPackage ./pkgs/powder {};
    
    xinvaders3d = callPackage ./pkgs/xinvaders3d {};
    
    TEST = pkgs.stdenv.mkDerivation {
        name = "TEST";
        dontUnpack = true;
        buildPhase = ''
            clang -otestbin -x c -Wl,-t - <<< $'#include <stdio.h>\nint main() { printf("hello\\n"); return 0; }' | tee test.log
        '';
        installPhase = ''
            install -Dm755 testbin $out/bin/testbin
            install -Dm644 test.log $out/share/TEST/test.log
        '';
    };
    
    icbm3d = pkgs.icbm3d.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace makefile --replace-fail 'CC=' '#CC='
            substituteInPlace randnum.c --replace-fail 'stdio.h' 'stdlib.h'
            sed -i '1i\
            #include <string.h>' text.c
        '';
        meta = old.meta // {
            description = "${old.meta.description or "icbm3d"} (fixed for macOS/Darwin)";
            platforms = old.meta.platforms ++ pkgs.lib.platforms.darwin;
        };
    });
    
    xgalagapp = pkgs.xgalagapp.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace Makefile --replace-fail 'CXX =' '#CXX ='
        '';
        meta = old.meta // {
            description = "${old.meta.description or "xgalagapp"} (fixed for macOS/Darwin)";
            platforms = old.meta.platforms ++ pkgs.lib.platforms.darwin;
        };
    });
    
    fpc = pkgs.fpc.overrideAttrs (old: {
        # preBuild = (old.preBuild or "") + ''
        #     makeFlagsArray+=(FPCOPT+="-FD${pkgs.lib.getBin pkgs.stdenv.cc}/bin -XR/")
        #     echo '[[[[[[[[[[[[[[[[[[[[[[ All store paths in env'
        #     env | grep -Eo '/nix/store/[0-9a-z]{32}-[-.+_?=0-9a-zA-Z]+' | sort | uniq || true
        #     echo -E ']]]]]]]]]]]]]]]]]]]]]] All store paths in env'
        #     echo '[[[[[[[[[[[[[[[[[[[[[[ Store paths in env containing libc'
        #     env | grep -Eoz '/nix/store/[0-9a-z]{32}-[-.+_?=0-9a-zA-Z]+' | xargs -0 ${pkgs.lib.getExe pkgs.fd} 'libc\.(tbd|dylib)$'
        #     echo ']]]]]]]]]]]]]]]]]]]]]] Store paths in env containing libc'
        #     # echo '[[[[[[[[[[[[[[[[[[[[[[ env lines containing those paths'
        #     # set -x
        #     # env | grep -Eoz '/nix/store/[0-9a-z]{32}-[-.+_?=0-9a-zA-Z]+' | xargs -0 ${pkgs.lib.getExe pkgs.fd} 'libc\.(tbd|dylib)$' | while IFS= read -r line; do
        #     #     env | grep -F "$line" || true
        #     # done | sort | uniq
        #     # set +x
        #     # echo ']]]]]]]]]]]]]]]]]]]]]] env lines containing those paths'
        #     echo '[[[[[[[[[[[[[[[[[[[[[[ env lines containing apple-sdk'
        #     env | grep -E '/nix/store/[0-9a-z]{32}-apple-sdk[-.+_?=0-9a-zA-Z]+'
        #     echo ']]]]]]]]]]]]]]]]]]]]]] env lines containing apple-sdk'
        #     exit 1
        # '';
        postPatch = (old.postPatch or "") + ''
            NIX_CFLAGS_COMPILE+=" -isysroot $SDKROOT"
            NIX_CFLAGS_COMPILE+=" -idirafter $SDKROOT/usr/include"
            NIX_CFLAGS_COMPILE+=" -iframework $SDKROOT/System/Library/Frameworks"
        '';
        NIX_DEBUG = 7;
        NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -t";
        meta = old.meta // {
            description = "${old.meta.description or "fpc"} (fixed for macOS/Darwin)";
            platforms = old.meta.platforms ++ pkgs.lib.platforms.darwin;
        };
    });
    
    drl-packages = callPackage ./pkgs/drl/packages.nix {};
    inherit (self.drl-packages) drl drl-hq drl-lq;
    
    man2html = callPackage ./pkgs/man2html {};
    
    # qemu-screamer-nixpkgs = callPackage ./pkgs/qemu-screamer/nixpkgs.nix {};
    qemu-screamer = let
        darwinSdkVersion = "11.0";
        stdenv = if pkgs.hostPlatform.isDarwin && pkgs.lib.versionOlder pkgs.stdenv.hostPlatform.darwinSdkVersion darwinSdkVersion then
            pkgs.overrideSDK pkgs.stdenv {
                inherit darwinSdkVersion;
            }
        else
            pkgs.stdenv
        ;
    in callPackage ./pkgs/qemu-screamer {
        inherit stdenv;
        inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
        inherit (pkgs.darwin.stubs) rez setfile;
        inherit (pkgs.darwin) sigtool;
    };
    
    _ciOnly.mac = pkgs.lib.optionalAttrs pkgs.hostPlatform.isDarwin (pkgs.lib.recurseIntoAttrs {
        wine64Full = pkgs.wine64Packages.full;
    });
    
    # _ciOnly.dev = pkgs.lib.optionalAttrs (pkgs.hostPlatform.system == "x86_64-darwin") (pkgs.lib.recurseIntoAttrs {
    #     checkpoint = pkgs.lib.recurseIntoAttrs (pkgs.lib.mapAttrs (k: pkgs.checkpointBuildTools.prepareCheckpointBuild) {
    #         inherit (self)
    #             # hbmame
    #         ;
    #     });
    # });
}); in result // {
    lib = result.myLib;
    modules = result.myModules;
    overlays = result.myOverlays;
}
