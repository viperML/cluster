This is a simple project with nix to start a cluster of virtual machines using QEMU.

# Usage

To start the cluster, run:

```
nix run ./default.nix run
```

This will be a foreground process, so you might want to manage that.

To connect to the machines, you can use SSH.

```
ssh -p 22220 nixos@localhost # Connect to lab0
ssh -p 22221 nixos@localhost # Connect to lab1
```
