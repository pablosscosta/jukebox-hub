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
- [x] **Playback**: avanço automático ao fim da faixa; pular, remover e tocar só pelo host; música
  tocada direto no app do Spotify "fura a fila" ([ADR 0008](adr/0008-avanco-da-fila.md))
- [x] **Tempo real e ciclo de vida**: fila ao vivo por SSE, encerramento pelo host, expiração após 6 h
  sem atividade e limpeza dos dados ([ADR 0004](adr/0004-sse-com-postgres-listen-notify.md))
- [ ] **Hospedagem**: escolher o servidor gratuito (os jobs não podem "dormir") e registrar em ADR
- [x] **Acabamento visual**: tema escuro com verde, "Tocando agora" com capa e progresso, layout pensado
  para o celular e botões com alvo de toque de 44 px

## Depois do MVP
- [ ] Votação para pular faixa
- [ ] Busca de faixas com cache
- [ ] Histórico de parties do host
- [ ] Rate limiting por participante
- [ ] Avaliar: host reordenar a fila (hoje a ordem é calculada pela regra justa)
- [ ] Avaliar: botões "Tocar a seguir" e "Tocar agora" na busca, só para o host
- [ ] Avaliar: transição sem silêncio entre músicas
- [ ] Avaliar: Web Playback SDK (a aba da Jukebox Hub como player, sem o app do Spotify)
- [ ] Deploy contínuo no Render
