{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  cairo,
  dbus,
  fontconfig,
  freetype,
  giflib,
  glib,
  gmp,
  gnutls,
  gst_all_1,
  harfbuzz,
  lcms2,
  libdrm,
  libgbm,
  libGL,
  libjpeg,
  libotf,
  libpng,
  librsvg,
  libselinux,
  libtiff,
  libva,
  libwebp,
  libx11,
  libxcursor,
  libxi,
  libxinerama,
  libxkbcommon,
  libxml2,
  libxpm,
  libxrandr,
  alsa-lib,
  ncurses,
  pango,
  poppler,
  tree-sitter,
  vulkan-loader,
  wayland,
  zlib,
}:

let
  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];

  # Loaded with dlopen at runtime (winit/wgpu backends, lcms, treesit).
  dlopenLibs = [
    lcms2
    libGL
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    tree-sitter
    vulkan-loader
    wayland
  ];

  releaseDir = "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "neomacs";
  version = "0.0.20";

  src = fetchFromGitHub {
    owner = "eval-exec";
    repo = "neomacs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6gNMv+H5gfQ6O3qGkigMdN1tMsT4z0g2RlyyJz8mcGg=";
  };

  cargoHash = "";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    cairo
    dbus
    fontconfig
    freetype
    giflib
    glib
    gmp
    gnutls
    harfbuzz
    libdrm
    libgbm
    libjpeg
    libotf
    libpng
    librsvg
    libselinux
    libtiff
    libva
    libwebp
    libxinerama
    libxml2
    libxpm
    ncurses
    pango
    poppler
    zlib
  ]
  ++ dlopenLibs
  ++ gstPlugins;

  # Mirrors the Linux production capability profile in the workspace
  # Cargo.toml (`video`, linked GStreamer).
  cargoBuildFlags = [
    "-p"
    "neomacs"
  ];
  buildFeatures = [ "video" ];

  # Upstream's `cargo xtask fresh-build` without its cargo stage: patches the
  # pdump fingerprint, bootstraps and byte-compiles the Lisp tree and dumps
  # the final image with the binary built above.
  postBuild = ''
    cargo run --offline -j "$NIX_BUILD_CORES" -p xtask -- \
      fresh-build --release --skip-build --bin-dir ${releaseDir}
  '';

  # The parity suites compare against a pinned GNU Emacs and need a display.
  doCheck = false;

  postInstall = ''
    # Build-role copies of the main executable used only by fresh-build.
    rm "$out/bin/neomacs-temacs" "$out/bin/bootstrap-neomacs"

    mkdir -p "$out/share/neomacs"
    cp -r lisp etc "$out/share/neomacs/"

    bash scripts/install-linux-desktop-assets.sh "$out"

    fingerprint="$("$out/bin/neomacs" --fingerprint | tr -d '[:space:]')"
    if ! [[ "$fingerprint" =~ ^[[:xdigit:]]{64}$ ]]; then
      echo "invalid final pdump fingerprint: $fingerprint" >&2
      exit 1
    fi
    install -m 0644 ${releaseDir}/neomacs.pdump "$out/bin/neomacs.pdump"
    install -m 0644 ${releaseDir}/neomacs.pdump "$out/bin/neomacs-$fingerprint.pdump"

    wrapProgram "$out/bin/neomacs" \
      --set-default NEOMACS_RUNTIME_ROOT "$out/share/neomacs" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${lib.makeSearchPath "lib/gstreamer-1.0" (map lib.getLib gstPlugins)}"
  '';

  # After patchelf's rpath shrinking, which would drop dlopen-only entries.
  postFixup = ''
    patchelf --add-rpath "${lib.makeLibraryPath dlopenLibs}" "$out/bin/.neomacs-wrapped"
  '';

  meta = {
    description = "GPU-accelerated Emacs-compatible editor written in Rust";
    homepage = "https://github.com/eval-exec/neomacs";
    changelog = "https://github.com/eval-exec/neomacs/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ aciceri ];
    mainProgram = "neomacs";
    platforms = lib.platforms.linux;
  };
})
