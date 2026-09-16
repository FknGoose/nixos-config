{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./audio.nix
    ./core.nix
    ./desktop.nix
    ./network.nix
  ];
}
