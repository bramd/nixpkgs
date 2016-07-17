{ plasmaPackage, extra-cmake-modules, frameworkintegration
, kcmutils, kconfigwidgets, kcoreaddons, kdecoration, kguiaddons
, ki18n, kwindowsystem, makeQtWrapper, plasma-framework, qtx11extras
}:

plasmaPackage {
  name = "breeze-qt5";
  sname = "breeze";
  nativeBuildInputs = [
    extra-cmake-modules
    makeQtWrapper
  ];
  propagatedBuildInputs = [
    frameworkintegration ki18n kwindowsystem plasma-framework qtx11extras
    kcmutils kconfigwidgets kcoreaddons kdecoration kguiaddons
  ];
  cmakeFlags = [ "-DUSE_Qt4=OFF" ];
  postInstall = ''
    wrapQtProgram "$out/bin/breeze-settings5"
  '';
}
