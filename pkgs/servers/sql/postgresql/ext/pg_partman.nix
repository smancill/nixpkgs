{ lib, stdenv, fetchFromGitHub, postgresql }:

stdenv.mkDerivation rec {
  pname = "pg_partman";
  version = "5.0.1";

  buildInputs = [ postgresql ];

  src = fetchFromGitHub {
    owner  = "pgpartman";
    repo   = pname;
    rev    = "refs/tags/v${version}";
    sha256 = "sha256-sJODpyRgqpeg/Lb584wNgCCFRaH22ELcbof1bA612aw=";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp src/*${postgresql.dlSuffix} $out/lib
    cp updates/*     $out/share/postgresql/extension
    cp -r sql/*      $out/share/postgresql/extension
    cp *.control     $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "Partition management extension for PostgreSQL";
    homepage    = "https://github.com/pgpartman/pg_partman";
    changelog   = "https://github.com/pgpartman/pg_partman/blob/v${version}/CHANGELOG.md";
    maintainers = with maintainers; [ ggpeti ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
    broken      = versionOlder postgresql.version "14";
  };
}
