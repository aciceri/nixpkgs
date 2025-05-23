{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  qtbase,
  wrapQtAppsHook,
}:

stdenv.mkDerivation rec {
  pname = "pe-bear";
  version = "0.7.0.4";

  src = fetchFromGitHub {
    owner = "hasherezade";
    repo = "pe-bear";
    rev = "v${version}";
    hash = "sha256-W8Sa7MKTf7mbdzAEL6tNDpmXIFWAC/8qSXBqqsZ4WFk=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
  ];

  meta = with lib; {
    description = "Portable Executable reversing tool with a friendly GUI";
    mainProgram = "PE-bear";
    homepage = "https://hshrzd.wordpress.com/pe-bear/";

    license = [
      # PE-Bear
      licenses.gpl2Only

      # Vendored capstone
      licenses.bsd3

      # Vendored bearparser
      licenses.bsd2
    ];

    maintainers = with maintainers; [ blitz ];
    platforms = platforms.linux;
  };
}
