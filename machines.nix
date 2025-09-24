let

  shared = {
    services.openssh.enable = true;

    users.users.nixos = {
      isNormalUser = true;
      createHome = true;
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAxks+8Jg1PDy8W+4mPLN9G0LUYp5bscEk7MOm+WtzrlfQilflbY8BIbyvxNteGjxuO0u78YXCjJSYiZxQAkt9k= ayats hermes tpm2"
      ];
    };
  };

  imports = [ shared ];
in
{
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
