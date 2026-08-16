{
  config,
  pkgs,
  quickshell,
  ...
}:

{
  # === QUICKSHELL DEPENDENCIES CONFIGURATION ===
  home.packages = with pkgs; [
    # === CORE QUICKSHELL ===
    quickshell.packages.${pkgs.system}.default # QuickShell UI system

    # === KDE ===
    # AUDIO
    lxqt.pavucontrol-qt # PulseAudio volume control
    libdbusmenu-gtk3 # DBus menu for KDE

    # === KDE ===
    kdePackages.qtwayland # Wayland support for Qt
    kdePackages.qtpositioning # Location and positioning services
    kdePackages.qtlocation # Location services
    kdePackages.kdialog # Dialog utility
    kdePackages.syntax-highlighting # Syntax highlighting
    kdePackages.qt5compat # Qt5 compatibility layer
    kdePackages.bluedevil # Bluetooth management
    kdePackages.plasma-nm # NetworkManager integration
    kdePackages.polkit-kde-agent-1 # Polkit agent
    kdePackages.systemsettings # System settings
    kdePackages.kirigami # Kirigami framework for QML
    kdePackages.kirigami-addons # Additional Kirigami components
    kdePackages.kirigami # Kirigami2 for Qt5 compatibility

    # === QT6 FRAMEWORK ===
    qt6.qtbase
    qt6.qtwayland # Wayland support for Qt6
    qt6.qt5compat # Qt5 compatibility layer
    qt6.qtdeclarative # QML runtime and compiler
    qt6.qtsvg # SVG support
    qt6.qtimageformats # Additional image format support
    qt6.qtmultimedia # Multimedia support for media controls
    qt6.qtnetworkauth # Network authentication (for AI services)
    qt6.qtpositioning # Location and positioning services
    qt6.qtquicktimeline # QML timeline support
    qt6.qtvirtualkeyboard # Virtual keyboard support
    qt6.qttools # Qt development tools (includes qmllint)

    # === INPUT AUTOMATION ===
    ydotool # Input automation for Wayland

    # === AI SERVICES (OPTIONAL) ===
    ollama # Local AI models
    jq # JSON processor
    bc # Calculator (needed for switchwall.sh)
    libsecret # Needed for secret-tool (Gemini API)
    glib # Needed for gsettings
    gsettings-desktop-schemas # Fix "No schemas installed"
    gnome-keyring # Provide org.freedesktop.secrets

    # === WALLPAPER & THEMING ===
    awww # Wallpaper manager
    imagemagick # Image manipulation and identification
    zenity # File selection portal fallback

    # === WIDGETS & TOOLS ===
    wlogout # Logout menu
    swappy # Screenshot editor
    grim # Screenshot utility
    slurp # Area selection utility
    fuzzel # App launcher (fallback when quickshell IPC unavailable)
  ];
}
