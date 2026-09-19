# Shared view of the home LAN. Imported by `modules/shared.nix`, so both hosts
# (and only those) get these options; the VPS needs the address/subnet for the
# Headscale ACL and split DNS, the desktop needs the interface for dnsmasq.
{
  config,
  lib,
  ...
}: {
  options.my.lan = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "lab.almiraj.xyz";
      description = "Internal split-brain DNS zone. Services get <name>.<lan.domain>; the same names resolve to my.lan.address on the LAN and are covered by the Let's Encrypt wildcard cert from modules/selfhost/acme.nix.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.6";
      description = "LAN IP of the home host, advertised by dnsmasq for <lan.domain>.";
    };
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["enp43s0"];
      description = "LAN interfaces dnsmasq binds to (in addition to lo) and that the tailnet may forward to.";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      default = let
        parts = lib.splitString "." config.my.lan.address;
      in "${lib.concatStringsSep "." (lib.take 3 parts)}.0/24";
      defaultText = "IPv4 /24 derived from my.lan.address";
      description = "IPv4 /24 subnet of my.lan.address, advertised over the tailnet and allowed by the Headscale ACL.";
    };

    headscale.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Join the Headscale tailnet and advertise my.lan.subnet.";
    };
  };
}
