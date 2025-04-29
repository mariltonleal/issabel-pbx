# Manual do Issabel PBX

Este manual contém instruções para instalação, configuração e administração do Issabel PBX.

## Índice

1. [Instalação](#instalação)
2. [Configuração Inicial](#configuração-inicial)
3. [Gerenciamento de Ramais](#gerenciamento-de-ramais)
4. [Troncos SIP](#troncos-sip)
5. [Filas de Atendimento](#filas-de-atendimento)
6. [Backup e Restauração](#backup-e-restauração)
7. [Segurança](#segurança)
8. [Troubleshooting](#troubleshooting)

## Instalação

### Requisitos Mínimos

- Processador: 2 cores
- Memória RAM: 2GB
- Espaço em disco: 20GB
- Rocky Linux 8 ou CentOS 7

### Passos de Instalação

1. Instale o Rocky Linux 8 com uma instalação mínima
2. Atualize o sistema:
   ```bash
   dnf update -y
   ```
3. Execute o script de instalação:
   ```bash
   ./scripts/install_issabel.sh
   ```
4. Após a instalação, acesse a interface web através de http://IP_DO_SERVIDOR

## Configuração Inicial

Após a primeira instalação, é necessário configurar:

1. **Rede**: Configure o endereço IP estático
2. **Fuso Horário**: Defina o fuso horário correto para seu local
3. **Senhas**: Altere as senhas padrão (admin/admin)
4. **Email**: Configure as notificações por email

## Gerenciamento de Ramais

### Criação de Ramais via Web

1. Acesse o painel administrativo
2. Navegue até "PBX > Extensions"
3. Clique em "Add Extension" e selecione "Generic SIP Device"
4. Preencha as informações necessárias:
   - Extension: número do ramal
   - Display Name: nome do usuário
   - Secret: senha do ramal
5. Clique em "Submit" e depois "Apply Config"

### Criação de Ramais via Script

Use o script `criar_ramal.sh` para criar ramais pelo terminal:

```bash
./scripts/criar_ramal.sh 1001 "João Silva" senha123 joao@empresa.com
```

### Configuração de Softphones

Para configurar um softphone (X-Lite, Zoiper, etc):

1. Servidor: IP do servidor Issabel
2. Usuário: número do ramal
3. Senha: senha configurada para o ramal
4. Porta: 5060 (padrão)
5. Protocolo: UDP

## Troncos SIP

### Configuração de Troncos

1. Acesse "PBX > Trunks"
2. Clique em "Add SIP Trunk"
3. Configure os parâmetros conforme fornecido pelo seu provedor VoIP:
   - Trunk Name: nome identificador
   - Outbound Caller ID: ID de chamadas saintes
   - Maximum Channels: limite de canais simultâneos
   - Parâmetros de autenticação

## Filas de Atendimento

### Criação de Filas

1. Acesse "PBX > Queues"
2. Clique em "Add Queue"
3. Configure:
   - Queue Number: número da fila (ex: 600)
   - Queue Name: nome descritivo
   - Strategy: estratégia de distribuição (ringall, roundrobin, etc)
   - Static Agents: ramais membros da fila

## Backup e Restauração

### Backup Automático

Configure backups automáticos usando o script `backup_issabel.sh`:

```bash
# Adicione ao crontab para execução diária
0 2 * * * /caminho/scripts/backup_issabel.sh
```

Para backup com envio para servidor remoto:

```bash
/caminho/scripts/backup_issabel.sh user@servidor:/diretorio/backup
```

### Restauração

Para restaurar um backup:

1. Copie o arquivo de backup para o servidor
2. Descompacte: `tar -xzf backup_file.tar.gz -C /`
3. Restaure o banco de dados: `mysql -u root -p < backup_mysql.sql`
4. Reinicie os serviços: `systemctl restart asterisk`

## Segurança

### Recomendações

1. **Firewall**: Configure o firewall permitindo apenas portas necessárias
   ```bash
   firewall-cmd --permanent --add-service=http
   firewall-cmd --permanent --add-service=https
   firewall-cmd --permanent --add-port=5060/udp
   firewall-cmd --permanent --add-port=10000-20000/udp
   firewall-cmd --reload
   ```

2. **Senhas Fortes**: Use senhas complexas para ramais e painel administrativo
3. **Fail2Ban**: Configure para bloquear tentativas de invasão
4. **Acesso Restrito**: Limite o acesso ao painel admin por IP
5. **HTTPS**: Configure HTTPS para o painel administrativo

## Troubleshooting

### Problemas Comuns

1. **Ramal não registra**:
   - Verifique as configurações de NAT
   - Confirme se as credenciais estão corretas
   - Teste a conectividade (porta UDP 5060)

2. **Áudio unidirecional**:
   - Problema geralmente relacionado a NAT/Firewall
   - Verifique as configurações de NAT no sip.conf
   - Garanta que as portas RTP (10000-20000) estejam abertas

3. **Verificar logs**:
   - Logs do Asterisk: `tail -f /var/log/asterisk/full`
   - Logs do sistema: `journalctl -u asterisk`

4. **Console Asterisk**:
   - Acesse o console: `asterisk -rvvv`
   - Verifique ramais ativos: `sip show peers`
   - Verifique registros: `sip show registry`