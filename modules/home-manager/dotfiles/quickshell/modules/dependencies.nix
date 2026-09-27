{ pkgs, ... }:

{
  # Runtime dependencies of the ii shell and the Hyprland session tools it
  # shells out to. The quickshell binary itself is installed (wrapped) by
  # ../default.nix.
  home.packages = with pkgs; [
    # === QT / KDE RUNTIME ===
    kdePackages.qtwayland
    kdePackages.qtpositioning
    kdePackages.qtlocation
    kdePackages.syntax-highlighting
    kdePackages.qt5compat
    kdePackages.bluedevil # Bluetooth management
    kdePackages.plasma-nm # NetworkManager integration
    kdePackages.systemsettings
    kdePackages.kirigami
    kdePackages.kirigami-addons
    qt6.qtbase
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtimageformats
    qt6.qtmultimedia
    qt6.qtnetworkauth
    qt6.qtpositioning
    qt6.qtquicktimeline
    qt6.qtvirtualkeyboard
    qt6.qttools # qmllint
    libdbusmenu-gtk3

    # === HYPRLAND / WAYLAND TOOLS ===
    hyprpicker
    hyprcursor
    hyprsome
    hyprshot
    grim # screenshot
    slurp # region select
    swappy # screenshot editor
    wf-recorder # screen recording
    wtype
    ydotool # input automation (daemon in services.nix)
    cliphist # clipboard history (watcher in services.nix)
    wl-clipboard
    brightnessctl
    ddcutil # DDC/CI monitor control
    playerctl
    pamixer
    lxqt.pavucontrol-qt
    wdisplays
    wlogout
    fuzzel # fallback launcher when quickshell IPC is unavailable
    nwg-look

    # === THEMING ===
    awww # wallpaper daemon
    imagemagick
    zenity # file selection portal fallback
    glib # gsettings
    gsettings-desktop-schemas
    libsecret # secret-tool (Gemini API key)

    # === MISC SHELL HELPERS ===
    jq
    bc # switchwall.sh
    tesseract # OCR
    ffmpeg
    cheese # webcam
    ollama # local AI models (service in services.nix)
  ];
}
