{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) lib;

  machines = import ./machines.nix;

  json = pkgs.formats.json { };

  nMachines = lib.length (builtins.attrNames machines);

  toHexPadded = number: lib.fixedWidthString 2 "0" (lib.toHexString number);

  ipFor = i: "192.168.100.${toString (i + 10)}";

  configs = builtins.listToAttrs (
    lib.imap0 (
      i:
      { name, value }:
      lib.nameValuePair name (
        pkgs.nixos {
          imports = [
            {
              _file = ./machines.nix;
              imports = [ value ];
            }
            (pkgs.path + /nixos/modules/virtualisation/qemu-vm.nix)
          ];
          networking.hostName = lib.mkForce name;
          networking.hosts = builtins.listToAttrs (
            lib.imap0 (j: name: lib.nameValuePair (ipFor j) [ name ]) (builtins.attrNames machines)
          );
          networking.interfaces.eth1.ipv4 = {
            addresses = [
              {
                address = ipFor i;
                prefixLength = 24;
              }
            ];
          };
          networking.defaultGateway = null;
          virtualisation = {
            qemu.networkingOptions = lib.mkForce (
              [
                # Forward SSH
                "-device virtio-net,netdev=mynet${toString i},mac=52:54:00:12:34:${toHexPadded i}"
                "-netdev user,id=mynet${toString i},hostfwd=tcp::${toString (22220 + i)}-:22"
              ]
              ++ (lib.optionals (nMachines > 1) [
                # Internal connection
                "-device virtio-net,netdev=net0,mac=52:54:00:12:35:${toHexPadded i}"
                "-netdev socket,id=net0,mcast=230.0.0.1:1234,localaddr=127.0.0.1"
              ])
            );
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
      )
    ) (lib.attrsToList machines)
  );

  process-compose-config = json.generate "process-compose.yml" {
    version = "0.5";
    processes = builtins.mapAttrs (name: nixos: {
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
    }) configs;
  };
in

{

  inherit configs process-compose-config pkgs;

  run = pkgs.writeShellApplication {
    name = "run";
    runtimeInputs = [
      pkgs.process-compose
      pkgs.bash
    ];
    inheritPath = false;
    text = ''
      process-compose -t=false -f ${process-compose-config}
    '';
  };
}
