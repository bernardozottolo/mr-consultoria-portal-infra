#!/bin/bash
# Script de backup do SQLite e planilhas
# Backup do volume backend-data (database.db + spreadsheets/)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$INFRA_DIR/backups"
VOLUME_DIR="$INFRA_DIR/volumes/backend-data"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"

# Criar diretório de backups se não existir
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando backup..."

# Verificar se o diretório de volumes existe
if [ ! -d "$VOLUME_DIR" ]; then
    echo "❌ Erro: Diretório de volumes não encontrado: $VOLUME_DIR"
    exit 1
fi

# Criar backup tar.gz
cd "$VOLUME_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    database.db \
    database.db-wal \
    database.db-shm \
    spreadsheets/ 2>/dev/null || {
    # Se algum arquivo não existir, continuar mesmo assim
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
        database.db* \
        spreadsheets/ 2>/dev/null || true
}

# Verificar se o backup foi criado
if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
    echo "✅ Backup criado com sucesso: $BACKUP_NAME ($BACKUP_SIZE)"
    echo "📍 Localização: $BACKUP_DIR/$BACKUP_NAME"
    
    # Listar últimos 5 backups
    echo ""
    echo "📦 Últimos 5 backups:"
    ls -lh "$BACKUP_DIR" | tail -6 | head -5
else
    echo "❌ Erro: Falha ao criar backup"
    exit 1
fi
