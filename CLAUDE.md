# Jukebox Hub

## Objetivo
Jukebox colaborativa integrada ao Spotify. O host cria uma party tocando no seu dispositivo Spotify; os
convidados entram por link/QR code e adicionam músicas a uma fila com regras (FIFO, sem duplicatas,
limite de músicas seguidas). Projeto de portfólio: destaque para OAuth do Spotify e tempo real via SSE.

## Stack
- `backend/`: Ruby 4.0 + Rails 8.1 (modo API), PostgreSQL, RSpec + FactoryBot + WebMock, RuboCop.
- `frontend/`: React 19 + TypeScript 6 (strict) + Vite, Vitest + Testing Library, ESLint + Prettier.
- CI: GitHub Actions (`.github/workflows/ci.yml`). Deploy: Render (`render.yaml`).

O TypeScript fica fixo na 6.0 porque o `typescript-eslint` ainda não suporta o TS 7.

## Comandos
Backend (em `backend/`; use o Ruby do `.ruby-version` via mise):
- Setup: `bin/setup --skip-server`
- Dev: `bin/dev` (http://localhost:3000)
- Testes: `bundle exec rspec`
- Lint: `bin/rubocop` (corrigir: `bin/rubocop -a`)
- Tudo do CI: `bin/ci`

Frontend (em `frontend/`):
- Dev: `npm run dev` (http://localhost:5173)
- Testes: `npm test` (uma vez: `npm test -- --run`)
- Lint/format: `npm run lint`, `npm run format`
- Build: `npm run build`

## Arquitetura
- Vocabulário do domínio: `Party` (sessão da jukebox), `Participant` (convidado), `QueueItem`.
  Nunca usar `Session`/`User` para esses conceitos (ADR 0003).
- Backend segue as convenções do Rails: controllers enxutos; regras com mais de um passo em
  `app/services`; cliente do Spotify em `app/clients/spotify` (sempre stubado nos testes).
- Regras de negócio críticas também são garantidas no banco (constraints/índices).
- Tempo real: SSE (`ActionController::Live`) + Postgres `LISTEN/NOTIFY` (ADR 0004).
- Party é efêmera por regra de expiração, não por armazenamento em memória (ADR 0002).

## Git
- Mensagens de commit, títulos e descrições de PR em **português** (Conventional Commits:
  `feat(backend): adiciona ...`). Isso vale acima da regra geral de commits em inglês.
- Código, nomes de variáveis e branches continuam em inglês.
- Sem linhas de coautoria do Claude em commits e PRs.

## Docs
- `docs/arquitetura.md`, `docs/modelo-conceitual.md`, `docs/api.md`: fonte das regras e do contrato.
- `docs/adr/`: decisões; criar um ADR novo para cada decisão relevante.
- `docs/ROADMAP.md`: checklist do MVP; atualizar ao concluir uma funcionalidade.
