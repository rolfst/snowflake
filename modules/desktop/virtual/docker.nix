{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.virtualize.docker;
  userName = config.user.name;
  userHome = config.user.home;
in
{
  options.modules.virtualize.docker =
    let
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) attrsOf nullOr str submodule;
    in
    {
      enable = mkEnableOption "container manipulation";
      daemonSettings = mkEnableOption "daemon settings";

      tokenSecretPath = mkOption {
        type = nullOr str;
        default = null;
        description = "Path to the agenix-decrypted file containing registry tokens (e.g. config.age.secrets.\"private-tokens\".path). Each token is stored as key=value.";
      };

      registries = mkOption {
        type = attrsOf (submodule {
          options = {
            email = mkOption {
              type = str;
              description = "Email address for Docker registry authentication.";
            };
            tokenKey = mkOption {
              type = str;
              description = "Key prefix to extract the pre-encoded auth token from the shared secret file (e.g. 'jfrog' extracts from 'jfrog=<token>').";
            };
          };
        });
        default = { };
        description = "Docker registries to authenticate with. The attribute name is the registry URL. Generates ~/.config/docker/config.json when non-empty.";
        example = {
          "dhlparcel.pe.jfrog.io" = {
            email = "user@company.com";
            tokenKey = "jfrog";
          };
        };
      };
    };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = attrValues { inherit (pkgs) docker docker-compose; };

      home.sessionVariables = {
        DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
        MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";
      };

      user.extraGroups = [ "docker" ];

      virtualisation = {
        docker = {
          enable = true;
          autoPrune.enable = true;
          enableOnBoot = false;
          daemon = mkIf cfg.daemonSettings {
            settings = {
              bip = "172.26.0.1/16";
            };
          };

          # listenOptions = [];
        };
      };
    }

    (mkIf (cfg.registries != { }) {
      assertions = [
        {
          assertion = cfg.tokenSecretPath != null;
          message = "modules.virtualize.docker.tokenSecretPath must be set when registries are configured.";
        }
      ];

      system.activationScripts.docker-registry-auth = {
        text = let
          grep = "${pkgs.gnugrep}/bin/grep";
          jq = "${pkgs.jq}/bin/jq";
          chmod = "${pkgs.coreutils}/bin/chmod";
          chown = "${pkgs.coreutils}/bin/chown";

          # Build a jq filter that constructs the auths object from all registries.
          # For each registry, we extract its token and add it to the JSON.
          registryEntries = lib.attrsets.mapAttrsToList (url: reg: {
            inherit url;
            inherit (reg) email tokenKey;
          }) cfg.registries;

          # Generate shell script lines that extract each token and build jq args
          extractTokens = lib.concatStringsSep "\n" (lib.imap0 (i: entry: ''
            TOKEN_${toString i}=$(${grep} -oP '^${entry.tokenKey}=\K[^#]*' "${cfg.tokenSecretPath}" | head -1 | xargs)
          '') registryEntries);

          # Generate jq --arg pairs for all registries
          jqArgs = lib.concatStringsSep " \\\n    " (lib.imap0 (i: entry:
            ''--arg auth_${toString i} "$TOKEN_${toString i}" --arg email_${toString i} "${entry.email}" --arg url_${toString i} "${entry.url}"''
          ) registryEntries);

          # Generate jq expression that builds the auths object
          jqAuthEntries = lib.concatStringsSep " + " (lib.imap0 (i: _entry:
            ''{ ($url_${toString i}): { auth: $auth_${toString i}, email: $email_${toString i} } }''
          ) registryEntries);

          jqFilter = ''{ auths: (${jqAuthEntries}) }'';

          # Generate token presence check (all tokens must be non-empty)
          tokenChecks = lib.concatStringsSep " && " (lib.imap0 (i: _entry:
            ''[ -n "$TOKEN_${toString i}" ]''
          ) registryEntries);
        in ''
          DOCKER_CONFIG_DIR="${userHome}/.config/docker"
          DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/config.json"

          mkdir -p "$DOCKER_CONFIG_DIR"

          ${extractTokens}

          if ${tokenChecks}; then
            ${jq} -n \
              ${jqArgs} \
              '${jqFilter}' \
              > "$DOCKER_CONFIG_FILE"

            ${chmod} 600 "$DOCKER_CONFIG_FILE"
            ${chown} ${userName}:users "$DOCKER_CONFIG_FILE"
          fi
        '';
        deps = [ "agenix" ];
      };
    })
  ]);
}
