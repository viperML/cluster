{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) lib;

  machines = import ./machines.nix;

  nMachines =
    let
      n = lib.length (builtins.attrNames machines);
    in
    lib.throwIf (n > 256) "Too many machines" n;

  toHexPadded = number: lib.fixedWidthString 2 "0" (lib.toHexString number);

  ipFor = i: "192.168.100.${toString i}";

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
            lib.imap0 (j: name: lib.nameValuePair (ipFor j) ((lib.mkIf (i != j) [ name ]))) (
              builtins.attrNames machines
            )
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
                "-device virtio-net,netdev=mynet${toString i},mac=52:54:00:00:00:${toHexPadded i}"
                "-netdev user,id=mynet${toString i},hostfwd=tcp::${toString (22220 + i)}-:22"
              ]
              ++ (lib.optionals (nMachines > 1) [
                # Internal connection
                "-device virtio-net,netdev=net0,mac=52:54:00:00:01:${toHexPadded i}"
                "-netdev socket,id=net0,mcast=230.0.0.1:50821,localaddr=127.0.0.1"
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

  process-compose-config = (pkgs.formats.json { }).generate "process-compose.yml" {
    version = "0.5";
    processes = builtins.mapAttrs (name: nixos: {
      command = pkgs.writeShellScript "start-${name}" ''
        IMAGES_DIR="$PWD/images"
        mkdir -p "$IMAGES_DIR"
        export NIX_DISK_IMAGE="$IMAGES_DIR/${name}.qcow2"
        set -x
        exec ${lib.getExe nixos.config.system.build.vm}
      '';
    }) configs;
  };
in

{

  inherit configs process-compose-config pkgs;

  run = pkgs.writeShellScriptBin "run-cluster" ''
    export PATH='${
      lib.makeBinPath [
        pkgs.process-compose
        pkgs.bash
      ]
    }'
    exec process-compose -t=false -f ${process-compose-config}
  '';
}
