# Arquitetura

## Estilo
- API-first
- Arquitetura em camadas:
  - Controllers (API)
  - Application (casos de uso)
  - Domain (entidades e regras)
  - Infrastructure (Spotify client, storage, SSE)

## Fluxos Principais
1. Criar sessão (host autentica via Spotify, seleciona device e atribui nome)
2. Gerar link único e QR code para compartilhamento da sessão
3. Participantes acessam via link/QR code e adicionam músicas à fila
4. Reprodução automática (avança ao fim da faixa)
5. Encerrar sessão

## Decisões Técnicas
- Sessão efêmera (in-memory)
- Playback controlado pelo backend usando token do host
- SSE para atualizações em tempo real
- Regras de negócio:
  - Fila FIFO
  - Sem duplicatas simultâneas
  - Limite de músicas consecutivas por dispositivo/usuário
