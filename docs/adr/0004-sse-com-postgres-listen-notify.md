# 0004 — Tempo real com SSE e Postgres `LISTEN/NOTIFY`

- **Status:** aceito (revisado em 2026-11-25, ao implementar)
- **Data:** 2026-11-23

## Contexto
Os participantes precisam ver a fila e a faixa atual mudarem ao vivo. A comunicação é só do servidor
para o cliente: as ações (adicionar música, pular) já são requisições HTTP normais.

## Decisão
- **SSE** com `ActionController::Live` em `GET /parties/:id/events`. No cliente, `EventSource` nativo,
  que já reconecta sozinho.
- **O stream manda só um aviso curto**, sem dados: `queue_changed` ou `party_ended`. A cada aviso (e a
  cada reconexão), a tela recarrega a fila pela API normal, com o próprio token. Motivo: o
  `EventSource` não envia o header `Authorization`; se o stream carregasse a fila, o token teria que ir
  na URL, onde aparece em logs e no histórico. Como o aviso não revela nada, o stream não pede token.
- **Toda mudança gravada na fila ou na party dispara `NOTIFY`** num canal único (`party_events`), com o
  id da party no payload. O `NOTIFY` roda dentro da transação: o Postgres só entrega depois do commit,
  descarta o aviso se a mudança for desfeita e junta avisos iguais da mesma transação.
- **Um único `LISTEN` por processo** (`PartyEvents::Listener`), que repassa cada aviso aos streams
  daquela party por uma fila em memória. Os streams não seguram conexão do banco enquanto esperam.
- Heartbeat a cada 15 s e conexão renovada a cada 5 min (30 s em desenvolvimento). Enquanto há um
  stream aberto, o heartbeat também é o momento de conferir o Spotify, no máximo uma vez a cada 20 s
  por party ([ADR 0008](0008-avanco-da-fila.md)).

## Consequências
- Nenhuma dependência nova (sem Redis, sem biblioteca de WebSocket no cliente).
- Cada stream aberto ocupa uma thread do Puma, mas nenhuma conexão do banco: o Puma roda com 32 threads,
  e o pool do banco é configurado à parte (`PUMA_MAX_THREADS` e `DB_POOL`).
- Cada aviso faz cada tela buscar a fila de novo: mais requisições do que mandar os dados no stream,
  mas são leituras simples, autenticadas e já testadas.
- Em desenvolvimento, o Rails só recarrega código alterado depois que as requisições abertas terminam;
  por isso o stream dura pouco em dev.
- Descartados: Action Cable (bidirecional, mais complexidade do que o caso precisa), polling (latência e
  carga) e um `LISTEN` por stream (esgotaria o pool do banco numa festa com muitos celulares).
- Se a escala crescer, a troca por Action Cable ou por um serviço dedicado fica isolada em `PartyEvents`.
