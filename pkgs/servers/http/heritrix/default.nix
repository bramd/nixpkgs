{ stdenv, fetchurl, jre, makeWrapper }: 

stdenv.mkDerivation {
  name = "heritrix-3.1.0"; 
  src = fetchurl { 
    url = mirror://sourceforge/project/archive-crawler/heritrix3/3.1.0/heritrix-3.1.0-dist.tar.gz;
    sha256 = "06n2rkhk79ql3x81gmj4l0wjihi3i50200x70g3jn42rf2gb40kb";
  };
  
  buildInputs = [ makeWrapper ];
  
  installPhase = ''
    mkdir -p $out/heritrix $out/bin
    cp -r ./ $out/heritrix
    makeWrapper $out/heritrix/bin/heritrix $out/bin/heritrix \
      --set JAVA_HOME ${jre} \
      --set HERITRIX_HOME $out/heritrix \
      --set HERITRIX_OUT /var/log/heritrix.log
    substituteInPlace $out/heritrix/bin/heritrix \
      --replace \''${HERITRIX_HOME}/heritrix_dmesg.log /tmp/heritrix_dmesg.log
  '';

}
