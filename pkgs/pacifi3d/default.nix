{ stdenv, lib, fetchurl, SDL_compat, maintainers }: stdenv.mkDerivation rec {
    pname = "pacifi3d";
    version = "0.3";
    src = fetchurl {
        url = "http://pacifi3d.retrogames.com/pacifi3d/pacifi3d${version}-src.tgz";
        hash = "sha256-M9/XIHVXLFEV+SZAuwkSPKH+YZwdgQ1qFGBzWKjV0F8=";
    };
    whichPlatform = if stdenv.isDarwin then "macosx" else "linux";
    postPatch = ''
        sed -E -i.bak '
            s/\w+\s*=\s*gcc/#&/g
            ${lib.optionalString stdenv.isDarwin ''
                s/-mtune=G4//g
                s/-framework SDL/`sdl-config --libs`/g
                s@/Developer/Tools/CpMac@cp@g
            ''}
        ' "makefiles/Makefile.$whichPlatform"
        substituteInPlace src/Makefile.common --replace-fail '$(LD)' '$(CC)'
        substituteInPlace src/video.h --replace-fail 'void (*blitter)(void);' '// void (*blitter)(void);'
        for file in src/ghost.c src/pacman.c; do
            substituteInPlace "$file" --replace-fail 'enum {X, Y, Z} axes;' 'enum axes {X, Y, Z};'
        done
        substituteInPlace src/video.c --replace-fail 'char * color_prom' 'Uint8 * color_prom'
        substituteInPlace src/rom.c --replace-fail 'char* region' 'Uint8* region'
    '';
    sourceRoot = ".";
    buildInputs = [SDL_compat];
    makeFlags = [
        # Skip the top-level Makefile so we don't have to build the `package` target:
        "-f" "makefiles/Makefile.${whichPlatform}"
        # Normally the top-level Makefile sets this:
        "VERSION=$(version)"
    ];
    buildFlags = ["common"] ++ lib.optional stdenv.isDarwin ".bundle";
    installPhase = ''
        mkdir -p "$out"/bin
        ${if stdenv.isDarwin then ''
            mkdir -p "$out"/Applications
            cp -r Pacifi3d.app "$out"/Applications/Pacifi3d.app
            ln -s "$out"/Applications/Pacifi3d.app/Contents/MacOS/pacifi3d "$out"/bin/pacifi3d
        '' else ''
            cp pacifi3d "$out"/bin/pacifi3d
        ''}
    '';
    meta = {
        description = "Pac-Man emulator in 3D";
        longDescription = ''
            Pacifi3D is a proof-of-concept pacman emulator that replaces the original pacman sprites and tiles with OpenGL 3D graphics.
        '';
        homepage = "http://pacifi3d.retrogames.com/";
        platforms = with lib.platforms; linux ++ darwin;
        # No license explicitly specified. Credits seem to indicate some emulation code came from
        # MAME, which would have been under its old viral non-commercial license at the time.
        license = lib.licenses.unfree;
        maintainers = [maintainers.Rhys-T];
    };
}
