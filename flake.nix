{
  description = "github.com:david-r-cox/blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
        buildInputs = with pkgs; [
          nodejs_20
          nodePackages.yarn
          nodePackages.ts-node
        ];
        devShell = pkgs.mkShell {
          inherit buildInputs;
        };
      in
      rec
      {
        inherit devShell;
      }
    );
}
