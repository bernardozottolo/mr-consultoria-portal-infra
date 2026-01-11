# Guia de Deploy - Portal MR Consultoria

## Pré-requisitos na VPS

1. **Docker e Docker Compose instalados**
   # Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   sudo apt install docker-compose-plugin -y
   
   # Ou instalar docker-compose standalone
   sudo apt install docker-compose -y
   