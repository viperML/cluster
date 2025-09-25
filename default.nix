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

          virtualisation = {

            sharedDirectories = lib.mkForce {
              nix-store = {
                source = builtins.storeDir;
                target = "/nix/.ro-store";
                securityModel = "none";
              };
            };

            graphics = false;

            # qemu.options = [
            #   "-device usb-net,netdev=net0"
            #   "-netdev user,id=net0,hostfwd=tcp::2222-:22"
            # ];
          };
        }
      ];
    }
  ) machines;

  json = pkgs.formats.json { };

  config = json.generate "process-compose.yml" {
    version = "0.5";
    log_level = "debug";

    processes = builtins.listToAttrs (
      lib.imap0 (
        i:
        { name, value }:
        lib.nameValuePair name {
          command = lib.getExe (
            pkgs.writeShellApplication {
              name = "command";
              runtimeInputs = [ pkgs.coreutils ];
              inheritPath = false;
              text = ''
                IMAGES_DIR="$PWD/images"
                mkdir -p "$IMAGES_DIR"
                export NIX_DISK_IMAGE="$IMAGES_DIR/${name}.qcow2"
                export QEMU_NET_OPTS="hostfwd=tcp::2222${toString i}-:22"
                export QEMU_OPTS="-net nic,model=virtio -net socket,mcast=230.0.0.1:1234"
                set -x
                exec ${lib.getExe value.config.system.build.vm}
              '';
            }
          );
        }
      ) (lib.attrsToList all-nixos)
    );
  };
in

{
  inherit all-nixos;
  inherit config;
  inherit pkgs;

  run = pkgs.writeShellApplication {
    name = "run";
    runtimeInputs = [
      pkgs.process-compose
      pkgs.bash
    ];
    inheritPath = false;
    text = ''
      process-compose -t=false -f ${config}
    '';
  };
}
