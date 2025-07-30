# Utiliser une version plus récente de Flutter
FROM ubuntu:22.04

# Éviter les interactions pendant l'installation
ENV DEBIAN_FRONTEND=noninteractive

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    android-sdk \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# Télécharger et installer Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /home/developer/flutter

# Ajouter flutter au PATH
ENV PATH="/home/developer/flutter/bin:${PATH}"

# Préconfigurer Flutter
RUN flutter precache
RUN flutter doctor

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers du projet
COPY --chown=developer:developer . .

# Supprimer l'ancien .metadata s'il existe
RUN rm -f .metadata

# Activer le support web et recréer le projet
RUN flutter config --enable-web
RUN flutter create --platforms=web --org com.vegnbio .
RUN flutter pub get

# Exposer le port pour le développement
EXPOSE 3000

# Commande pour lancer l'application en mode développement
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]