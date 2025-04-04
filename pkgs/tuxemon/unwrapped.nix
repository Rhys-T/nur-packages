{
    python3Packages,
    fetchFromGitHub, fetchPypi,
    lib, stdenv,
    version, rev ? "v${version}", hash?null,
    libShake ? null, withLibShake ? true,
    desktopToDarwinBundle,
    data, attachPkgs, pkgs,
    _pos, gitUpdater, unstableGitUpdater, symlinkJoin, writeShellApplication,
    maintainers
}: let
    inherit (stdenv) hostPlatform;
    python3PackagesOrig = python3Packages;
in let
    python3Packages = (python3PackagesOrig.python.override {
        packageOverrides = pself: psuper: {
            pyglet = pself.callPackage ./fix-pyglet.nix { pyglet' = psuper.pyglet; };
        };
    }).pkgs;
    pygame-ce' = python3Packages.pygame-ce.overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + lib.optionalString (
            (lib.versionAtLeast python3Packages.meson-python.version "0.17") &&
            !(lib.hasInfix "\"meson-python<=" (old.postPatch or ""))
        ) ''
            substituteInPlace pyproject.toml \
                --replace-fail '"meson-python<=0.16.0",' '"meson-python",'
        '';
    });
    neteria = python3Packages.buildPythonPackage rec {
        pname = "neteria";
        version = "1.0.2";
        src = fetchPypi {
            inherit pname version;
            hash = "sha256-Z/uCYGquDLEU1NsKKJ/QqE8xJl5tgT+i0HYbBVCP9Ks=";
        };
        postPatch = ''
            substituteInPlace neteria/core.py --replace-fail 'is not 0' '!= 0'
        '';
        dependencies = with python3Packages; [rsa];
    };
    pyscroll = python3Packages.buildPythonPackage rec {
        pname = "pyscroll";
        version = "2.31";
        src = fetchPypi {
            inherit pname version;
            hash = "sha256-GQIFGyCEN5/I22mfCgDSbV0g5o+Nw8RT316vOSsqbHA=";
        };
        dependencies = [pygame-ce'];
    };
    pygame-menu-ce = python3Packages.buildPythonPackage rec {
        pname = "pygame-menu-ce";
        version = "4.4.3";
        src = fetchPypi {
            inherit pname version;
            hash = "sha256-p14PBkst5eKPVShIKX51WjU39IABdOXEZShAKhitYrg=";
        };
        dependencies = with python3Packages; [pygame-ce' pyperclip typing-extensions];
    };
    tuxemon = python3Packages.buildPythonApplication {
        pname = "tuxemon";
        inherit version;
        src = fetchFromGitHub {
            owner = "Tuxemon";
            repo = "Tuxemon";
            inherit rev;
            ${if hash != null then "hash" else null} = hash;
        };
        pyproject = true;
        pythonRelaxDeps = true;
        pythonRemoveDeps = ["pygame_menu" "pygame-menu"];
        nativeBuildInputs = [python3Packages.pythonRelaxDepsHook] ++ lib.optional hostPlatform.isDarwin desktopToDarwinBundle;
        build-system = with python3Packages; [
            setuptools
            setuptools-scm
        ];
        dependencies = with python3Packages; [
            babel
            cbor
            neteria
            pillow
            pygame-ce'
            pyscroll
            pytmx
            requests
            natsort
            pyyaml
            prompt-toolkit
            pygame-menu-ce
            pydantic
        ];
        inherit data;
        postPatch = ''
            substituteInPlace tuxemon/platform/__init__.py \
                --replace-fail '"/usr/share/tuxemon/"' 'os.path.join(os.getenv("NIX_TUXEMON_DIR"), "")'
            sed -Ei '
                s@import logging@&, sys@
                /mods_folder =/ {
                    s@os.path.join\(LIBDIR, "\.\.", "mods"\)@os.path.join(os.getenv("NIX_TUXEMON_DIR"), "mods")@
                }
            ' tuxemon/constants/paths.py
        '' + lib.optionalString withLibShake ''
            sed -Ei 's@locations = \[.*\]@locations = ["${lib.getLib libShake}/lib/libShake${hostPlatform.extensions.sharedLibrary}"]@' tuxemon/rumble/__init__.py
        '';
        makeWrapperArgs = ["--set-default NIX_TUXEMON_DIR $out/share/tuxemon"];
        postInstall = ''
            mkdir -p "$out"/share/tuxemon/mods
            ln -s "$data"/share/tuxemon/mods/* "$out"/share/tuxemon/mods/
            install -Dm755 run_tuxemon.py "$out"/bin/tuxemon # replaces default tuxemon command - has more CLI options
            install -Dm755 buildconfig/flatpak/org.tuxemon.Tuxemon.desktop "$out"/share/applications/org.tuxemon.Tuxemon.desktop
            substituteInPlace "$out"/share/applications/org.tuxemon.Tuxemon.desktop --replace-fail 'Exec=org.tuxemon.Tuxemon' 'Exec=tuxemon'
            install -Dm755 buildconfig/flatpak/org.tuxemon.Tuxemon.appdata.xml "$out"/share/metainfo/org.tuxemon.Tuxemon.appdata.xml
            install -Dm644 mods/tuxemon/gfx/icon.png "$out"/share/icons/hicolor/64x64/apps/org.tuxemon.Tuxemon.png
            install -Dm644 mods/tuxemon/gfx/icon_128.png "$out"/share/icons/hicolor/128x128/apps/org.tuxemon.Tuxemon.png
            install -Dm644 mods/tuxemon/gfx/icon_32.png "$out"/share/icons/hicolor/32x32/apps/org.tuxemon.Tuxemon.png
        '';
        meta = {
            description = "Open source monster-fighting RPG";
            longDescription = ''
                Tuxemon is a free, open source monster-fighting RPG. It's in constant development and improving all the time! Contributors of all skill levels are welcome to join.
                
                Features:
                * Game data is all json, easy to modify and extend
                * Game maps are created using the Tiled Map Editor
                * Simple game script to write the story
                * Dialogs, interactions on map, npc scripting
                * Localized in several languages
                * Seamless keyboard, mouse, and gamepad input
                * Animated maps
                * Lots of documentation
                * Python code can be modified without a compiler
                * CLI interface for live game debugging
                * Runs on Windows, Linux, OS X, and some support on Android
                * 183 monsters with sprites
                * 98 techniques to use in battle
                * 221 NPC sprites
                * 18 items
            '';
            homepage = "https://tuxemon.org/";
            mainProgram = "tuxemon";
            license = with lib.licenses; [
                gpl3Plus
                mit # for tuxemon/lib/bresenham.py
            ];
            maintainers = [maintainers.Rhys-T];
        };
        pos = _pos;
        passthru.updateScript = let
            fixUpdater = u: u.override (old: {
                common-updater-scripts = symlinkJoin {
                    name = "tuxemon-updater-scripts-wrapper";
                    paths = [
                        (writeShellApplication {
                            name = "update-source-version";
                            runtimeInputs = [old.common-updater-scripts];
                            text = ''
                                update-source-version "$@"
                                args=()
                                for arg in "$@"; do
                                    case "$arg" in
                                        --rev=*)
                                            continue
                                            ;;
                                    esac
                                    args+=("$arg")
                                done
                                update-source-version "''${args[@]}" --ignore-same-version --source-key=data
                            '';
                        })
                        old.common-updater-scripts
                    ];
                };
            });
        in if lib.hasPrefix "v" rev then fixUpdater gitUpdater {
            rev-prefix = "v";
        } else fixUpdater unstableGitUpdater {
            tagFormat = "v*";
            tagPrefix = "v";
        };
    };
in attachPkgs pkgs tuxemon
