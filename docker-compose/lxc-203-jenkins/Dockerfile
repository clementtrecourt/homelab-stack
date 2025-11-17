# On part de l'image officielle de Jenkins
FROM jenkins/jenkins:lts-jdk17

# On passe en utilisateur root pour pouvoir installer des paquets
USER root

# On installe les dépendances et le client Docker
# C'est la même procédure que celle que nous avons faite dans le LXC
RUN apt-get update && apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    # On installe UNIQUEMENT le client, pas le serveur complet
    apt-get install -y docker-ce-cli

# On repasse à l'utilisateur jenkins, c'est une bonne pratique de sécurité
USER jenkins