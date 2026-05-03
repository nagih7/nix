{
  config,
  pkgs,
  ...
}:

{
  virtualisation = {
    docker = {
      enable = true;

      # Automatic cleanup
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm; # Use KVM-enabled QEMU for better performance
        runAsRoot = false; # Run QEMU as unprivileged user (more secure)
        swtpm.enable = true; # Enable TPM emulation support
      };
      onBoot = "start"; # Start default libvirt networks on boot
      onShutdown = "shutdown"; # Gracefully shutdown VMs on host shutdown
    };

    # Shared memory for better VM performance
    spiceUSBRedirection.enable = true;
  };

  # Enable dnsmasq for libvirt default network
  virtualisation.libvirtd.extraConfig = ''
    unix_sock_group = "libvirtd"
    unix_sock_rw_perms = "0770"
  '';
}
