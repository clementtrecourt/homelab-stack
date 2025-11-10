# Étape 1: Choisir une image de base légère avec Node.js
FROM node:18-alpine

# Étape 2: Définir le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Étape 3: Copier les fichiers de dépendances
# On copie ces fichiers en premier pour profiter du cache Docker.
# Si ces fichiers ne changent pas, Docker n'exécutera pas "npm install" à chaque build.
COPY package*.json ./

# Étape 4: Installer les dépendances de l'application
RUN npm install

# Étape 5: Copier tout le reste du code de l'application
COPY . .

# Étape 6: Exposer le port que notre serveur utilise
# CORRIGÉ : Le port exposé correspond maintenant au port du serveur
EXPOSE 2000

# Étape 7: La commande pour démarrer l'application lorsque le conteneur se lance
CMD ["node", "server.js"]
