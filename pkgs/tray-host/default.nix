{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tray-host";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "sorubedo";
    repo = "tray-host";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6V1Pz6G7zqktkC9WauAcosIOsnPDL3rnO33aWyP6w9w=";
  };

  cargoHash = "sha256-Gh+T/L9olcwEdaFqo59qYWkgd66YIMmE0JEHdK1ozLI=";

  # Upstream bugs are fixed here with local .patch files instead of maintaining a fork.
  patches = [ ];

  # Upstream ships no tests
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Headless StatusNotifierItem host for external pickers like fuzzel";
    homepage = "https://github.com/sorubedo/tray-host";
    license = lib.licenses.mit;
    mainProgram = "tray-host";
    platforms = lib.platforms.linux;
  };
})
