# Upstream: https://github.com/acidanthera/Lilu/releases/
{ lib }: rec {
  latest = v1_6_7;

  v1_6_7 = {
    canonicalVersion = "1.6.7";
    debug = "sha256-d2P2LhjzI1VU1CSddmIB1YBh7XQgRqcR6PzrpHkSBW8=";
    release = "sha256-+1i0E0Q94ePbD6wA496p6NCDRVeeigi8KwZ1uZdtC9c=";
  };

  v1_6_2 = {
    canonicalVersion = "1.6.2";
    debug = "sha256-IAifHevcg86l6i41b6WsJinDz1wgzuQgBCbrzCZFQYA=";
    release = "sha256-eyYwlQdPDuLHtLPNt8g1a6z1VmMXGnzXfSwUj3uSsdY=";
  };
}
