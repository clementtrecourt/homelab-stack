// Déclaration du pipeline
pipeline {
    // L'agent spécifie où le pipeline va s'exécuter. 'any' signifie sur n'importe quel agent disponible.
    agent any

    // Les 'stages' sont les étapes de notre pipeline
    stages {
        // Étape 1: Valider le code Terraform
        stage('Terraform Validate') {
            steps {
                // Le 'dir' change le répertoire de travail pour les commandes suivantes
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                }
            }
        }

        // Étape 2: Planifier les changements Terraform
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    // NOTE: La gestion des secrets (variables.tfvars) est un sujet avancé.
                    // Pour commencer, on peut supposer que le fichier est déjà sur le serveur Jenkins.
                    sh 'terraform plan'
                }
            }
        }

        // Étape 3: Appliquer les changements (étape manuelle pour la sécurité)
        stage('Terraform Apply') {
            steps {
                // 'input' met le pipeline en pause et attend une confirmation manuelle
                input 'Do you want to apply the Terraform changes?'
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        // Étape 4: Lancer la configuration Ansible
        stage('Ansible Provision') {
            steps {
                input 'Do you want to run the Ansible playbook?'
                dir('ansible') {
                    // La gestion du mot de passe du vault est complexe.
                    // On peut le stocker dans les "Credentials" de Jenkins.
                    // Pour commencer, on peut le passer via une variable d'environnement (moins sécurisé).
                    sh 'ansible-playbook site.yml'
                }
            }
        }
    }
}