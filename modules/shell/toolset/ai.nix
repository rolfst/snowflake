{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;

  cfg = config.modules.shell.toolset.AI;
  configDir = config.snowflake.configDir;
  skillsDir = "${configDir}/opencode/skills";

  # Auto-discover all skill directories under config/opencode/skills/
  skillNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (
      if builtins.pathExists skillsDir then builtins.readDir skillsDir else { }
    )
  );

  # Generate xdg configFile entries for each discovered skill
  skillConfigFiles = builtins.listToAttrs (map (name: {
    name = "opencode-skill-${name}";
    value = {
      target = "opencode/skills/${name}/SKILL.md";
      source = "${skillsDir}/${name}/SKILL.md";
    };
  }) skillNames);
in
{
  options.modules.shell.toolset.AI =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Agentic AI code base helper";
    };

  config = mkIf cfg.enable {
    create.configFile = skillConfigFiles;

    environment.shellAliases = mkIf config.modules.desktop.terminal.kitty.enable {
      oc = "kitty @ launch --type=os-window --cwd=current opencode";
    };
  };
}
