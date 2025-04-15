#!/bin/bash

# Script d'installation automatique de Docker avec barre de progression

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérification root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root. Utilisez sudo.${NC}"
    exit 1
fi

# Fonction de barre de progression
progress_bar() {
    local duration=${1}
    local columns=$(tput cols)
    local space=$(( columns - 20 ))
    local increment=$(( duration / space ))
    
    for (( i=0; i<=space; i++ )); do
        printf "${BLUE}⏳ ["
        for (( j=0; j<i; j++ )); do printf "▓"; done
        for (( j=i; j<space; j++ )); do printf " "; done
        printf "] %3d%%${NC}\r" $(( (i * 100) / space ))
        sleep $increment
    done
    printf "\n"
}

# Fonction pour exécuter une commande avec barre de progression
run_with_progress() {
    local cmd=$1
    local msg=$2
    local duration=${3:-3} # Valeur par défaut 3 secondes
    
    echo -e "${YELLOW}${msg}...${NC}"
    eval "$cmd" &>/dev/null &
    local pid=$!
    
    progress_bar $duration
    
    wait $pid
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Succès${NC}"
    else
        echo -e "${RED}✗ Erreur${NC}"
        exit 1
    fi
}

# Début de l'installation
clear
echo -e "${BLUE}=============================================="
echo -e " Installation automatique de Docker - Debian "
echo -e "==============================================${NC}"

# Mise à jour des paquets
run_with_progress "apt-get update -qq" "Mise à jour des paquets" 2

# Installation des dépendances
run_with_progress "apt-get install -y ca-certificates curl" "Installation des dépendances" 3

# Ajout de la clé GPG de Docker
echo -e "${YELLOW}Ajout de la clé GPG de Docker...${NC}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo -e "${GREEN}✓ Succès${NC}"

# Ajout du dépôt Docker
echo -e "${YELLOW}Ajout du dépôt Docker...${NC}"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo -e "${GREEN}✓ Succès${NC}"

# Mise à jour après ajout du dépôt
run_with_progress "apt-get update -qq" "Mise à jour des dépôts" 2

# Installation de Docker
run_with_progress "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Installation de Docker" 10

# Vérification de l'installation
echo -e "${YELLOW}Vérification de l'installation...${NC}"
if docker --version &>/dev/null; then
    echo -e "${GREEN}✓ Docker installé avec succès${NC}"
    echo -e "${BLUE}Version installée : $(docker --version)${NC}"
else
    echo -e "${RED}✗ L'installation de Docker a échoué${NC}"
    exit 1
fi

echo -e "${GREEN}=============================================="
echo -e " Installation terminée avec succès! "
echo -e "==============================================${NC}"