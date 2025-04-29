#!/bin/bash
# Script para criar ramais SIP no Issabel PBX
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

# Verificar se o MySQL está instalado
if ! command -v mysql &> /dev/null; then
    error "MySQL não está instalado. Verifique sua instalação do Issabel."
    exit 1
fi

# Verificar argumentos
if [ $# -lt 3 ]; then
    error "Uso: $0 <número_ramal> <nome_ramal> <senha_ramal> [email_ramal]"
    error "Exemplo: $0 1001 \"João Silva\" minhasenha joao@empresa.com"
    exit 1
fi

NUMERO_RAMAL=$1
NOME_RAMAL=$2
SENHA_RAMAL=$3
EMAIL_RAMAL=${4:-""}

# Variáveis para conexão com o banco de dados
MYSQL_USER="root"
MYSQL_PASS=$(cat /etc/issabel.conf | grep "mysqlrootpwd" | cut -d"=" -f2)
ASTERISK_DB="asterisk"

# Verificar se o ramal já existe
RAMAL_EXISTE=$(mysql -u${MYSQL_USER} -p${MYSQL_PASS} -D${ASTERISK_DB} -se "SELECT extension FROM users WHERE extension='${NUMERO_RAMAL}'")

if [ ! -z "$RAMAL_EXISTE" ]; then
    error "O ramal ${NUMERO_RAMAL} já existe no sistema!"
    exit 1
fi

log "Criando ramal SIP ${NUMERO_RAMAL} para ${NOME_RAMAL}..."

# Gerar hash MD5 para autenticação SIP
MD5_HASH=$(echo -n "${NUMERO_RAMAL}:asterisk:${SENHA_RAMAL}" | md5sum | cut -d' ' -f1)

# Adicionar ramal no FreePBX/Issabel
mysql -u${MYSQL_USER} -p${MYSQL_PASS} -D${ASTERISK_DB} << EOF
-- Inserir na tabela de usuários
INSERT INTO users (extension, password, name, voicemail, ringtimer, noanswer, recording, outboundcid, sipname, noanswer_cid, busy_cid, chanunavail_cid, noanswer_dest, busy_dest, chanunavail_dest, mohclass, id, tech, dial, devicetype, user_agent, emergency_cid, call_screen, cid_masquerade, concurrency_limit, callwaiting, email) 
VALUES ('${NUMERO_RAMAL}', '${SENHA_RAMAL}', '${NOME_RAMAL}', 'default', 0, '', 'out=always,in=always', '', '', '', '', '', '', '', '', 'default', NULL, 'sip', 'SIP/${NUMERO_RAMAL}', 'fixed', '', '', 0, '', 0, 'enabled', '${EMAIL_RAMAL}');

-- Inserir na tabela de dispositivos SIP
INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'secret', '${SENHA_RAMAL}', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'md5secret', '${MD5_HASH}', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'account', '${NUMERO_RAMAL}', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'callerid', '${NOME_RAMAL} <${NUMERO_RAMAL}>', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'mailbox', '${NUMERO_RAMAL}@device', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'host', 'dynamic', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'nat', 'yes', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'type', 'friend', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'context', 'from-internal', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'dtmfmode', 'rfc2833', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'allow', 'ulaw,alaw', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'callgroup', '', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'pickupgroup', '', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'disallow', 'all', 2);

INSERT INTO sip (id, keyword, data, flags) 
VALUES ('${NUMERO_RAMAL}', 'videosupport', 'no', 2);
EOF

# Verificar se a inserção foi bem-sucedida
if [ $? -eq 0 ]; then
    log "Ramal ${NUMERO_RAMAL} criado com sucesso!"
    
    # Recarregar configuração do Asterisk
    log "Recarregando configuração do Asterisk..."
    asterisk -rx "module reload"
    asterisk -rx "sip reload"
    
    # Exibir informações do ramal
    log "Detalhes do ramal:"
    log "Número: ${NUMERO_RAMAL}"
    log "Nome: ${NOME_RAMAL}"
    log "Senha: ${SENHA_RAMAL}"
    if [ ! -z "$EMAIL_RAMAL" ]; then
        log "Email: ${EMAIL_RAMAL}"
    fi
    
    warning "Lembre-se de configurar seu softphone ou telefone IP com essas informações."
else
    error "Ocorreu um erro ao criar o ramal. Verifique os logs do MySQL."
fi

# Fazer backup após a criação
log "Criando backup da configuração..."
tar -czf /backup/issabel_backup_after_extension_${NUMERO_RAMAL}_$(date +%Y%m%d).tar.gz /etc/asterisk

log "Script concluído."