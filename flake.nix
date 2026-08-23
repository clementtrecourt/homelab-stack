{
  description = "DevOps / SRE Bastion & Talos Management Shell with Fish";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Script de supervision rapide
        checkHomelab = pkgs.writeShellScriptBin "check-homelab" ''
          echo "🔍 Vérification de la connectivité de l'infrastructure..."
          check_port() {
            local name=$1
            local host=$2
            local port=$3
            if nc -z -w 2 "$host" "$port" 2>/dev/null; then
              echo "  \033[32m[OK]\033[0m $name ($host:$port)"
            else
              echo "  \033[31m[FAIL]\033[0m $name ($host:$port) inaccessible !"
            fi
          }

          check_port "Proxmox VE" "192.168.1.120" 8006
          check_port "Bastion Rocky Linux (SSH)" "192.168.1.20" 22
          check_port "Talos API (gRPC)" "192.168.1.21" 50000
          check_port "Kubernetes API" "192.168.1.21" 6443
        '';

      in {
        devShells.default = pkgs.mkShell {
          name = "sre-ops-shell";

          buildInputs = with pkgs; [
            # Shell & Scripts
            fish
            checkHomelab

            # IaC & Automation
            opentofu
            terraform
            ansible

            # Kubernetes & Talos
            talosctl
            kubectl
            kubernetes-helm
            k9s
            kubectx
            stern
            cilium-cli

            # DevSecOps & Secrets
            sops
            age
            cosign
            syft
            trivy

            # Network & Debug
            netcat
            jq
            yq-go
            curl
            bind.dnsutils
            mtr
            btop
          ];

          # Bascule automatiquement vers Fish avec alias pré-chargés
          shellHook = ''
            if [ -z "$IN_NIX_FISH" ] && [ -t 0 ]; then
              export IN_NIX_FISH=1
              exec fish --init-command "
                alias k='kubectl'
                alias t='talosctl'
                alias tf='tofu'
                alias check='check-homelab'

                function fish_greeting
                  echo '========================================================='
                  echo ' 🛡️  ENVIRONNEMENT DE GESTION & SUPERVISION (FISH)  🛡️ '
                  echo '========================================================='
                  echo ' Commandes rapides :'
                  echo '   • check : Teste la connectivité du cluster'
                  echo '   • k9s   : Dashboard Kubernetes'
                  echo '   • t     : talosctl'
                  echo '   • tf    : opentofu / terraform'
                  echo '========================================================='
                end
              "
            fi
          '';
        };
      }
    );
}
