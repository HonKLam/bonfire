self:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.bonfire;
  pkg = self.packages.${pkgs.system}.bonfire;
in
{
  options.programs.bonfire = {
    enable = lib.mkEnableOption "the Bonfire start page";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8420;
      description = "Port the local static server listens on.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/bonfire";
      description = ''
        Writable directory the page is served from. The static files are
        copied here from the Nix store on every service start, and Noctalia
        writes colors.css alongside them — which is why this cannot simply
        be the store path.
      '';
    };

    noctaliaTemplate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Register the Noctalia user template that generates colors.css.";
    };
  };

  config = lib.mkIf cfg.enable {
    ###################################################################
    # Palette template
    ###################################################################
    xdg.configFile."noctalia/templates/bonfire.css" = lib.mkIf cfg.noctaliaTemplate {
      text = ''
        :root {
          --m-surface:            {{colors.surface.default.hex}};
          --m-surface-variant:    {{colors.surface_variant.default.hex}};
          --m-on-surface:         {{colors.on_surface.default.hex}};
          --m-on-surface-variant: {{colors.on_surface_variant.default.hex}};
          --m-primary:            {{colors.primary.default.hex}};
          --m-secondary:          {{colors.secondary.default.hex}};
          --m-tertiary:           {{colors.tertiary.default.hex}};
          --m-outline:            {{colors.outline.default.hex}};
        }
      '';
    };

    programs.noctalia.settings.theme.templates.user.bonfire =
      lib.mkIf cfg.noctaliaTemplate {
        input_path  = "${config.xdg.configHome}/noctalia/templates/bonfire.css";
        output_path = "${cfg.dataDir}/colors.css";
      };

    ###################################################################
    # Static server
    #
    # Firefox will not let an extension load a file:// URL, so the new-tab
    # override has to point at http. This serves the page on loopback only.
    ###################################################################
    systemd.user.services.bonfire = {
      Unit = {
        Description = "Bonfire start page";
        After = [ "graphical-session.target" ];
      };

      Service = {
        # Refresh the static files from the store, but never clobber the
        # generated colors.css.
        ExecStartPre = pkgs.writeShellScript "bonfire-sync" ''
          mkdir -p ${cfg.dataDir}
          ${pkgs.rsync}/bin/rsync -a --delete \
            --exclude colors.css \
            ${pkg}/ ${cfg.dataDir}/
          chmod -R u+w ${cfg.dataDir}
        '';

        ExecStart = ''
          ${pkgs.darkhttpd}/bin/darkhttpd ${cfg.dataDir} \
            --addr 127.0.0.1 \
            --port ${toString cfg.port} \
            --no-listing
        '';

        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
