let
  fkngoose = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEfUJxZSbiRrpeRkr3CD2DME5ZK45HJhYToAFZdetU2r";
in
{
  "rdp-pass.age".publicKeys = [ fkngoose ];
  "mail.json.age".publicKeys = [ fkngoose ];
  "mihomo.yaml.age".publicKeys = [ fkngoose ];
}
