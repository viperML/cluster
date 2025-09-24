let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  machines = import ./machines.nix;

  all-nixos = builtins.mapAttrs (
    _: config:
    pkgs.nixos {
      imports = [
        {
          _file = ./machines.nix;
          imports = [ config ];
        }
        <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
        {
          virtualisation.sharedDirectories = lib.mkForce {
            nix-store = {
              source = builtins.storeDir;
              target = "/nix/.ro-store";
              securityModel = "none";
            };
          };
          virtualisation.graphics = false;
        }
      ];
    }
  ) machines;

  json = pkgs.formats.json { };
  config = json.generate "process-compose.yml" {
    version = "0.5";
    log_level = "debug";
    processes = builtins.mapAttrs (name: nixos: {
      command = pkgs.writeShellScript "run-${name}" ''
        set -x
        IMAGES_DIR="$PWD/images"
        mkdir -p "$IMAGES_DIR"
        export NIX_DISK_IMAGE="$IMAGES_DIR/${name}.qcow2"
        exec ${lib.getExe nixos.config.system.build.vm}
      '';

    }) all-nixos;
  };
in

{
  inherit all-nixos;
  inherit config;
  inherit pkgs;

  run = pkgs.writeShellScriptBin "run" ''
    ${lib.getExe pkgs.process-compose}
  '';
}
