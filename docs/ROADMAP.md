# Roadmap

## Base
- [x] Monorepo com `backend/` (Rails API) e `frontend/` (React + TS)
- [x] Lint, formatação e testes de exemplo nas duas aplicações
- [x] CI no GitHub Actions
- [x] Documentação revisada e ADRs iniciais

## MVP
- [x] **Host via Spotify OAuth**
  - [x] Login com Authorization Code + PKCE, tokens criptografados e renovação automática
  - [x] Escolha de device e criação da party (só Premium, uma party ativa por host)
- [x] **Convite**: link único + QR code; participante entra sem login e recebe token anônimo
- [x] **Fila**: busca no Spotify, até 5 músicas esperando por participante (host incluso), sem
  duplicatas e sem 3 seguidas da mesma pessoa quando há outras na fila ([ADR 0007](adr/0007-fila-justa.md))
- [ ] **Playback**: avanço automático ao fim da faixa; pular e remover item só pelo host
- [ ] **Tempo real e ciclo de vida**: eventos SSE, encerramento manual e expiração da party

## Depois do MVP
- [ ] Votação para pular faixa
- [ ] Busca de faixas com cache
- [ ] Histórico de parties do host
- [ ] Rate limiting por participante
- [ ] Avaliar: host reordenar a fila (hoje a ordem é calculada pela regra justa)
- [ ] Deploy contínuo no Render
