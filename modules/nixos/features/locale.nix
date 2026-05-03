{ config, pkgs, ... }:
{
  time.timeZone = "Asia/Ho_Chi_Minh";
  time.hardwareClockInLocalTime = false;

  i18n = {
    defaultLocale = "en_US.UTF-8"; # Default system locale (English US with UTF-8 encoding)

    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8"; # Address format
      LC_IDENTIFICATION = "en_US.UTF-8"; # Personal identification format
      LC_MEASUREMENT = "en_US.UTF-8"; # Measurement units (metric/imperial)
      LC_MONETARY = "en_US.UTF-8"; # Currency and money format
      LC_NAME = "en_US.UTF-8"; # Personal name format
      LC_NUMERIC = "en_US.UTF-8"; # Numeric format (decimal separator, etc.)
      LC_PAPER = "en_US.UTF-8"; # Paper size format
      LC_TELEPHONE = "en_US.UTF-8"; # Telephone number format
      LC_TIME = "en_US.UTF-8"; # Date and time format
    };
  };

  # === CONSOLE CONFIGURATION ===
  console = {
    font = "Lat2-Terminus16"; # Console font for TTY sessions
    useXkbConfig = true; # Use X11 keyboard configuration for console
  };
}
