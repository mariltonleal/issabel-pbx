# Issabel PBX

Este repositório contém scripts, configurações e personalizações para o sistema Issabel PBX.

## Sobre o Issabel PBX

Issabel é uma plataforma de comunicações unificadas de código aberto baseada em Asterisk. Ele oferece recursos como:

- PABX IP
- Correio de voz
- Fax-to-Email
- Suporte a softphones e telefones IP
- Videoconferência
- Chat integrado
- Call center
- E muito mais

## Estrutura do Repositório

- `/scripts` - Scripts úteis para instalação e manutenção
- `/configs` - Arquivos de configuração
- `/backup` - Rotinas de backup
- `/docs` - Documentação

## Requisitos

- Rocky Linux 8 ou CentOS 7
- Mínimo de 2GB de RAM
- 20GB de espaço em disco
- Conexão à internet para instalação

## Instalação Básica

Para instalar o Issabel PBX em um servidor Rocky Linux 8, siga os passos abaixo:

```bash
# Atualizar o sistema
dnf update -y

# Instalar dependências necessárias
dnf install -y wget

# Baixar o script de instalação do Issabel
wget http://mirror.issabel.org/issabel4/issabel4-netinstall-4.0.0-1.sh

# Dar permissão de execução ao script
chmod +x issabel4-netinstall-4.0.0-1.sh

# Executar o script de instalação
./issabel4-netinstall-4.0.0-1.sh
```

## Configuração de Ramais

Após a instalação, você pode configurar ramais SIP utilizando a interface web ou através de scripts automatizados incluídos neste repositório.

## Segurança

Recomendações de segurança para seu servidor Issabel:

- Alterar senhas padrão
- Configurar firewall adequadamente
- Utilizar certificados SSL
- Implementar autenticação de dois fatores
- Restringir acesso por IP quando possível

## Contribuição

Sinta-se à vontade para contribuir com este projeto através de pull requests, relatórios de bugs ou sugestões de melhorias.

## Licença

Este projeto está sob a licença GPL v3.