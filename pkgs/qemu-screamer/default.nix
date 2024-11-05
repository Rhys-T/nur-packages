{ callPackage, lib }: let
    nixpkgs' = callPackage ./nixpkgs.nix {};
    qemuFn = import "${nixpkgs'}/pkgs/applications/virtualization/qemu";
    qemuScreamerFn = { fetchFromGitHub, maintainers, hostCpuTargets ? ["ppc-softmmu"], ... }@args: (qemuFn (builtins.removeAttrs args ["fetchFromGitHub" "maintainers"])).overrideAttrs (old: {
        pname = "${old.pname}-screamer";
        version = "7.1.94-unstable-2022-12-09";
        src = fetchFromGitHub {
            owner = "mcayland";
            repo = "qemu";
            rev = "448771a27001d867759c15cb5a505968182dbabc";
            fetchSubmodules = true;
            hash = "sha256-OCMNXjcQ/tJkakEmVX91HQhpxPhMPdp0m5/gu1Slxwk=";
        };
        preConfigure = builtins.replaceStrings ["shaderinclude.py"] ["shaderinclude.pl"] old.preConfigure;
        meta = old.meta // {
            description = "${old.meta.description} (mcayland's 'screamer' fork)";
            longDescription = ''
                ${old.meta.longDescription or old.meta.description}
                
                This is mcayland's 'screamer' fork, with flaky-but-functional support for the
                Screamer audio chip used in PowerPC Macintoshes. By default it will only build
                the `ppc-softmmu` target for qemu.
            '';
            homepage = "https://github.com/mcayland/qemu/tree/screamer";
            maintainers = [maintainers.Rhys-T];
        };
    });
in lib.setFunctionArgs qemuScreamerFn (lib.functionArgs qemuScreamerFn // lib.functionArgs qemuFn)
