{ stdenv, fetchurl, jre }: 

stdenv.mkDerivation {
  name = "heritrix-3.1.0"; 
  src = fetchurl { 
    url = mirror://sourceforge/project/archive-crawler/heritrix3/3.1.0/heritrix-3.1.0-dist.tar.gz;
    sha256 = "06n2rkhk79ql3x81gmj4l0wjihi3i50200x70g3jn42rf2gb40kb";
  };
  
  inherit jre;
  
  installPhase = ''
    cp -r ./ $out
  '';

}
