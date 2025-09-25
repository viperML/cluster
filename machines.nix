let
  imports = [
    ./common.nix
  ];
in
{
  lab0 = {
    inherit imports;
    networking.hostName = "lab0";
  };

  lab1 = {
    inherit imports;
    networking.hostName = "lab1";
  };

  lab2 = {
    inherit imports;
    networking.hostName = "lab2";
  };
}
