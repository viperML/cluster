let
  common =
    { config, pkgs, ... }:
    {
      # Example, run caddy on every machine
      #  Try with: curl {lab0,lab1,lab2}
      services.caddy = {
        enable = true;
        virtualHosts.":80".extraConfig = ''
          handle {
            respond "Hello from ${config.networking.hostName}"
          }
        '';
      };
    };

  imports = [
    common
    ./modules/base.nix
  ];
in
{
  lab0 = {lib, ...}: {
    inherit imports;

    # Per-host configuration
    #  Try with: curl lab0/goodbye
    services.caddy.virtualHosts.":80".extraConfig = lib.mkBefore ''
      handle /goodbye {
        respond "Goodbye!"
      }
    '';
  };

  lab1 = {
    inherit imports;
  };

  lab2 = {
    inherit imports;
  };
}
