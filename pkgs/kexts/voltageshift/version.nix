# Upstream:
# - https://github.com/sicreative/VoltageShift
# - https://github.com/xCuri0/VoltageShiftSecure/releases
{ lib }: rec {
  latest = v1_27;

  v1_27 = {
    canonicalVersion = "1.27";
    hash = "sha256-1xwcGnpuFEPmI3urX/jyEaMyfe2wkIrmuIkjCFvhDGI=";
    secure = true;
  };

  v1_25 = {
    canonicalVersion = "1.25";
    hash = "sha256-tOdSpoYHTPiJ0GEjRMR9i5w5sUVklVnJNiFnTr/GKLA=";
    secure = false;
  };
}
