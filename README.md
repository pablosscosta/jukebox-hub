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

## Documentação
Documentos adicionais estão disponíveis em `docs/`:
- [Arquitetura](docs/arquitetura.md)
- [API](docs/api.md)
- [Modelo Conceitual](docs/modelo-conceitual.md)
