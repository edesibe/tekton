# reproducible shell env
# https://nix.dev/tutorials/declarative-and-reproducible-developer-environments
{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/cff83d5032a21aad4f69bf284e95b5f564f4a54e.tar.gz") {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.direnv
    pkgs.sops
    pkgs.age
    pkgs.kubectl
  ];
  shellHook =
    let tmuxConf = 
      pkgs.writeText 
        "tmux.conf" 
        ''
        unbind C-b
        set -g prefix C-Space
        set -g mouse on
        '';
    in ''
      tmux -f ${tmuxConf}
    '';
}
