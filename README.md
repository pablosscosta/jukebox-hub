# Jukebox Hub

Jukebox colaborativa integrada ao Spotify: o host toca a música no próprio dispositivo e os convidados de
uma festa escolhem a próxima faixa pelo celular, sem precisar de conta.

[![CI](https://github.com/pablosscosta/jukebox-hub/actions/workflows/ci.yml/badge.svg)](https://github.com/pablosscosta/jukebox-hub/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Ruby](https://img.shields.io/badge/Ruby-4.0-CC342D?logo=ruby)
![Rails](https://img.shields.io/badge/Rails-8.1-D30001?logo=rubyonrails)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)
![TypeScript](https://img.shields.io/badge/TypeScript-strict-3178C6?logo=typescript)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql)

> **Status:** reescrita (v2) em andamento. A base do projeto está pronta e as funcionalidades do MVP
> estão sendo implementadas uma a uma ([ROADMAP](docs/ROADMAP.md)). A versão anterior está na tag
> `v0-legado`.

## Demonstração
> **TODO:** adicionar o link do deploy no Render e um GIF do fluxo (host cria a party → convidado
> adiciona uma música) em `docs/assets/`.

## Funcionalidades
Já funciona:
- Base da API Rails (health check em `GET /up`) e da SPA React.
- Lint, testes e checagens de segurança rodando no CI.

Planejado para o MVP ([ROADMAP](docs/ROADMAP.md)):
- Host autentica com Spotify (OAuth + PKCE) e cria uma party ligada a um dispositivo.
- Convite por link e QR code; convidado entra sem login.
- Fila FIFO sem músicas duplicadas e com no máximo 2 músicas seguidas por convidado.
- Avanço automático de faixa controlado pelo backend; só o host pula, remove ou encerra.
- Fila e faixa atual atualizadas ao vivo via SSE.

## Tecnologias
| Tecnologia | Por quê |
| --- | --- |
| Ruby on Rails 8.1 (API) | Convenções fortes e produtividade para uma API REST com regras de negócio |
| PostgreSQL | Regras críticas (ex.: sem duplicatas) garantidas por constraints; `LISTEN/NOTIFY` para tempo real sem Redis |
| React 19 + TypeScript strict | SPA pensada para celular, com tipos protegendo o contrato com a API |
| Vite | Dev server e build rápidos, sem configuração extra |
| RSpec + FactoryBot + WebMock | Request specs legíveis; Spotify sempre simulado nos testes |
| Vitest + Testing Library | Testes de comportamento do usuário, integrados ao Vite |
| GitHub Actions + Render | CI em todo PR; deploy de API, banco e site estático declarado em `render.yaml` |

## Arquitetura
```mermaid
flowchart LR
  Guest[Convidado / Host<br/>React SPA] -- HTTP JSON --> API[Rails API]
  API -- SSE --> Guest
  API --> DB[(PostgreSQL)]
  API -- token do host --> Spotify[Spotify Web API]
```

Monorepo com duas aplicações independentes: `backend/` e `frontend/`. A API é a única que fala com o
Spotify, usando o token do host, então os convidados nunca precisam de conta. Os eventos de fila e
playback chegam aos navegadores por SSE e são distribuídos entre processos pelo `LISTEN/NOTIFY` do
Postgres. Mais detalhes em [docs/arquitetura.md](docs/arquitetura.md),
[docs/modelo-conceitual.md](docs/modelo-conceitual.md) e [docs/api.md](docs/api.md).

## Como rodar localmente
### Pré-requisitos
- Ruby 4.0.10 (versão em `backend/.ruby-version`; recomendado instalar com [mise](https://mise.jdx.dev/))
- Node.js 24 (`.nvmrc`)
- PostgreSQL 16 rodando localmente

### Variáveis de ambiente
Veja `backend/.env.example`. Por padrão, o backend conecta no Postgres local pelo socket Unix, com o
seu usuário do sistema. Para conectar por TCP, exporte `DATABASE_HOST`, `DATABASE_USERNAME` e
`DATABASE_PASSWORD`.

### Backend
```bash
cd backend
bin/setup --skip-server   # instala as gems e cria o banco
bin/dev                   # http://localhost:3000 (health check: /up)
```

### Frontend
```bash
cd frontend
npm install
npm run dev               # http://localhost:5173
```

## Testes
```bash
# backend
cd backend
bundle exec rspec         # testes
bin/rubocop               # lint
bin/ci                    # tudo o que o CI roda (lint, segurança, testes)

# frontend
cd frontend
npm test -- --run         # testes
npm run lint              # ESLint (type-checked)
npm run format:check      # Prettier
```

Hoje os testes cobrem o boot da API (request spec de `/up`) e a renderização da página inicial.
Cada funcionalidade do MVP entra com seus request specs e testes de componente.

## Decisões e aprendizados
- **Postgres em vez de sessões em memória**: o Puma roda vários processos que não dividem memória.
  "Party efêmera" virou regra de expiração. ([ADR 0002](docs/adr/0002-postgresql-party-efemera.md))
- **`Party` e `Participant`**: evitam conflito com a sessão HTTP do Rails e com o model `Session` do
  gerador de autenticação. ([ADR 0003](docs/adr/0003-nomes-party-participant.md))
- **SSE em vez de WebSocket**: a comunicação em tempo real é só do servidor para o cliente.
  ([ADR 0004](docs/adr/0004-sse-com-postgres-listen-notify.md))
- **Monorepo**: API e tela que a consome mudam no mesmo PR. ([ADR 0001](docs/adr/0001-monorepo.md))
- **TypeScript 6.0 fixo**: o `typescript-eslint` ainda não suporta o TS 7.

## Próximos passos
Fora do MVP: votação para pular faixa, busca com cache, histórico de parties, rate limiting por
convidado e deploy contínuo.

## Autor
**Pablo Costa**
- LinkedIn: [linkedin.com/in/pablosilva013](https://www.linkedin.com/in/pablosilva013)
- GitHub: [github.com/pablosscosta](https://github.com/pablosscosta)
- Portfólio: [portfolio-pablosscosta.netlify.app](https://portfolio-pablosscosta.netlify.app/)
