# 0005 — Testes com RSpec e FactoryBot

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
A versão anterior usava Minitest com fixtures. As regras de negócio (fila, limites, permissões do host)
têm muitas variações de cenário.

## Decisão
RSpec + FactoryBot, priorizando **request specs** (testam o contrato HTTP de ponta a ponta) e specs
unitários para models e services. Chamadas ao Spotify são bloqueadas com WebMock e simuladas por stubs.

## Consequências
- `describe`/`context` deixam os cenários das regras de negócio legíveis.
- As factories montam o estado de cada teste de forma explícita, sem depender de fixtures globais.
- Custo: mais gems e configuração do que o Minitest, que já vem no Rails.
