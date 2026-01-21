#!/bin/bash
set -e
# Оновлення списку пакетів
sudo apt-get update -y

echo "--- Перевірка та встановлення інструментів ---"

# 1. Встановлення Docker
if ! command -v docker &> /dev/null; then

    echo "--- Встановлення Docker ---"
    
    # Add Docker's official GPG key:
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt-get update -y

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "--- Docker встановлено. ---"
else
    echo "--- Docker вже встановлено: $(docker --version) ---"
fi

# 2. Встановлення Docker Compose
if ! docker compose version &> /dev/null; then
    echo "--- Встановлення Docker Compose. ---"
    sudo apt-get install -y docker-compose-plugin
    echo "--- Docker Compose встановлено. ---"
else
    echo "--- Docker Compose вже встановлено: $(docker compose version) ---"
fi

# 3. Встановлення Python 3
# Використовуємо deadsnakes PPA для отримання найновіших версій на Ubuntu
if ! command -v python3 &> /dev/null; then
    echo "--- Встановлення Python 3. ---"
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-dev
    echo "--- Python 3 встановлено. ---"
else
    echo "--- Python 3 вже встановлено: $(python3 --version) ---"
fi

# 4. Встановлення Pip та Django
# Перевіряємо, чи встановлено Django через модуль python3
if ! command -v django-admin &> /dev/null; then
    echo "--- Встановлення pipx та Django. ---"

    sudo apt-get install -y pipx python3-venv

    pipx ensurepath

    pipx install django

    echo "--- Django встановлено через pipx: ---"
    django-admin --version
else
    echo "--- Django вже встановлено: $(django-admin --version) ---"
fi

echo "--- Встановлення завершено! ---"
