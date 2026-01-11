#!/bin/bash
# Script de deploy automatizado para VPS
# Uso: ./deploy.sh [--pull] [--rebuild]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$INFRA_DIR/../portal-backend"
FRONTEND_DIR="$INFRA_DIR/../portal-frontend"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando deploy...${NC}"

# Verificar se estamos no diretório correto
if [ ! -f "$INFRA_DIR/docker-compose.yml" ]; then
    echo -e "${RED}❌ Erro: docker-compose.yml não encontrado${NC}"
    echo "Execute este script de dentro de portal-infra/"
    exit 1
fi

# Opção --pull: atualizar código dos repositórios
if [[ "$*" == *"--pull"* ]]; then
    echo -e "${YELLOW}📥 Atualizando código dos repositórios...${NC}"
    
    if [ -d "$BACKEND_DIR" ]; then
        echo "Atualizando portal-backend..."
        cd "$BACKEND_DIR"
        git pull
    else
        echo -e "${RED}❌ portal-backend não encontrado em $BACKEND_DIR${NC}"
        exit 1
    fi
    
    if [ -d "$FRONTEND_DIR" ]; then
        echo "Atualizando portal-frontend..."
        cd "$FRONTEND_DIR"
        git pull
    else
        echo -e "${RED}❌ portal-frontend não encontrado em $FRONTEND_DIR${NC}"
        exit 1
    fi
fi

# Voltar para infra
cd "$INFRA_DIR"

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    echo "Copie env.example para .env e configure:"
    echo "  cp env.example .env"
    echo "  nano .env"
    exit 1
fi

# Verificar se secrets/google.json existe
if [ ! -f "secrets/google.json" ]; then
    echo -e "${YELLOW}⚠️  Arquivo secrets/google.json não encontrado${NC}"
    echo "Criando diretório secrets/..."
    mkdir -p secrets
    echo "Por favor, copie o arquivo JSON do Google Service Account para secrets/google.json"
    exit 1
fi

# Opção --rebuild: rebuild forçado das imagens
REBUILD_FLAG=""
if [[ "$*" == *"--rebuild"* ]]; then
    REBUILD_FLAG="--build"
    echo -e "${YELLOW}🔨 Rebuild forçado das imagens...${NC}"
fi

# Parar containers existentes
echo -e "${GREEN}🛑 Parando containers...${NC}"
docker-compose down

# Subir containers
echo -e "${GREEN}⬆️  Subindo containers...${NC}"
docker-compose up -d $REBUILD_FLAG

# Aguardar containers iniciarem
echo -e "${GREEN}⏳ Aguardando containers iniciarem...${NC}"
sleep 5

# Verificar saúde dos containers
echo -e "${GREEN}🏥 Verificando saúde dos containers...${NC}"
docker-compose ps

# Testar health check
echo -e "${GREEN}🔍 Testando health check...${NC}"
sleep 3
if curl -f http://localhost/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Health check OK!${NC}"
else
    echo -e "${YELLOW}⚠️  Health check falhou, mas containers podem estar iniciando...${NC}"
    echo "Verifique os logs: docker-compose logs backend"
fi

echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""
echo "Próximos passos:"
echo "1. Verificar logs: docker-compose logs -f"
echo "2. Testar frontend: http://seu-dominio.com"
echo "3. Testar API: http://seu-dominio.com/api/health"