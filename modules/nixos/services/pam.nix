{ ... }:

{
  # 1. Enable the GNOME Keyring daemon
  services.gnome.gnome-keyring.enable = true;

  # 2. Tell PAM to unlock the keyring using your login password
  security.pam.services.login.enableGnomeKeyring = true;

  # 3. Securely hook it up to your specific Display Manager (Greeter) if you use one
  # (Uncomment the line that matches what you use to log in)
  # security.pam.services.greetd.enableGnomeKeyring = true; 
  # security.pam.services.sddm.enableGnomeKeyring = true;
  # security.pam.services.gdm-password.enableGnomeKeyring = true;
}
