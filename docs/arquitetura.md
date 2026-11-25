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
- `app/services`: casos de uso com mais de um passo (ex.: `QueueItems::Add`, `Playback::Advance`).
- `app/clients/spotify`: cliente HTTP da Spotify Web API, isolado para ser substituído nos testes.
- `app/jobs`: tarefas em background com Solid Queue, no mesmo Postgres e rodando dentro do Puma:
  `CheckPlaybackJob` avança a fila; `ExpirePartiesJob` (a cada 10 min) encerra parties vencidas;
  `DeleteEndedPartiesJob` (a cada hora) apaga os dados de parties encerradas há mais de 24 h.
- Tempo real: `PartyEvents` publica um aviso com `NOTIFY` a cada mudança, e um `LISTEN` por processo
  repassa aos streams SSE abertos (`EventsController`).

## Fluxos principais
1. **Criar party**: o host entra com o Spotify (Authorization Code + PKCE, feito todo no backend) e recebe
   um token da API. Depois escolhe um device e dá um nome à party.
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
| Login do host | OAuth no backend + token Bearer | [0006](adr/0006-autenticacao-do-host.md) |
| Fila | Limite de 5 esperando e ordem justa calculada | [0007](adr/0007-fila-justa.md) |
| Avanço da fila | Job agendado que confere o Spotify antes de agir | [0008](adr/0008-avanco-da-fila.md) |
| Hospedagem | Render gratuito, API em Docker | [0009](adr/0009-hospedagem-render.md) |

## Restrições conhecidas
- O Spotify não aceita `localhost` em redirect URIs, só `127.0.0.1`. Por isso, em dev, o host usa
  frontend e API em `127.0.0.1`. Para testar o convite pelo celular, os dois também escutam no IP do
  notebook no Wi-Fi, e o link de convite usa esse IP (`INVITE_ORIGIN`).
- A Spotify Web API só permite controlar o playback de contas **Premium**. A API guarda o plano do
  host (campo `product` do perfil) a cada login e só deixa criar party se ele for Premium. Apps em modo de
  desenvolvimento aceitam apenas usuários cadastrados no painel do Spotify.
- A Spotify Web API não avisa quando uma música acaba ou quando o host dá play pelo app do Spotify: a
  jukebox precisa perguntar. Por isso o avanço é por job agendado que confere antes de agir
  ([ADR 0008](adr/0008-avanco-da-fila.md)).
- Cada stream SSE aberto ocupa uma thread do Puma (mas não uma conexão do banco). O Puma roda com 32
  threads (`PUMA_MAX_THREADS`) e o pool do banco é separado (`DB_POOL`). Em desenvolvimento, editar o
  código com streams abertos atrasa as requisições até o stream fechar (no máximo 10 s em dev).

## Deploy
No Render gratuito ([`render.yaml`](../render.yaml), [ADR 0009](adr/0009-hospedagem-render.md)): a API como
web service em Docker (com Solid Queue rodando dentro do Puma, em modo `async`), Postgres gerenciado e
site estático para o frontend. A API dorme após 15 min sem requisições.
