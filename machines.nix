let
  imports = [ shared ];
  shared =
    { config, pkgs, ... }:
    {
      services.openssh.enable = true;

      users.users.nixos = {
        isNormalUser = true;
        createHome = true;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyqWuElqeIjZyAEpp9se0+MrTlxSKIwPUh/ccmv60muXD8mCz0bOLKVwgmMjBVgPpt4ED8VqKkeX4NXzsvdiWueM1YEGgqVQSpZ9UqvEsob6ugZX3eWkGvcFShkCQcfcL0gVo2dCem/WefchAC0BWHT403QxnCRwfDQSKO5ipvdkru+zZZ7IHxvpvJVqjBtZ4KFiApbEokne2w1tMGXjaWifCw00gdUYTOgn5z0PILx12cLzLqh8Q64zeyl3v0ATtz2StQPJJNEPemHyfjQkRw4MsEjYnp7NnREDmUGjQ68DvAIbiqTzYPY2Ju7GtX3J7n0IvJpkfhNFM9z+z1p1Mh ayats BSC-8488104251 tpm2"
        ];
        extraGroups = [ "wheel" ];
      };

      networking.firewall.enable = false;

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = [
        pkgs.net-tools
        pkgs.tcpdump
        pkgs.python3
        pkgs.iptables
      ];

      services.caddy = {
        enable = true;
        virtualHosts.":80".extraConfig = ''
          respond "Hello World"
        '';
      };
    };

in
{
  lab0 =
    { config, pkgs, ... }:
    {
      inherit imports;
      networking.hostName = "lab0";
    };

  lab1 =
    { config, pkgs, ... }:
    {
      inherit imports;
      networking.hostName = "lab1";
    };

  lab2 =
    { config, pkgs, ... }:
    {
      inherit imports;
      networking.hostName = "lab2";
    };
}
