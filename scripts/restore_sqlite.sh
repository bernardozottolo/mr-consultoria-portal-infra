#!/bin/bash
# Script de restore do SQLite e planilhas
# Restaura backup do volume backend-data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$INFRA_DIR/backups"
VOLUME_DIR="$INFRA_DIR/volumes/backend-data"

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo "❌ Uso: $0 <arquivo_backup.tar.gz>"
    echo ""
    echo "Backups disponíveis:"
    ls -lh "$BACKUP_DIR" 2>/dev/null || echo "Nenhum backup encontrado"
    exit 1
fi

BACKUP_FILE="$1"

# Se caminho relativo, assumir que está em backups/
if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

# Verificar se o arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Erro: Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  ATENÇÃO: Esta operação irá substituir o banco de dados atual!"
echo "📁 Backup: $BACKUP_FILE"
echo "📁 Destino: $VOLUME_DIR"
echo ""
read -p "Deseja continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Restore cancelado"
    exit 1
fi

# Parar containers se estiverem rodando
echo "🛑 Parando containers..."
cd "$INFRA_DIR"
docker-compose stop backend 2>/dev/null || true

# Criar diretório de volumes se não existir
mkdir -p "$VOLUME_DIR"

# Fazer backup do estado atual (safety)
CURRENT_BACKUP="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
if [ -f "$VOLUME_DIR/database.db" ]; then
    echo "💾 Criando backup de segurança do estado atual..."
    cd "$VOLUME_DIR"
    tar -czf "$CURRENT_BACKUP" database.db* spreadsheets/ 2>/dev/null || true
fi

# Extrair backup
echo "📦 Extraindo backup..."
cd "$VOLUME_DIR"
tar -xzf "$BACKUP_FILE"

# Ajustar permissões
chmod 644 database.db* 2>/dev/null || true
chmod -R 755 spreadsheets/ 2>/dev/null || true

echo "✅ Restore concluído!"
echo "🔄 Reiniciando containers..."
cd "$INFRA_DIR"
docker-compose up -d backend

echo ""
echo "✅ Restore finalizado com sucesso!"
echo "💾 Backup de segurança criado em: $CURRENT_BACKUP"
