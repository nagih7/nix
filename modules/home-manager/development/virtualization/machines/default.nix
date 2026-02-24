{
  config,
  pkgs,
  hostVars,
  ...
}:

{
  home.packages = with pkgs; [
    qemu          # Generic and open source machine emulator and virtualizer
    libvirt       # API for managing platform virtualization
    virtiofsd     # Virtio Filesystem Daemon for shared folder support
    virt-manager  # Desktop user interface for managing virtual machines
    libguestfs    # Tools for accessing and modifying virtual machine disk images
  ];
}
