{ options, config, lib, pkgs, ... }:

let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (pkgs) python3 writeScriptBin;
in {
  options.modules.shell.scripts.brightness =
    let inherit (lib.options) mkEnableOption;
    in { enable = mkEnableOption "brightness control"; };

  config = mkIf config.modules.shell.scripts.brightness.enable {
    # brightnessctl ships udev rules for non-root access (programs.light was removed)
    hardware.acpilight.enable = true;
    services.udev.packages = [ pkgs.brightnessctl ];

    user.packages = [
      (writeScriptBin "brightctl" ''
        #!${getExe python3}

        import argparse
        import subprocess

        parser = argparse.ArgumentParser(
            prog="Brightness Control",
            description="A simple script to help control the brightness levels of your environment!",
            epilog="Please, try again.",
        )

        subparser = parser.add_subparsers(dest="command")

        increase = subparser.add_parser("increase")
        decrease = subparser.add_parser("decrease")

        increase.add_argument(
            "-l",
            "--level",
            type=int,
            default=5,
            help="Increase brightness levels by +x%. (default: +%(default)%)",
        )

        decrease.add_argument(
            "-l",
            "--level",
            type=int,
            default=5,
            help="Decrease brightness levels by -x%. (default: -%(default)%)",
        )


        args = parser.parse_args()

        def get_level() -> str:
            cur = int(subprocess.check_output(["brightnessctl", "get"]).strip())
            top = int(subprocess.check_output(["brightnessctl", "max"]).strip())
            return str(round(cur * 100 / top))


        brightness_level = get_level()


        def notify(message):
            return subprocess.run(
                [
                    "notify-send",
                    message,
                    "-t",
                    "500",
                    "-h",
                    "string:synchronous:brightness",
                    "-h",
                    "int:value:" + brightness_level,
                    "-u",
                    "low",
                ]
            )


        def light(param: str):
            subprocess.run(["brightnessctl", "set", str(args.level) + "%" + param])


        def change_brightness():
            if args.command == "increase":
                ICON = "  "
                light("+")
            elif args.command == "decrease":
                ICON = "  "
                light("-")
            else:
                return

            notify(ICON + "Brightness: " + brightness_level + "%")


        change_brightness()
      '')
    ];
  };
}
