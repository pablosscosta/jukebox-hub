# Arquitetura

## Visão geral
Monorepo com duas aplicações independentes ([ADR 0001](adr/0001-monorepo.md)):

- `backend/`: API em Ruby on Rails (modo API) com PostgreSQL.
- `frontend/`: SPA em React + TypeScript (Vite).

```text
Navegador (React) ──HTTP/JSON──> Rails API ──> PostgreSQL
        ▲                          │  └──────> Spotify Web API (token do host)
        └────────── SSE ───────────┘
```

## Organização do backend
Segue as convenções do Rails, sem camadas extras:

- `app/controllers`: controllers enxutos, que só recebem a requisição e formatam a resposta.
- `app/models`: entidades (`Party`, `Participant`, `QueueItem`), validações e regras simples.
- `app/services`: casos de uso com mais de um passo (ex.: `Queue::AddTrack`, `Playback::Advance`).
- `app/clients/spotify`: cliente HTTP da Spotify Web API, isolado para ser substituído nos testes.
- `app/jobs`: tarefas em background com Solid Queue (avançar faixa, expirar parties).

## Fluxos principais
1. **Criar party**: o host autentica via Spotify OAuth (Authorization Code + PKCE), escolhe um device e dá um nome à party.
2. **Compartilhar**: a API devolve o link de convite; o QR code é gerado a partir dele.
3. **Entrar e adicionar músicas**: o participante abre o link, recebe um token anônimo e adiciona faixas à fila.
4. **Reprodução automática**: o backend manda o Spotify tocar a próxima faixa ao fim da atual, usando o token do host.
5. **Encerrar**: o host encerra a party, ou ela expira sozinha.

## Decisões técnicas
| Tema | Decisão | ADR |
| --- | --- | --- |
| Repositório | Monorepo `backend/` + `frontend/` | [0001](adr/0001-monorepo.md) |
| Persistência | PostgreSQL; "efêmero" é regra de expiração | [0002](adr/0002-postgresql-party-efemera.md) |
| Nomes | `Party` e `Participant` | [0003](adr/0003-nomes-party-participant.md) |
| Tempo real | SSE + Postgres `LISTEN/NOTIFY` | [0004](adr/0004-sse-com-postgres-listen-notify.md) |
| Testes | RSpec + FactoryBot | [0005](adr/0005-rspec-factorybot.md) |

## Restrições conhecidas
- A Spotify Web API só permite controlar o playback de contas **Premium**. Apps em modo de
  desenvolvimento aceitam apenas usuários cadastrados no painel do Spotify.
- Cada conexão SSE ocupa uma thread do Puma. O número de threads (`RAILS_MAX_THREADS`) e o
  heartbeat/timeout das conexões precisam ser dimensionados.

## Deploy
No Render ([`render.yaml`](../render.yaml)): web service para a API (com Solid Queue rodando dentro do
Puma), Postgres gerenciado e static site para o frontend.
