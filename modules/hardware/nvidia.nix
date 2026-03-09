{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrValues;
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "NVIDIA GPU support";
    cuda.enable = mkEnableOption "CUDA toolkit support (pulls in CUDA dependencies)";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      hardware.graphics = {
        extraPackages = with pkgs; [
          libva-vdpau-driver    # VA-API ↔ VDPAU bridge (NVIDIA VDPAU backend)
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          libva-vdpau-driver
        ];
      };

      environment.systemPackages = with pkgs; [
        nvtopPackages.intel     # GPU monitor (CUDA-free)
      ];
    })

    (mkIf (cfg.enable && cfg.cuda.enable) {
      hardware.graphics = {
        extraPackages = with pkgs; [
          nvidia-vaapi-driver   # VA-API via NVIDIA (requires CUDA)
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          nvidia-vaapi-driver
        ];
      };

      environment.systemPackages = with pkgs; [
        cudatoolkit
        nvitop                 # CUDA-aware GPU monitor
      ];
    })
  ];
}
