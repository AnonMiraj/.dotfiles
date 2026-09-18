# Nvidia GPU on the desktop host.
#
# PRIME render offload: the Intel iGPU (0:2:0) drives the display, the Nvidia
# dGPU (1:0:0) renders. The kernel parameters cover backlight control and DRM
# modesetting, which the proprietary driver needs to hand brightness over to
# the desktop.
{config, ...}: {
  services.xserver.videoDrivers = ["nvidia"];

  boot.kernelParams = [
    "acpi_backlight=native"
    "nvidia.NVreg_RegistryDwords=EnableBrightnessControl=1"
    "nvidia_drm.fbdev=1"
    "nvidia-drm.modeset=1"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
