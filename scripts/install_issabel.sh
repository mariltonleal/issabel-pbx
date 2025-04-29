#!/bin/bash
# Script para instalação do Issabel PBX em Rocky Linux 8
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

# Verificar se é Rocky Linux 8
if ! grep -q "Rocky Linux release 8" /etc/rocky-release 2>/dev/null; then
    error "Este script é destinado ao Rocky Linux 8"
    exit 1
fi

log "Iniciando instalação do Issabel PBX..."

# Desativar SELinux
log "Desativando SELinux..."
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Atualizar o sistema
log "Atualizando o sistema..."
dnf update -y

# Instalar dependências
log "Instalando dependências..."
dnf install -y wget net-tools nmap

# Configurar firewall
log "Configurando firewall..."
systemctl enable firewalld
systemctl start firewalld

# Abrir portas necessárias
log "Abrindo portas necessárias no firewall..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=5060/udp
firewall-cmd --permanent --add-port=5060/tcp
firewall-cmd --permanent --add-port=10000-20000/udp
firewall-cmd --reload

# Baixar o script de instalação do Issabel
log "Baixando script de instalação do Issabel..."
wget http://mirror.issabel.org/issabel4/issabel4-netinstall-4.0.0-1.sh

# Dar permissão de execução ao script
log "Configurando permissões..."
chmod +x issabel4-netinstall-4.0.0-1.sh

# Executar o script de instalação
log "Executando instalação do Issabel..."
./issabel4-netinstall-4.0.0-1.sh

# Verificar se a instalação foi bem-sucedida
if [ $? -eq 0 ]; then
    log "Instalação do Issabel concluída com sucesso!"
    log "Acesse a interface web através de http://SEU_IP"
    log "Usuário padrão: admin"
    log "Senha padrão: admin"
    warning "IMPORTANTE: Altere a senha padrão imediatamente após o primeiro acesso!"
else
    error "Houve um problema na instalação do Issabel."
    error "Consulte os logs para mais detalhes."
fi

# Fazer backup inicial da configuração
log "Criando backup inicial..."
mkdir -p /backup
tar -czf /backup/issabel_initial_backup_$(date +%Y%m%d).tar.gz /etc/asterisk

log "Script de instalação concluído."