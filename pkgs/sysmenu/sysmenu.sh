readonly TAB=$'\t'

readonly EL_BLUETOOTH=bluetooth
readonly EL_SYMBOLS=symbols
readonly EL_CALC=calc

have() { command -v -- "$1" >/dev/null 2>&1; }

# nmcli & co. translate their output ("enabled" -> "включено"), which breaks parsing.
# Applied per call, not globally: fuzzel needs the user locale for non-ASCII input.
lc() { LC_ALL=C "$@"; }


notify() {
  notify-send -a sysmenu -t 4000 -- "$1" "${2:-}" 2>/dev/null ||
    printf '%s: %s\n' "$1" "${2:-}" >&2
}

# Successes are silent by default: the menu closing is the feedback. Failures always
# notify, because sysmenu runs without a terminal and stderr would be lost.
say() {
  if [ "${SYSMENU_NOTIFY:-0}" = 1 ]; then notify "$@"; fi
}

finish() {
  if [ $# -gt 0 ]; then say "$@"; fi
  exit 0
}

try() {
  local out
  if out=$("$@" 2>&1); then
    printf '%s' "$out"
    return 0
  fi
  notify "Failed: ${*:1:2}" "$(tail -n 3 <<<"$out")"
  return 1
}

# For probes whose failure is expected, e.g. a profile that has no stored secret yet.
quiet() { "$@" >/dev/null 2>&1; }
pick() {
  fuzzel --dmenu --prompt "$1 " --with-nth 2 --accept-nth 1 --lines 12 --minimal-lines
}

menu() {
  local prompt=$1
  shift
  printf '%s\t%s\n' "$@" | pick "$prompt"
}

ask() {
  local prompt=$1
  shift
  fuzzel --dmenu --prompt-only "$prompt " "$@" </dev/null
}

dot() { if [ "$1" = 1 ]; then printf '●'; else printf '○'; fi; }

# ───────────────────────────────────────────── Wi-Fi ──

wifi_active_uuid() {
  lc nmcli -t -f UUID,TYPE connection show --active |
    awk -F: '$2 == "802-11-wireless" && !done { print $1; done = 1 }'
}

# pinentry speaks Assuan over stdin/stdout; the secret arrives as a "D " data line,
# percent-escaped. It never reaches argv or the environment.
pinentry_get() {
  local out
  out=$(printf 'SETPROMPT %s\nGETPIN\nBYE\n' "$1" | pinentry-gnome3 2>/dev/null) || return 1
  awk '
    /^D /  { printf "%s", substr($0, 3); next }
    /^\+ / { printf "%s", substr($0, 3); next }
    /^OK/  { exit }
  ' <<<"$out" | sed -e 's/%0A/\n/g; s/%0D/\r/g; s/%25/%/g'
}

wifi_connect() {
  local ssid=$1 security=$2
  local open=no
  case $security in "" | "--") open=yes ;; esac

  if [ "$open" = no ] && [[ $security == *802.1X* ]]; then
    notify "Wi-Fi" "Enterprise network: use the NetworkManager applet from the tray"
    return 0
  fi

  # A stored profile is enough for open networks and for networks whose secret
  # NetworkManager already saved.
  if lc nmcli -t -f NAME connection show | grep -xF -- "$ssid" >/dev/null; then
    if quiet nmcli connection up id "$ssid"; then
      finish "Wi-Fi" "Connected to $ssid"
    fi
  fi

  if [ "$open" = yes ]; then
    if try nmcli device wifi connect "$ssid" >/dev/null; then
      finish "Wi-Fi" "Connected to $ssid"
    fi
    return 0
  fi

  # No usable profile: let NetworkManager create one (it derives the security settings
  # from the AP), then activate it with the secret supplied out of band.
  quiet nmcli device wifi connect "$ssid" || :

  local passfile pass out
  passfile=$(mktemp -p /dev/shm sysmenu-wifi.XXXXXX) || return 0
  chmod 600 "$passfile"
  pass=$(pinentry_get "Password for $ssid:") || pass=""
  if [ -z "$pass" ]; then
    rm -f "$passfile"
    return 0
  fi
  printf '802-11-wireless-security.psk:%s\n' "$pass" >"$passfile"
  unset pass

  if out=$(nmcli connection up id "$ssid" passwd-file "$passfile" 2>&1); then
    rm -f "$passfile"
    finish "Wi-Fi" "Connected to $ssid"
  fi
  rm -f "$passfile"
  # A failed attempt still leaves a profile behind, and NetworkManager would silently
  # reuse it next time instead of asking for the password again.
  quiet nmcli connection delete id "$ssid" || :
  notify "Wi-Fi" "$(tail -n 3 <<<"$out")"
}


wifi_menu() {
  local rescan=no
  while :; do
    local choice
    if [ "$(lc nmcli -t radio wifi)" != enabled ]; then
      choice=$(menu "Wi-Fi: off" on "Turn Wi-Fi on") || return 0
      if [ "$choice" = on ]; then try nmcli radio wifi on >/dev/null || :; fi
      continue
    fi

    local -A signal=() security=() inuse=()
    local use sig sec ssid
    # SSID is the last field: it may contain ':' (escaped as '\:'), so it takes the rest.
    while IFS=: read -r use sig sec ssid; do
      ssid=${ssid//\\:/:}
      ssid=${ssid//$TAB/ }
      if [ -z "$ssid" ]; then continue; fi
      if [ "$sec" = "--" ]; then sec=""; fi
      if [ "$use" = '*' ]; then inuse[$ssid]=1; fi
      if [ -z "${signal[$ssid]:-}" ] || [ "$sig" -gt "${signal[$ssid]}" ]; then
        signal[$ssid]=$sig
        security[$ssid]=$sec
      fi
    done < <(lc nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan "$rescan" 2>/dev/null)
    rescan=no

    local -a entries=()
    local name
    while IFS=$TAB read -r _ name; do
      entries+=("net:$name" "$(dot "${inuse[$name]:-0}") $name   ${signal[$name]}%   ${security[$name]:-open}")
    done < <(for name in "${!signal[@]}"; do printf '%s\t%s\n' "${signal[$name]}" "$name"; done |
      sort -t "$TAB" -k1,1nr)
    entries+=(rescan "Rescan" off "Turn Wi-Fi off")

    choice=$(menu "Wi-Fi" "${entries[@]}") || return 0
    case $choice in
      rescan) rescan=yes ;;
      off) try nmcli radio wifi off >/dev/null || : ;;
      net:*)
        ssid=${choice#net:}
        if [ -n "${inuse[$ssid]:-}" ]; then
          local uuid
          uuid=$(wifi_active_uuid) || uuid=""
          if [ -n "$uuid" ] && try nmcli connection down uuid "$uuid" >/dev/null; then
            finish "Wi-Fi" "Disconnected from $ssid"
          fi
        else
          wifi_connect "$ssid" "${security[$ssid]:-}"
        fi
        ;;
    esac
  done
}

# ─────────────────────────────────────────── Elephant ──

el_items() {
  local raw
  raw=$(timeout 3 elephant query --json "$1;$2;$3;false" 2>/dev/null) || return 1
  # Don't depend on the exact envelope of `query --json`: collect every object with an identifier.
  jq -cs '[.. | objects | select(has("identifier"))]' <<<"$raw"
}

el_pick() {
  local prompt=$1 items=$2 index
  index=$(jq -r '
      to_entries[]
      | [ (.key | tostring),
          ((.value.text // .value.identifier | tostring)
           + (if (.value.subtext // "") != "" then "   " + .value.subtext else "" end)
           | gsub("[\t\n]"; " ")) ]
      | @tsv' <<<"$items" | pick "$prompt") || return 1
  if ! [[ $index =~ ^[0-9]+$ ]]; then return 1; fi
  jq -c --argjson i "$index" '.[$i]' <<<"$items"
}

el_activate() {
  local id
  id=$(jq -r '.identifier | tostring' <<<"$2")
  try elephant activate "$1;$id;$3;${4:-};" >/dev/null
}

bluetooth_menu() {
  while :; do
    local items item
    if ! items=$(el_items "$EL_BLUETOOTH" "" 200); then
      notify "Bluetooth" "Elephant is not responding"
      return 0
    fi
    if [ "$(jq length <<<"$items")" -eq 0 ]; then
      notify "Bluetooth" "No devices"
      return 0
    fi
    item=$(el_pick "Bluetooth" "$items") || return 0

    local -a actions=() entries=()
    local a action device
    mapfile -t actions < <(jq -r '.actions // [] | .[]' <<<"$item")
    for a in "${actions[@]}"; do entries+=("$a" "${a^}"); done
    if [ "${#entries[@]}" -eq 0 ]; then
      notify "Bluetooth" "No actions available for this device"
      continue
    fi
    device=$(jq -r '.text // .identifier | tostring' <<<"$item")
    action=$(menu "$device" "${entries[@]}") || continue
    if el_activate "$EL_BLUETOOTH" "$item" "$action"; then
      finish "Bluetooth" "${action^}: $device"
    fi
  done
}

symbols_menu() {
  local items item action
  # fuzzel does the filtering, so fetch the whole list up front.
  if ! items=$(el_items "$EL_SYMBOLS" "" 100000); then
    notify "Symbols" "Elephant is not responding"
    return 0
  fi
  item=$(el_pick "Symbols" "$items") || return 0
  action=$(jq -r '(.actions // [])[0] // "copy"' <<<"$item")
  if el_activate "$EL_SYMBOLS" "$item" "$action"; then finish; fi
}

calc_eval() {
  local items
  items=$(el_items "$EL_CALC" "$1" 1) || return 1
  jq -r '.[0].text // empty' <<<"$items"
}

calc_menu() {
  local expr result
  while :; do
    expr=$(ask "=") || return 0
    if [ -z "$expr" ]; then return 0; fi
    if result=$(calc_eval "$expr") && [ -n "$result" ]; then
      printf '%s' "$result" | wl-copy
      finish "$expr = $result" "Copied to clipboard"
    fi
    notify "Calculator" "Cannot evaluate: $expr"
  done
}

# ───────────────────────────────────────────── Power ──

battery() {
  local d
  for d in /sys/class/power_supply/BAT*; do
    if [ -d "$d" ]; then
      printf '%s' "$d"
      return 0
    fi
  done
  return 1
}

sysval() { if [ -r "$1" ]; then cat -- "$1" 2>/dev/null || :; fi; }


power_menu() {
  if ! have tlpctl; then
    notify "Power" "tlpctl not found (enable services.tlp.pd)"
    return 0
  fi
  while :; do
    local current bat prompt
    current=$(lc tlpctl get 2>/dev/null) || current="?"
    prompt="Power: $current"
    if bat=$(battery); then
      local capacity status start stop
      capacity=$(sysval "$bat/capacity")
      status=$(sysval "$bat/status")
      start=$(sysval "$bat/charge_control_start_threshold")
      stop=$(sysval "$bat/charge_control_end_threshold")
      prompt+=" · ${capacity:-?}% ${status,,}"
      if [ -n "$stop" ]; then prompt+=" · limit ${start:-0}–${stop}%"; fi
    fi

    local -a entries=()
    local id label on
    for id in performance balanced power-saver; do
      case $id in
        performance) label="Performance" ;;
        balanced) label="Balanced" ;;
        *) label="Power saver" ;;
      esac
      on=0
      if [ "$id" = "$current" ]; then on=1; fi
      entries+=("$id" "$(dot "$on") $label")
    done

    local choice
    choice=$(menu "$prompt" "${entries[@]}") || return 0
    if try tlpctl set "$choice" >/dev/null; then
      finish "Power" "Profile: $choice"
    fi
  done
}

# ─────────────────────────────────────────── Displays ──

output_menu() {
  local out=$1
  while :; do
    local json
    json=$(niri msg --json outputs 2>/dev/null) || return 0

    local enabled scale active_count
    enabled=$(jq -r --arg o "$out" 'if .[$o].logical then 1 else 0 end' <<<"$json")
    scale=$(jq -r --arg o "$out" '.[$o].logical.scale // "-" | tostring' <<<"$json")
    active_count=$(jq '[.[] | select(.logical)] | length' <<<"$json")

    local -a entries=()
    if [ "$enabled" = 1 ]; then entries+=(off "Turn off"); else entries+=(on "Turn on"); fi

    local s on t mode current
    for s in 1 1.25 1.5 1.75 2; do
      on=0
      if [ "$s" = "$scale" ]; then on=1; fi
      entries+=("scale:$s" "$(dot "$on") Scale ×$s")
    done
    for t in normal 90 180 270; do entries+=("transform:$t" "Rotation: $t"); done
    # niri reports refresh in mHz but expects WxH@Hz with three decimals.
    while IFS=$TAB read -r mode current; do
      entries+=("mode:$mode" "$(dot "$current") Mode ${mode/@/ @ } Hz")
    done < <(jq -r --arg o "$out" '
        .[$o] | .current_mode as $c | .modes | to_entries[]
        | [.value.width, .value.height, .value.refresh_rate, (if .key == $c then 1 else 0 end)]
        | @tsv' <<<"$json" |
      awk -F'\t' '{ printf "%dx%d@%.3f\t%d\n", $1, $2, $3 / 1000, $4 }')

    local choice
    choice=$(menu "Display $out" "${entries[@]}") || return 0
    case $choice in
      off)
        # Turning off the last active output leaves a black screen with no way back but a TTY.
        if [ "$active_count" -le 1 ]; then
          notify "Displays" "Refusing to turn off the last active output"
          continue
        fi
        try niri msg output "$out" off >/dev/null || :
        ;;
      on) try niri msg output "$out" on >/dev/null || : ;;
      scale:*) try niri msg output "$out" scale "${choice#scale:}" >/dev/null || : ;;
      transform:*) try niri msg output "$out" transform "${choice#transform:}" >/dev/null || : ;;
      mode:*) try niri msg output "$out" mode "${choice#mode:}" >/dev/null || : ;;
    esac
  done
}

display_menu() {
  if ! have niri; then
    notify "Displays" "niri not found"
    return 0
  fi
  while :; do
    local json
    if ! json=$(niri msg --json outputs 2>/dev/null); then
      notify "Displays" "Cannot talk to niri"
      return 0
    fi
    local -a entries=()
    local name model on scale
    while IFS=$TAB read -r name model on scale; do
      entries+=("$name" "$(dot "$on") $name   $model   ×$scale")
    done < <(jq -r '
        to_entries[]
        | [ .key,
            ("\(.value.make // "") \(.value.model // "")"),
            (if .value.logical then "1" else "0" end),
            (.value.logical.scale // "-" | tostring) ]
        | @tsv' <<<"$json")

    if [ "${#entries[@]}" -eq 2 ]; then
      output_menu "${entries[0]}"
      return 0
    fi
    local choice
    choice=$(menu "Displays" "${entries[@]}") || return 0
    output_menu "$choice"
  done
}

# ───────────────────────────────────── Removable drives ──

disks_menu() {
  local -a entries=()
  local path size label mounted
  # Partitions don't report TRAN/RM themselves, so inherit them from the parent disk;
  # otherwise USB hard drives (RM=0) never show up.
  while IFS=$TAB read -r path size label mounted; do
    if [ "$mounted" = 1 ]; then
      entries+=("unmount:$path" "Unmount   $path   $size   $label")
    else
      entries+=("mount:$path" "Mount   $path   $size   $label")
    fi
  done < <(lc lsblk -J -o PATH,LABEL,FSTYPE,SIZE,MOUNTPOINTS,RM,TRAN 2>/dev/null | jq -r '
      .blockdevices[]
      | (.tran // "") as $tran
      | (.rm == true or .rm == "1") as $rm
      | recurse(.children[]?)
      | select(.fstype != null)
      | select(.fstype | IN("crypto_LUKS", "swap", "LVM2_member") | not)
      | select($tran == "usb" or $rm)
      | [ .path, .size, (.label // .fstype),
          (if ((.mountpoints // []) | map(select(. != null)) | length) > 0 then 1 else 0 end) ]
      | @tsv')

  if [ "${#entries[@]}" -eq 0 ]; then
    notify "Drives" "No removable drives"
    return 0
  fi

  local choice msg
  choice=$(menu "Drives" "${entries[@]}") || return 0
  case $choice in
    mount:*) if msg=$(try udisksctl mount -b "${choice#mount:}"); then finish "Drives" "$msg"; fi ;;
    unmount:*) if msg=$(try udisksctl unmount -b "${choice#unmount:}"); then finish "Drives" "$msg"; fi ;;
  esac
}

# ────────────────────────────────────────────── Tray ──

tray_menu() {
  if ! have tray-host; then
    notify "Tray" "tray-host is not installed"
    return 0
  fi
  if ! systemctl --user is-active --quiet tray-host.service; then
    notify "Tray" "tray-host.service is not running"
    return 0
  fi
  exec tray-host pick
}

# ──────────────────────────────────────────── Router ──

main_menu() {
  while :; do
    local -a entries=()
    if have tray-host; then entries+=(tray "Tray"); fi
    if have nmcli; then entries+=(wifi "Wi-Fi"); fi
    if have elephant; then entries+=(bluetooth "Bluetooth"); fi
    if have tlpctl; then entries+=(power "Power & battery"); fi
    if have niri; then entries+=(display "Displays"); fi
    if have udisksctl; then entries+=(disks "Removable drives"); fi
    if have elephant; then entries+=(symbols "Symbols & emoji" calc "Calculator"); fi

    local choice
    choice=$(menu "System" "${entries[@]}") || return 0
    case $choice in
      tray) tray_menu ;;
      wifi) wifi_menu ;;
      bluetooth) bluetooth_menu ;;
      power) power_menu ;;
      display) display_menu ;;
      disks) disks_menu ;;
      symbols) symbols_menu ;;
      calc) calc_menu ;;
    esac
  done
}

usage() {
  cat <<'EOF'
Usage: sysmenu [SECTION]

Sections:
  tray  wifi  bluetooth  power  display  disks  symbols
  calc [EXPRESSION]   without EXPRESSION opens a prompt, with it prints the result
EOF
}

case "${1:-}" in
  "") main_menu ;;
  tray) tray_menu ;;
  wifi) wifi_menu ;;
  bluetooth | bt) bluetooth_menu ;;
  power) power_menu ;;
  display) display_menu ;;
  disks) disks_menu ;;
  symbols) symbols_menu ;;
  calc)
    shift
    if [ $# -gt 0 ]; then calc_eval "$*"; else calc_menu; fi
    ;;
  -h | --help) usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
