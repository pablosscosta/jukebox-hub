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
- [x] **Hospedagem**: no ar no Render gratuito, com a API em Docker
  ([ADR 0009](adr/0009-hospedagem-render.md)); conta Spotify não liberada vê como pedir acesso
- [x] **Acabamento visual**: tema escuro com verde, "Tocando agora" com capa e progresso, layout pensado
  para o celular e botões com alvo de toque de 44 px

## Depois do MVP
- [ ] Identidade visual: logo e favicon próprios (hoje o site usa o ícone padrão do Vite), usados também
  no README e no link compartilhado (Open Graph). As cores e o tema escuro já estão definidos.
- [ ] Votação para pular faixa
- [ ] Busca de faixas com cache
- [ ] Histórico de parties do host
- [ ] Rate limiting por participante
- [ ] Avaliar: host reordenar a fila (hoje a ordem é calculada pela regra justa)
- [ ] Playlist de fundo: quando a fila acaba, tocar uma playlist escolhida pelo host (`context_uri`) até
  alguém adicionar uma música. Hoje a música para: o Autoplay do Spotify só continua a partir de um
  álbum ou playlist, e a jukebox toca músicas avulsas. A API de recomendações do Spotify não está
  disponível para apps novos.
- [ ] Avaliar: botões "Tocar a seguir" e "Tocar agora" na busca, só para o host
- [ ] Avaliar: transição sem silêncio entre músicas
- [ ] Avaliar: Web Playback SDK (a aba da Jukebox Hub como player, sem o app do Spotify)
- [ ] Servidor que não dorme, se o app crescer (VM da Oracle com Kamal ou plano pago)
- [ ] Avaliar: pedido de acesso de hosts (formulário e lista de pendentes para o admin). A liberação em
  si continua manual no painel do Spotify, que não tem API para isso
