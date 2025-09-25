let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  machines = import ./machines.nix;

  json = pkgs.formats.json { };

  config = json.generate "process-compose.yml" {
    version = "0.5";
    log_level = "debug";

    processes = builtins.listToAttrs (
      lib.imap0 (
        i:
        { name, value }:
        let
          nixos = pkgs.nixos {
            imports = [
              {
                _file = ./machines.nix;
                imports = [ value ];
              }
              <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
              {
                networking.interfaces.eth1.ipv4 = {
                  addresses = [
                    {
                      address = "192.168.100.${toString (i + 10)}";
                      prefixLength = 24;
                    }
                  ];
                };
                networking.defaultGateway = null;
                virtualisation = {
                  qemu.networkingOptions = lib.mkForce [
                    # Forward SSH
                    "-netdev user,id=mynet${toString i},hostfwd=tcp::${toString (22220 + i)}-:22"
                    "-device virtio-net-pci,netdev=mynet${toString i},mac=52:54:00:12:34:0${toString i}"
                    # Internal connection
                    "-device e1000,netdev=intranet${toString i},mac=52:54:00:12:35:0${toString i}"
                    "-netdev socket,id=intranet${toString i},mcast=239.192.168.1:1102"
                  ];
                  sharedDirectories = lib.mkForce {
                    nix-store = {
                      source = builtins.storeDir;
                      target = "/nix/.ro-store";
                      securityModel = "none";
                    };
                  };
                  graphics = false;
                };
              }
            ];
          };
        in
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
                set -x
                exec ${lib.getExe nixos.config.system.build.vm}
              '';
            }
          );
        }
      ) (lib.attrsToList machines)
    );
  };
in

{
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
