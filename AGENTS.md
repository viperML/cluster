This is a simple project with nix to start a cluster of virtual machines using QEMU.

# Usage

To start the cluster in the background, run:

```
nix run -f ./default.nix run &
```

Remember to run `pkill -f process-compose` to kill it if needed.

To connect to the machines, you can use SSH.

```
ssh -p 22220 nixos@localhost # Connect to lab0
ssh -p 22221 nixos@localhost # Connect to lab1
```

You may use sudo to run commands as root.
