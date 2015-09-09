{ stdenv, fetchurl, makeDesktopItem, makeWrapper
, dbus_libs, gcc, glib, libdrm, libffi, libICE, libSM
, libX11, libXmu, ncurses, popt, qt5, zlib
}:

# this package contains the daemon version of dropbox
# it's unfortunately closed source
#
# note: the resulting program has to be invoced as
# 'dropbox' because the internal python engine takes
# uses the name of the program as starting point.

# Dropbox ships with its own copies of some libraries.
# Unfortunately, upstream makes changes to the source of
# some libraries, rendering them incompatible with the
# open-source versions. Wherever possible, we must try
# to make the bundled libraries work, rather than replacing
# them with our own.

let
  version = "3.6.9";
  sha256 =
    {
      "x86_64-linux" = "1i260mi40siwcx9b2sj4zwszxmj1l88mpmyqncsfa72k02jz22j3";
      "i686-linux" = "0qqc8qbfaighbhjq9y22ka6n6apl8b6cr80a9rkpk2qsk99k8h1z";
    }."${stdenv.system}" or (throw "system ${stdenv.system} not supported");

  arch =
    {
      "x86_64-linux" = "x86_64";
      "i686-linux" = "x86";
    }."${stdenv.system}" or (throw "system ${stdenv.system} not supported");

  interpreter =
    {
      "x86_64-linux" = "ld-linux-x86-64.so.2";
      "i686-linux" = "ld-linux.so.2";
    }."${stdenv.system}" or (throw "system ${stdenv.system} not supported");

  # relative location where the dropbox libraries are stored
  appdir = "opt/dropbox";

  ldpath = stdenv.lib.makeSearchPath "lib"
    [
      dbus_libs gcc glib libdrm libffi libICE libSM libX11
      libXmu ncurses popt qt5 zlib
    ];

  desktopItem = makeDesktopItem {
    name = "dropbox";
    exec = "dropbox";
    comment = "Online directories";
    desktopName = "Dropbox";
    genericName = "Online storage";
    categories = "Application;Internet;";
  };

in stdenv.mkDerivation {
  name = "dropbox-${version}-bin";
  src = fetchurl {
    name = "dropbox-${version}.tar.gz";
    url = "https://dl-web.dropbox.com/u/17/dropbox-lnx.${arch}-${version}.tar.gz";
    inherit sha256;
  };

  sourceRoot = ".";

  patchPhase = ''
    rm -f .dropbox-dist/dropboxd
  '';

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p "$out/${appdir}"
    cp -r ".dropbox-dist/dropbox-lnx.${arch}-${version}"/* "$out/${appdir}/"

    rm "$out/${appdir}/libdrm.so.2"
    rm "$out/${appdir}/libffi.so.6"
    rm "$out/${appdir}/libicudata.so.42"
    rm "$out/${appdir}/libicui18n.so.42"
    rm "$out/${appdir}/libicuuc.so.42"
    rm "$out/${appdir}/libGL.so.1"
    rm "$out/${appdir}/libpopt.so.0"
    rm "$out/${appdir}/libQt5Core.so.5"
    rm "$out/${appdir}/libQt5DBus.so.5"
    rm "$out/${appdir}/libQt5Gui.so.5"
    rm "$out/${appdir}/libQt5Network.so.5"
    rm "$out/${appdir}/libQt5OpenGL.so.5"
    rm "$out/${appdir}/libQt5PrintSupport.so.5"
    rm "$out/${appdir}/libQt5Qml.so.5"
    rm "$out/${appdir}/libQt5Quick.so.5"
    rm "$out/${appdir}/libQt5Sql.so.5"
    rm "$out/${appdir}/libQt5WebKit.so.5"
    rm "$out/${appdir}/libQt5WebKitWidgets.so.5"
    rm "$out/${appdir}/libQt5Widgets.so.5"
    rm "$out/${appdir}/libX11-xcb.so.1"

    rm "$out/${appdir}/qt.conf"
    rm -fr "$out/${appdir}/plugins"

    find "$out/${appdir}" -type f -a -perm +0100 \
      -print -exec patchelf --set-interpreter ${stdenv.glibc}/lib/${interpreter} {} \;

    RPATH=${ldpath}:${gcc.gcc}/lib:$out/${appdir}
    echo "updating rpaths to: $RPATH"
    find "$out/${appdir}" -type f -a -perm +0100 \
      -print -exec patchelf --force-rpath --set-rpath "$RPATH" {} \;

    mkdir -p "$out/share/applications"
    cp "${desktopItem}/share/applications/"* $out/share/applications

    mkdir -p "$out/bin"
    makeWrapper "$out/${appdir}/dropbox" "$out/bin/dropbox" \
      --prefix LD_LIBRARY_PATH : "${ldpath}"

    mkdir -p "$out/share/icons"
    ln -s "$out/${appdir}/images/hicolor" "$out/share/icons/hicolor"
  '';

  meta = {
    homepage = "http://www.dropbox.com";
    description = "Online stored folders (daemon version)";
    maintainers = with stdenv.lib.maintainers; [ ttuegel ];
  };
}
