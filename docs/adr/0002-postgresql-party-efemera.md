# 0002 — PostgreSQL, com party efêmera como regra de negócio

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
A primeira versão dos docs previa sessões só em memória. Em Rails isso falha na prática:
- o Puma roda vários processos/workers que não dividem memória, então cada um teria uma fila diferente;
- restart ou deploy apaga todas as parties;
- eventos de tempo real precisam chegar a conexões abertas em qualquer processo.

## Decisão
Guardar parties, participantes e fila no PostgreSQL. "Efêmero" passa a ser uma regra:
a party tem `expires_at`, é encerrada quando expira e um job remove os dados de parties encerradas.

## Consequências
- As regras de negócio também ficam protegidas no banco. Por exemplo, um índice único parcial em
  `(party_id, track_id)` para itens `pending`/`playing` impede duplicatas mesmo com requisições concorrentes.
- Os tokens do host são guardados com Active Record Encryption.
- O mesmo banco atende Solid Queue e `LISTEN/NOTIFY` ([ADR 0004](0004-sse-com-postgres-listen-notify.md)), sem Redis.
- Custo: precisa de Postgres no dev e no CI, e de uma rotina de limpeza.
