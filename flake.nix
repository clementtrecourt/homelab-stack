{
  description = "DevOps / SRE Bastion & Talos Management Shell";

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

        # Script de supervision rapide intégré au shell
        checkHomelab = pkgs.writeShellScriptBin "check-homelab" ''
          echo "🔍 Vérification de la connectivité de l'infrastructure..."
          
          check_port() {
            local name=$1
            local host=$2
            local port=$3
            if nc -z -w 2 "$host" "$port" 2>/dev/null; then
              echo "  [OK] $name ($host:$port)"
            else
              echo "  [FAIL] $name ($host:$port) inaccessible !"
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
            # Scripts customs
            checkHomelab

            # Infrastructure as Code & Automation
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
            bind.dnsutils # dig
            mtr
            btop
          ];

          shellHook = ''
            echo "========================================================="
            echo " 🛡️  ENVIRONNEMENT DE GESTION & SUPERVISION HOMELAB  🛡️ "
            echo "========================================================="
            echo " Commandes rapides disponibles :"
            echo "   • check-homelab : Vérifie l'état du Proxmox, Bastion, Talos"
            echo "   • k9s            : Lance le dashboard Kubernetes"
            echo "   • talosctl       : Contrôle des nœuds Talos"
            echo "   • tofu / tf      : Déploiement IaC"
            echo "========================================================="
            
            alias k="kubectl"
            alias t="talosctl"
            alias tf="tofu"
          '';
        };
      }
    );
}
