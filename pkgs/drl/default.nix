{ stdenvNoCC, lib, drl-unwrapped, drl-audio, drl-icon, drl-common, makeDesktopItem, copyDesktopItems, desktopToDarwinBundle, bash, coreutils, shellcheck }: let
    wrongAudioSuffix = if drl-audio.audioQuality == "hq" then "" else "hq";
in stdenvNoCC.mkDerivation {
    pname = "drl-${drl-audio.audioQuality}";
    inherit (drl-unwrapped) version;
    nativeBuildInputs = [copyDesktopItems] ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [desktopToDarwinBundle];
    dontUnpack = true;
    unwrapped = drl-unwrapped;
    audio = drl-audio;
    icon = drl-icon;
    inherit bash coreutils;
    desktopItems = [(makeDesktopItem {
        name = "drl";
        desktopName = "DRL";
        exec = "drl";
        icon = "drl";
        type = "Application";
        genericName = drl-unwrapped.meta.description;
        categories = [ "Game" ];
        keywords = [ "Game" ];
    })];
    installPhase = ''
        runHook preInstall
        shopt -s extglob
        mkdir -p "$out"/bin "$out"/share/drl
        ln -s \
            "$unwrapped"/share/drl/!(@(sound|music)${wrongAudioSuffix}.lua) \
            "$out"/share/drl/
        ${lib.optionalString (drl-audio.audioQuality == "hq") ''
            for file in sound music; do
                mv "$out/share/drl/''${file}hq.lua" "$out/share/drl/$file.lua"
            done
        ''}
        ln -s "$audio"/* "$out"/share/drl/
        ln -s "$icon"/share/icons "$out"/share/icons
        storePath="$NIX_STORE" substituteAll ${./drl.sh} "$out"/bin/drl
        chmod +x "$out"/bin/drl
        shopt -u extglob
        runHook postInstall
    '';
    installCheckPhase = ''
        runHook preInstallCheck
        ${lib.getExe shellcheck} "$out"/bin/drl
        runHook postInstallCheck
    '';
    doInstallCheck = true;
    meta = drl-common.meta // {
        description = "${drl-common.meta.description} (with ${if drl-audio.audioQuality == "hq" then "high" else "low"}-quality audio)";
        mainProgram = "drl";
    };
}
