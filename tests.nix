{ self }:
let
  pkgs = import self.inputs.nixpkgs { system = "x86_64-linux"; };
  garnix-lib = self.inputs.garnix-lib;
in
{
  x86_64-linux.simple = pkgs.testers.runNixOSTest ({ lib, ... }: {
    name = "rss-bridge";
    nodes.simple = { lib, pkgs, ... }:
      let
        evaledGarnixModuleConfig = (garnix-lib.lib.evaledModulesForSystems {
          modules = [ self.garnixModules.default ({ }) ];
          config = { rss-bridge.default = { path = "/"; }; };
        }).x86_64-linux;
      in
      {
        imports = [ garnix-lib.nixosModules.garnix ]
          ++ evaledGarnixModuleConfig.config.nixosConfigurations.default;
        garnix.server.isVM = true;
        garnix.server.enable = true;
      };
    testScript = { nodes, ... }: ''
      start_all()
      simple.wait_for_unit("multi-user.target")
      simple.wait_for_unit("nginx.service")
      simple.wait_until_succeeds("curl --fail http://127.0.0.1", 20)
    '';
  });
}
