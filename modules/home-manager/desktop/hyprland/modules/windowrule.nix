# ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗██████╗ ██╗   ██╗██╗     ███████╗
# ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔══██╗██║   ██║██║     ██╔════╝
# ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║██████╔╝██║   ██║██║     █████╗
# ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║██╔══██╗██║   ██║██║     ██╔══╝
# ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║╚██████╔╝███████╗███████╗
#  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
#------------------------------------------------------------------------------------
#
# Hyprland 0.55 Lua config (configType = "lua").
# settings.window_rule/layer_rule/workspace_rule each render to hl.<name>({...}).
# Match conditions live under `match`; `float`/`fullscreen` ARE valid match keys
# in Lua (unlike the hyprlang shim), so the floating-based rules work again.

{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ######## Workspace Rules ########
      workspace_rule = [
        { workspace = "special:special"; gaps_out = 15; }
      ];

      # ######## Window Rules ########
      window_rule = [
        # --- Disable Blur ---
        { match = { class = "^$"; title = "^$"; }; no_blur = true; }

        # --- Floating & Center (General) ---
        { match.title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|.*wants to save|.*wants to open)$"; float = true; }
        { match.title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|.*wants to save|.*wants to open)$"; center = true; }

        # --- Specific Sizes ---
        { match.title = "^(Choose wallpaper)$"; size = "60% 65%"; }
        { match.class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$"; float = true; }
        { match.class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$"; size = "60% 65%"; }

        # --- System Tools (Pavucontrol, Network, Bluetooth) ---
        { match.class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueberry\\.py|guifetch|bluedevilwizard)$"; float = true; }
        { match.class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|Zotero)$"; size = "45% 45%"; }
        { match.class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor)$"; center = true; }
        { match.class = "^(Zotero)$"; float = true; }

        # --- KDE Plasma Specifics ---
        { match.class = "^(plasma-changeicons|kcm_.*|.*plasmawindowed.*)$"; float = true; }
        { match.class = "^(plasma-changeicons)$"; move = "999999 999999"; }
        { match.class = "^(plasma-changeicons)$"; no_initial_focus = true; }
        { match.title = "^(.*Welcome|illogical-impulse Settings|.*Shell conflicts.*)$"; float = true; }
        { match.title = "^(Copying — Dolphin)$"; move = "40 80"; }

        # --- Tiling Overrides ---
        { match.class = "^(dev\\.warp\\.Warp)$"; tile = true; }

        # --- Picture-in-Picture (PiP) ---
        { match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"; float = true; }
        { match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"; keep_aspect_ratio = true; }
        { match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"; move = "73% 72%"; }
        { match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"; size = "25% 25%"; }
        { match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"; pin = true; }

        # --- Tearing & Games ---
        { match.title = ".*\\.exe"; immediate = true; }
        { match.title = ".*minecraft.*"; immediate = true; }
        { match.class = "^(steam_app).*"; immediate = true; }

        # --- Fix Jetbrains IDEs (float match regained in Lua) ---
        { match = { class = "^(jetbrains-.*)$"; float = true; title = "^($|^\\s$|^win\\d+$)"; }; no_initial_focus = true; }

        # --- No shadow for tiled windows (float = false, regained in Lua) ---
        { match.float = false; no_shadow = true; }

        # --- Force Tile for Browsers ---
        { match.class = "^(brave-browser)$"; tile = true; }

        # --- LiveCaptions ---
        { match.class = "^(net.sapples.LiveCaptions)$"; workspace = "silent"; }
        { match.class = "^(net.sapples.LiveCaptions)$"; pin = true; }
        { match.class = "^(net.sapples.LiveCaptions)$"; float = true; }
        { match.class = "^(net.sapples.LiveCaptions)$"; no_shadow = true; }
        { match.class = "^(net.sapples.LiveCaptions)$"; border_size = 0; }
        { match.class = "^(net.sapples.LiveCaptions)$"; rounding = 16; }
        { match.class = "^(net.sapples.LiveCaptions)$"; opacity = "1.0 0.85"; }
        { match.class = "^(net.sapples.LiveCaptions)$"; no_initial_focus = true; }

        { match.class = "^$"; stay_focused = true; }
      ];

      # ######## Layer Rules ########
      layer_rule = [
        # --- General ---
        { match.namespace = ".*"; xray = true; }
        { match.namespace = "^(walker|selection|overview|anyrun|indicator.*|osk|hyprpicker|noanim|gtk4-layer-shell)$"; no_anim = true; }
        { match.namespace = "^(logout_dialog)$"; blur = true; }

        # --- Blur & Opacity (General) ---
        { match.namespace = "^(gtk-layer-shell|launcher|notifications)$"; blur = true; }
        { match.namespace = "^(gtk-layer-shell)$"; ignore_alpha = 0; }
        { match.namespace = "^(launcher)$"; ignore_alpha = 0.5; }
        { match.namespace = "^(notifications)$"; ignore_alpha = 0.69; }

        # --- AGS / Bar / Dock ---
        { match.namespace = "^(session[0-9]*|bar[0-9]*|dock[0-9]*|overview[0-9]*|barcorner.*|cheatsheet[0-9]*|sideright[0-9]*|sideleft[0-9]*|indicator.*|osk[0-9]*)$"; blur = true; }
        { match.namespace = "^(bar[0-9]*|dock[0-9]*|overview[0-9]*|barcorner.*|cheatsheet[0-9]*|sideright[0-9]*|sideleft[0-9]*|indicator.*|osk[0-9]*)$"; ignore_alpha = 0.6; }

        # --- AGS Animations ---
        { match.namespace = "^(sideleft.*)$"; animation = "slide left"; }
        { match.namespace = "^(sideright.*)$"; animation = "slide right"; }

        # ######## Quickshell Rules ########
        { match.namespace = "^(quickshell:.*)$"; blur_popups = true; }
        { match.namespace = "^(quickshell:.*)$"; blur = true; }
        { match.namespace = "^(quickshell:.*)$"; ignore_alpha = 0.79; }

        { match.namespace = "^(quickshell:(bar|verticalBar|reloadPopup))$"; animation = "slide"; }
        { match.namespace = "^(quickshell:(cheatsheet|dock|osk))$"; animation = "slide bottom"; }
        { match.namespace = "^(quickshell:screenCorners)$"; animation = "popin 120%"; }
        { match.namespace = "^(quickshell:notificationPopup)$"; animation = "fade"; }
        { match.namespace = "^(quickshell:wallpaperSelector)$"; animation = "slide top"; }
        { match.namespace = "^(quickshell:sidebarRight)$"; animation = "slide right"; }
        { match.namespace = "^(quickshell:sidebarLeft)$"; animation = "slide left"; }

        { match.namespace = "^(quickshell:(actionCenter|lockWindowPusher|overlay|overview|polkit|regionSelector|screenshot|wNotificationCenter|wOnScreenDisplay|wStartMenu))$"; no_anim = true; }

        { match.namespace = "^(quickshell:session)$"; no_anim = true; }
        { match.namespace = "^(quickshell:session)$"; blur = true; }
        { match.namespace = "^(quickshell:session)$"; ignore_alpha = 0; }

        { match.namespace = "^(quickshell:wTaskView)$"; no_anim = true; }
        { match.namespace = "^(quickshell:wTaskView)$"; ignore_alpha = 0; }

        { match.namespace = "^(quickshell:(overlay|popup|mediaControls))$"; ignore_alpha = 1; }
        { match.namespace = "^(quickshell:popup)$"; xray = false; } # Fix weird color

        { match.namespace = "^(quickshell:osk)$"; order = -1; }
      ];
    };
  };
}
