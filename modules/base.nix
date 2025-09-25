# Some defaults you may want
{
  # Console not usable anyways, because of process-compose
  console.enable = false;

  services.openssh.enable = true;

  # sudo-capable nixos user
  users.users.nixos = {
    password = "nixos";
    isNormalUser = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      # Add your public key
    ];
    extraGroups = [ "wheel" ];
  };
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  # For testing purposes
  networking.firewall.enable = false;
}
