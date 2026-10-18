
{
  writeShellApplication,
  coreutils,
  gawk,
  gnugrep,
  jq,
  fuzzel,
  libnotify,
  libqalculate,
  pinentry-gnome3,
  util-linux,
  wl-clipboard,
}:

writeShellApplication {
  name = "sysmenu";


  # Daemon clients (niri, nmcli, bluetoothctl, tlpctl, udisksctl, elephant, tray-host)
  # are intentionally NOT listed here: the script prepends runtimeInputs to PATH, which
  # would make every `have <tool>` check pass and turn the menu into a list of dead
  # entries on hosts that don't run that daemon.
  runtimeInputs = [
    coreutils
    gawk
    gnugrep
    jq
    fuzzel
    libnotify
    libqalculate
    pinentry-gnome3
    util-linux
    wl-clipboard
  ];

  # jq programs use $variables inside single quotes on purpose.
  excludeShellChecks = [ "SC2016" ];

  text = builtins.readFile ./sysmenu.sh;
}
