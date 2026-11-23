# 0004 — Tempo real com SSE e Postgres `LISTEN/NOTIFY`

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
Os participantes precisam ver a fila e a faixa atual mudarem ao vivo. A comunicação é só do servidor
para o cliente: as ações (adicionar música, pular) já são requisições HTTP normais.

## Decisão
- **SSE** com `ActionController::Live` em `GET /parties/:id/events`. No cliente, `EventSource` nativo,
  que já reconecta sozinho.
- Para que um evento gerado em um processo chegue a conexões abertas em outro, a aplicação publica com
  `NOTIFY party_<id>` e cada stream escuta com `LISTEN` no PostgreSQL.

## Consequências
- Nenhuma dependência nova (sem Redis, sem biblioteca de WebSocket no cliente).
- Cada conexão SSE ocupa uma thread do Puma e uma conexão do banco. É preciso dimensionar
  `RAILS_MAX_THREADS` e o pool, mandar heartbeat e limitar o tempo de vida da conexão.
- Descartados: Action Cable (bidirecional, mais complexidade do que o caso precisa) e polling (latência e carga).
- Se a escala crescer, a troca por Action Cable ou por um serviço dedicado fica isolada no publisher de eventos.
