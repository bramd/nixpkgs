{ stdenv, fetchurl, JAVA_HOME }: 

stdenv.mkDerivation {
  name = "heritrix-3.1.0"; 
  builder = ./builder.sh;
  src = fetchurl { 
    url =http://downloads.sourceforge.net/project/archive-crawler/heritrix3/3.1.0/heritrix-3.1.0-dist.tar.gz;

  buildInputs = [jre];
  };
  inherit JAVA_HOME;
  
}