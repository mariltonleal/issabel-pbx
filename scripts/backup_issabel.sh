#!/bin/bash
# Script para backup do Issabel PBX
# Autor: Marilton Leal
# Data: 29/04/2025

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Este script precisa ser executado como root"
    exit 1
fi

# Data atual para nome do arquivo
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/issabel"
BACKUP_FILE="${BACKUP_DIR}/issabel_backup_${DATE}.tar.gz"
MYSQL_BACKUP="${BACKUP_DIR}/mysql_backup_${DATE}.sql"
REMOTE_BACKUP=${1:-""}

# Criar diretório de backup se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    log "Criando diretório de backup $BACKUP_DIR..."
    mkdir -p $BACKUP_DIR
fi

# Variáveis para conexão com o banco de dados
MYSQL_USER="root"
MYSQL_PASS=$(cat /etc/issabel.conf | grep "mysqlrootpwd" | cut -d"=" -f2)

log "Iniciando backup do Issabel PBX..."

# Backup das bases de dados
log "Fazendo backup dos bancos de dados..."
databases="asterisk asteriskcdrdb"
mysqldump -u${MYSQL_USER} -p${MYSQL_PASS} --databases $databases > $MYSQL_BACKUP

if [ $? -ne 0 ]; then
    error "Erro ao fazer backup do banco de dados"
    exit 1
fi

# Compactar arquivos importantes
log "Compactando arquivos de configuração..."
tar -czf $BACKUP_FILE \
    /etc/asterisk \
    /etc/issabel.conf \
    /var/lib/asterisk/moh \
    /var/lib/asterisk/sounds \
    /var/spool/asterisk/voicemail \
    /var/www/html/admin/modules \
    /var/www/html/recordings \
    $MYSQL_BACKUP

if [ $? -ne 0 ]; then
    error "Erro ao criar arquivo de backup"
    rm -f $MYSQL_BACKUP
    exit 1
fi

# Remover arquivo SQL temporário
rm -f $MYSQL_BACKUP

# Verificar tamanho do backup
BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)
log "Backup concluído. Tamanho do arquivo: $BACKUP_SIZE"
log "Localização do arquivo de backup: $BACKUP_FILE"

# Rotação de backups (manter apenas os 5 últimos)
log "Realizando rotação de backups (mantendo os 5 mais recentes)..."
ls -t ${BACKUP_DIR}/issabel_backup_*.tar.gz | tail -n +6 | xargs -r rm

# Enviar para backup remoto se especificado
if [ ! -z "$REMOTE_BACKUP" ]; then
    log "Enviando backup para destino remoto: $REMOTE_BACKUP"
    
    # Verificar formato do destino remoto (user@host:/path)
    if [[ $REMOTE_BACKUP =~ ^[a-zA-Z0-9]+@[a-zA-Z0-9\.]+:.+$ ]]; then
        scp $BACKUP_FILE $REMOTE_BACKUP
        
        if [ $? -eq 0 ]; then
            log "Backup enviado com sucesso para $REMOTE_BACKUP"
        else
            error "Falha ao enviar backup para $REMOTE_BACKUP"
        fi
    else
        error "Formato inválido para destino remoto. Use: user@host:/path"
    fi
fi

log "Processo de backup concluído com sucesso."

# Definir permissões corretas
chmod 600 $BACKUP_FILE
log "Permissões do arquivo de backup ajustadas."