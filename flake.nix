{
  description = "Elegant GRUB2 Theme as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      variants = ["float" "sharp" "window"];
      sides = ["left" "right"];
      colors = ["dark" "light"];
      resolutions = ["1080p" "2k" "4k"];
      backgrounds = ["forest" "mojave" "mountain" "wave"];

      mkElegantGrubTheme = {
        config ? {
          variant = "float";
          side = "left";
          color = "dark";
          resolution = "1080p";
          background = "mojave";
          logo = false;
          info = false;
        },
      }: let
        cfg = config;
        selectLogoFile =
          if cfg.logo
          then "Nixos.png"
          else "Empty.png";
        selectInfoFile =
          if cfg.info
          then "${cfg.variant}-${cfg.side}.png"
          else "Empty.png";
      in
        assert builtins.elem cfg.variant variants;
        assert builtins.elem cfg.side sides;
        assert builtins.elem cfg.color colors;
        assert builtins.elem cfg.resolution resolutions;
        assert builtins.elem cfg.background backgrounds;
          pkgs.stdenvNoCC.mkDerivation {
            pname = "elegant-grub-theme";
            version = "latest";

            src = ./.;

            nativeBuildInputs = with pkgs; [grub2 freetype];

            buildPhase = ''
              cd common
              for font in *.ttf; do
                ${pkgs.grub2}/bin/grub-mkfont -s 32 -o "$(basename "$font" .ttf).pf2" "$font"
              done
              cd ..
            '';

            installPhase = ''
              mkdir -p $out/theme
              cp config/theme-${cfg.variant}-${cfg.side}-${cfg.color}-${cfg.resolution}.txt $out/theme/theme.txt
              cp backgrounds/backgrounds-${cfg.background}/background-${cfg.background}-${cfg.variant}-${cfg.side}-${cfg.color}.jpg $out/theme/background.jpg
              cp -r common/*.pf2 $out/theme/
              mkdir -p $out/theme/icons
              cp -r assets/assets-icons-${cfg.color}/icons-${cfg.color}-${cfg.resolution}/* $out/theme/icons/
              cp -r assets/assets-other/other-${cfg.resolution}/select_c-${cfg.background}-${cfg.color}.png $out/theme/select_c.png
              cp -r assets/assets-other/other-${cfg.resolution}/select_e-${cfg.background}-${cfg.color}.png $out/theme/select_e.png
              cp -r assets/assets-other/other-${cfg.resolution}/select_w-${cfg.background}-${cfg.color}.png $out/theme/select_w.png
              cp assets/assets-other/other-${cfg.resolution}/${selectLogoFile} $out/theme/logo.png
              cp assets/assets-other/other-${cfg.resolution}/${selectInfoFile} $out/theme/info.png
            '';

            meta = with pkgs.lib; {
              description = "Elegant GRUB2 theme";
              license = licenses.gpl3Plus;
              platforms = platforms.linux;
            };
          };
    in {
      packages = {
        elegant-grub-theme = mkElegantGrubTheme;
        default = mkElegantGrubTheme {};
      };
    });
}
