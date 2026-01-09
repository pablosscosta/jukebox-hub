# Jukebox Hub

## Visão Geral
Jukebox Hub é um sistema de jukebox colaborativa integrada ao Spotify.  
Um usuário host autentica via Spotify e controla a reprodução em um dispositivo ativo.  
Ao criar a sessão, o host atribui um nome e recebe um link/QR code para compartilhamento.  
Participantes acessam esse link/QR code e podem adicionar músicas à fila, respeitando regras de negócio.

## Tecnologias
- Backend: Ruby on Rails
- Frontend: React
- Banco de dados: PostgreSQL
- Autenticação: Spotify OAuth
- Arquitetura: API-first, camadas

## Escopo do MVP
- Criar sessão vinculada ao host (Spotify + device_id)
- Atribuir nome à sessão e gerar link/QR code para compartilhamento
- Participantes acessam via link/QR code e adicionam músicas à fila (limite de músicas consecutivas por dispositivo, sem duplicatas)
- Playback básico (play/next) controlado pelo backend
- Atualizações em tempo real via SSE
- Encerrar sessão

## Status do Projeto
Backend MVP implementado em Ruby on Rails.  
Funcionalidades básicas: sessões, usuários, fila de músicas e marcação de músicas como tocadas.


## Como Executar
### Pré-requisitos

Certifique-se de ter os seguintes componentes instalados e configurados:

- [Ruby](https://www.ruby-lang.org/en/documentation/installation/)  
- [Rails](https://guides.rubyonrails.org/getting_started.html)  
- [PostgreSQL](https://www.postgresql.org/download/)  

Verifique se o PostgreSQL está rodando localmente antes de iniciar o servidor Rails.  
Documentação oficial sobre inicialização e gerenciamento do servidor: [https://www.postgresql.org/docs/current/app-pg-ctl.html](https://www.postgresql.org/docs/current/app-pg-ctl.html)

- Dependências instaladas (instala todas as gems listadas no Gemfile):

```
bundle install
```
### Configuração do banco
- Criação e migração:
```
rails db:create
rails db:migrate
```

### Subir o servidor
- Inicie o servidor Rails
```
rails s
```
- O backend estará disponível em `http://localhost:3000.`

## Documentação
Documentos adicionais estão disponíveis em `docs/`:
- [Arquitetura](docs/arquitetura.md)
- [API](docs/api.md)
- [Modelo Conceitual](docs/modelo-conceitual.md)
