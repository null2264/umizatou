# This file contains functions used to generate related OpenCore settings based on installed resources.
{ lib }:
with lib;
with builtins; rec {
  # Make every child node default
  mkDefaultRecursive = attrs:
    mapAttrsRecursive (path: value: (mkDefault value)) attrs;

  # Transpose the generated attrsets back to the format OpenCore required, use it ONLY on ACPI and Drivers
  transpose = attrs: mapAttrsToList (n: v: v) attrs;

  pathToName = path: (replaceStrings [ "/" ] [ "+" ] path);

  pathToRelative = level: path:
    strings.concatStrings (strings.intersperse "/"
      (lists.drop level (splitString "/" (toString path))));

  mkACPIRecursive = autoEnable: dir:
    listToAttrs (flatten (mapAttrsToList
      (name: type:
        let path = dir + "/${name}";
        in if type == "regular" then
          if lib.hasSuffix ".aml" path then
            [
              (nameValuePair name {
                Comment = name;
                # default to false
                Enabled = autoEnable;
                Path = pathToRelative 7 path;
                # lower means loaded early
                Priority = 1000;
              })
            ]
          else
            [ ]
        else
          mkACPIRecursive autoEnable path)
      (readDir dir)));

  # Generated attrsets are of the form:
  # {
  #   "foo.aml" = {
  #      Comment = "foo.aml";
  #      Enabled = false;
  #      Path = "foo.aml";
  #   };
  # }
  mkACPI = autoEnable: pkg: mkACPIRecursive autoEnable "${pkg}/EFI/OC/ACPI";

  removeACPIPriority = list:
    map
      (value: updateManyAttrsByPath
        [{
          path = [ "Priority" ];
          update = old: null;
        }]
        value)
      list;

  finalizeACPI = attrs:
    removeACPIPriority (sort (a: b: a.Priority < b.Priority) (transpose attrs));

  mkToolsRecursive = autoEnable: dir:
    listToAttrs (flatten (mapAttrsToList
      (name: type:
        let path = dir + "/${name}";
        in if type == "regular" then
          if lib.hasSuffix ".efi" path then
            [
              (nameValuePair name {
                Arguments = "";
                Auxiliary = true;
                Flavour = "Auto";
                FullNvramAccess = false;
                Name = name;
                Comment = name;
                Enabled = autoEnable;
                Path = pathToRelative 7 path;
                RealPath = false;
                TextMode = false;
              })
            ]
          else
            [ ]
        else
          mkToolsRecursive autoEnable path)
      (readDir dir)));

  mkTools = autoEnable: pkg: mkToolsRecursive autoEnable "${pkg}/EFI/OC/Tools";

  mkDriversRecursive = autoEnable: dir:
    listToAttrs (flatten (mapAttrsToList
      (name: type:
        let path = dir + "/${name}";
        in if type == "regular" then
          if lib.hasSuffix ".efi" path then
            [
              (nameValuePair name {
                Arguments = "";
                LoadEarly = false;
                Comment = name;
                Enabled = autoEnable;
                Path = pathToRelative 7 path;
              })
            ]
          else
            [ ]
        else
          mkDriversRecursive autoEnable path)
      (readDir dir)));

  mkDrivers = autoEnable: pkg: mkDriversRecursive autoEnable "${pkg}/EFI/OC/Drivers";

  # How to generate Kexts
  # 1. Parse kexts using mkKexts: pkg -> attrset
  # 2. Make it recursively default
  # 3. Do recursive enable on plugins
  # 4. Apply DAG ordering
  # 5. Remove passthru

  # parent: the name of the parent Kext, null if it is at the top level
  # dir: current dir
  mkKextsRecursive = pkgs: parent: dir:
    (flatten (mapAttrsToList
      (name: type:
        let
          path = dir + "/${name}";
          # if this is folder, try to see if it is a kext
        in
        if (type == "directory") then
          if hasSuffix ".kext" path then
          # if it is a kext, we shall resolve dependency and add it to a list
            let
              infoListPath = path + "/Contents/Info.plist";
              info = parsePlist pkgs infoListPath;
            in
            [
              (nameValuePair (if parent == null then name else "${parent}/${name}") ({
                Arch = "Any";
                Comment = name;
                Enabled = null;
                BundlePath = pathToRelative 7 path;
                ExecutablePath = if info.CFBundleExecutable or null == null then "" else ("Contents/MacOS/" + info.CFBundleExecutable);
                PlistPath = "Contents/Info.plist";
                # TODO: Complete kernel version requirements automatically?
                MinKernel = "";
                MaxKernel = "";

                before = [];
                after = [];
                # Internal attrs. passthru should be removed later
                passthru = {
                  identifier = info.CFBundleIdentifier;
                  parent = parent;
                  dependencies = trace "${name} (${info.CFBundleIdentifier}) depends on [${toString (parseKextDeps info)}]" (parseKextDeps info);
                };
              }))
            ] ++
            # recursively descend for plugins
            # if we are at the top-level, then use our name as parent
            # otherwise, pass down the top-level kext from which we are inherited
            (mkKextsRecursive pkgs (if parent == null then name else parent) path)
          else
          # recursively descend, inheriting current parent
            mkKextsRecursive pkgs parent path
        # if it is not a folder, we do nothing.
        else
          [ ])
      (readDir dir)));

  mkKexts = pkgs: pkg: listToAttrs (mkKextsRecursive pkgs null "${pkg}/EFI/OC/Kexts");

  # recursively enable plugins before transpose
  enablePluginsRecursive = attrs:
    mapAttrs
      (name: value: updateManyAttrsByPath
        [{
          path = [ "Enabled" ];
          update = old:
            if value.passthru.parent == null || value.Enabled != null then
              old
            else
              attrs."${value.passthru.parent}".Enabled;
        }]
        value)
      attrs;

  # Enabled = null -> Enabled = false
  fixPluginsRecursive = attrs:
    mapAttrs
      (name: value: updateManyAttrsByPath
        [{
          path = [ "Enabled" ];
          update = old:
            if value.Enabled != null then
              old
            else
              false;
        }]
        value)
      attrs;

  orderKexts = attrs:
    map (x: x.data)
      (oc.dag.topoSort
        (mapAttrs (name: value: oc.dag.entryBetween value.before (value.after ++ value.passthru.dependencies) value)
          (mapAttrs'
            (name: value: nameValuePair (
              if value.passthru.parent == null then
                value.passthru.identifier
              else
                "${value.passthru.parent}/${value.passthru.identifier}"
              ) value)
            attrs))).result;

  removePassthru = list:
    map
      (value: updateManyAttrsByPath
        [
          {
            path = [ "passthru" ];
            update = old: null;
          }
          {
            path = [ "after" ];
            update = old: null;
          }
          {
            path = [ "before" ];
            update = old: null;
          }
        ]
        value)
      list;

  # used by end-user
  finalizeKexts = autoEnablePlugins: attrs:
    removePassthru (orderKexts
      (fixPluginsRecursive (if autoEnablePlugins then enablePluginsRecursive attrs else attrs)));

  parseKextDeps = attrs: mapAttrsToList (name: value: name) attrs.OSBundleLibraries or { };

  # We replace "\" with "/" because it often causes JSON parsing error on places we don't care like Patch or Add in Sample.plist
  parsePlist' = pkgs: path: pkgs.runCommand "parsePlist_${pathToRelative 7 path}" { allowSubstitutes = false; nativeBuildInputs = [ pkgs.libplist ]; } ''
    mkdir $out
    cp "${path}" ./plist.in
    substituteInPlace ./plist.in --replace "<data>" "<string>" --replace "</data>" "</string>" --replace "<date>" "<string>" --replace "</date>" "<string>" --replace "\\" "/"
    plistutil -i ./plist.in -o $out/plist.out -f json
  '';

  parsePlist = pkgs: plist: fromJSON (readFile "${parsePlist' pkgs plist}/plist.out");
}
