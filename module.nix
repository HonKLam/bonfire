self:
{ config, lib, options, pkgs, ... }:

let
  cfg = config.programs.bonfire;
  pkg = self.packages.${pkgs.system}.bonfire;
  backend = cfg.template.backend;

  # The same file the install script copies, so the two installation paths can
  # never render a different palette.
  templateText = builtins.readFile ./templates/bonfire.css;
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "programs" "bonfire" "noctaliaTemplate" ] ''
      programs.bonfire.noctaliaTemplate has been replaced by
      programs.bonfire.template.backend. Use "noctalia" (the default),
      "matugen", or "none".
    '')
  ];

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
        copied here from the Nix store on every service start, and the theming
        backend writes colors.css alongside them — which is why this cannot
        simply be the store path.
      '';
    };

    template.backend = lib.mkOption {
      type = lib.types.enum [ "noctalia" "matugen" "none" ];
      default = "noctalia";
      description = ''
        Which theming tool renders colors.css.

        "noctalia" writes the template and registers it with Noctalia, so the
        palette follows your wallpaper with no further setup.

        "matugen" only drops the template into ~/.config/matugen/templates/.
        Registering it under [templates.bonfire] is left to you, because
        bonfire cannot take ownership of a config.toml you already manage.

        "none" leaves the page on the colours from colors.default.css.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    ###################################################################
    # Palette template
    ###################################################################
    (lib.mkIf (backend == "noctalia") {
      xdg.configFile."noctalia/templates/bonfire.css".text = templateText;
    })

    (lib.mkIf (backend == "matugen") {
      xdg.configFile."matugen/templates/bonfire.css".text = templateText;
    })

    # Registering the template with Noctalia is guarded on `options`, not on
    # `config`: a definition under `programs.noctalia` counts as unmatched (and
    # so fails evaluation) for anyone who has not imported the Noctalia module,
    # even when it sits inside a `mkIf false`. `optionalAttrs` drops the whole
    # attribute path instead, which keeps bonfire usable without Noctalia.
    (lib.optionalAttrs (options.programs ? noctalia)
      (lib.mkIf (backend == "noctalia") {
        programs.noctalia.settings.theme.templates.user.bonfire = {
          input_path  = "${config.xdg.configHome}/noctalia/templates/bonfire.css";
          output_path = "${cfg.dataDir}/colors.css";
        };
      }))

    (lib.mkIf (backend == "noctalia") {
      warnings = lib.optional (!(options.programs ? noctalia)) ''
        programs.bonfire: template.backend is "noctalia" but the Noctalia
        home-manager module is not imported. The template was written to
        ${config.xdg.configHome}/noctalia/templates/bonfire.css but nothing
        registered it, so colors.css will never be rendered.
      '';
    })

    ###################################################################
    # Static server
    #
    # Firefox will not let an extension load a file:// URL, so the new-tab
    # override has to point at http. This serves the page on loopback only.
    ###################################################################
    {
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

            # index.html links colors.css unconditionally and the stylesheet has
            # no fallback values, so an unrendered palette means an unstyled
            # page. Seed it until the backend writes a real one.
            [ -f ${cfg.dataDir}/colors.css ] \
              || cp ${cfg.dataDir}/colors.default.css ${cfg.dataDir}/colors.css
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
    }
  ]);
}
