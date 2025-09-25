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
                      address = "192.168.100.1${toString i}";
                      prefixLength = 24;
                    }
                  ];
                  routes = [
                    {
                      address = "192.168.100.0";
                      prefixLength = 24;
                    }
                  ];
                };
                virtualisation = {
                  qemu.networkingOptions = lib.mkForce [
                    "-netdev user,id=mynet0,hostfwd=tcp::2222${toString i}-:22"
                    "-device virtio-net-pci,netdev=mynet0,mac=52:54:00:12:34:0${toString i}"
                    "-netdev socket,id=vlan,mcast=239.255.1.1:5558"
                    "-device virtio-net-pci,netdev=vlan,mac=52:54:00:56:78:0${toString i}"
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
