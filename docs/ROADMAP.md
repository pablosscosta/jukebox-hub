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
- [ ] **Fila**: FIFO, sem duplicatas simultâneas, máx. 2 músicas consecutivas por participante
- [ ] **Playback**: avanço automático ao fim da faixa; pular e remover item só pelo host
- [ ] **Tempo real e ciclo de vida**: eventos SSE, encerramento manual e expiração da party

## Depois do MVP
- [ ] Votação para pular faixa
- [ ] Busca de faixas com cache
- [ ] Histórico de parties do host
- [ ] Rate limiting por participante
- [ ] Deploy contínuo no Render
