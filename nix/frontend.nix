{ pkgs, src }:

pkgs.stdenv.mkDerivation {
  pname = "openhands-frontend";
  version = "0.39.1";
  
  # Use a dummy source
  src = pkgs.writeTextFile {
    name = "dummy-index.html";
    text = "<html><body><h1>OpenHands Frontend</h1></body></html>";
    destination = "/index.html";
  };
  
  # Just copy the dummy index.html to the output
  installPhase = ''
    mkdir -p $out/build
    cp $src/index.html $out/build/
  '';
  
  # Metadata
  meta = with pkgs.lib; {
    description = "Frontend for OpenHands AI software engineer";
    homepage = "https://github.com/all-hands-dev/OpenHands";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [];
  };
}