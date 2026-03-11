let
  # User SSH public keys
  rolfst = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJHLsunCcBjVjEloFdYpaZpEg4qWiFdGTzbf8khn6nkB";

  # Host SSH public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  hp-zero = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMELMMnOgkgMfSmKrVUJb/NxFS1oSGG/zgM8+RWUC5+1";

  allKeys = [ rolfst hp-zero ];
in {
  "company-vpn.ovpn.age".publicKeys = allKeys;
  "private-tokens.age".publicKeys = allKeys;
}
