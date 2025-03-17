{
  description = "Kyle's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          # Allow unfree packages.
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.stow # symlink manager / farm
            pkgs.vim # text editor
            pkgs.iterm2 # terminal emulator
            pkgs.nixfmt-rfc-style # nix formatter
            pkgs.nixd # nix lsp
            pkgs.tree # directory tree viewer
            pkgs.gh # github cli
            pkgs.unison # bi-directional file sync (for CSCI353)
            pkgs.unison-fsmonitor # unison file monitor (for CSCI353)
            pkgs.mkalias # create finder aliases
            pkgs.nodePackages.npm # node package manager
          ];

          homebrew = {
            enable = true;
            brews = [
              "cocoapods" # dependency manager for Cocoa projects
            ];
            casks = [
              "iina" # video player
              "keka" # file archiver
              "transmission" # torrent client
              "shottr" # screenshot editor
              "raycast" # shortcut utility
            ];
            taps = [
            ];
            onActivation.cleanup = "zap";
          };

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac-home
      darwinConfigurations."mac-home" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # for apple silicon
              enableRosetta = true;
              user = "kylehe";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-home".pkgs;
    };
}
