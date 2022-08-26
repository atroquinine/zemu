{
  description = "";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };

      zig = (pkgs.zig.override { llvmPackages = pkgs.llvmPackages_14; }).overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "ziglang";
          repo = "zig";
          rev = "5fd5950c9277d5d0bb52e5968dc7d020dbcdd3d8";
          sha256 = "sha256-0yM4H1OBp5N7kIf/ekNulUtVwKOQVAx8fb6Y6Nz0pPE=";
        };
        patches = [];
      });

      zls = (pkgs.zls.override { inherit zig; }).overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "zigtools";
          repo = "zls";
          rev = "8cf96fe27cfd235acdf301728f9cce7a7b265ca3";
          sha256 = "sha256-lpK32m03K4u8y2UdlM36m9TwA9wRfQ2x+FE0y143q7g=";
        };
      });

      buildInputs = with pkgs; [ ];
      nativeBuildInputs = [
        zls
        zig
        pkgs.pkg-config
      ];
    in
    rec {
      devShell = pkgs.mkShell {
        inherit buildInputs nativeBuildInputs;
      };
    }
  );
}
