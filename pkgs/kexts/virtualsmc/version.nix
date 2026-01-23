# Upstream: https://github.com/acidanthera/VirtualSMC/releases/
{ lib }: rec {
  latest = v1_3_2;

  v1_3_2 = {
    canonicalVersion = "1.3.2";
    debug = "sha256-7pcW4fxOvBRTI9TKpblprBFMaPET/V4dh/fw90ZL2JQ=";
    release = "sha256-KwoZM7MtwDPqNNNTl+LQ3O/7D05sXMnOpRKzmCWsZps=";
  };

  v1_3_0 = {
    canonicalVersion = "1.3.0";
    debug = "sha256-z5JzEtSF/NTSHTFxGvLXhQVgTIbKqReXUwsMNHE17FU=";
    release = "sha256-SPbgM8AeYDUzV2+/ZKhZz1MXkRAD7FJ/w9g//BbFhCE=";
  };
}
