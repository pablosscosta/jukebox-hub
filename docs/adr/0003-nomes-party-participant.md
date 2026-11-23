# 0003 — Nomes `Party` e `Participant`

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
O modelo conceitual chamava a entidade principal de `Session` e o convidado de `User`. Em Rails:
- `session` já é o helper de sessão HTTP nos controllers (`ActionDispatch::Session`);
- `rails g authentication` (Rails 8) gera um model `Session`;
- o convidado não é um usuário autenticado, então `User` sugere login e conta, coisas que ele não tem.

## Decisão
- `Session` vira **`Party`**: curto, faz sentido no domínio e gera rotas legíveis (`/parties/:id/queue`).
- `User` vira **`Participant`**: deixa claro que é alguém dentro de uma party, sem conta.

## Consequências
- Nenhuma ambiguidade entre a sessão HTTP do host e a party.
- `User` fica livre caso o host vire um usuário persistente no futuro.
- Descartados: `JukeboxSession` (verboso e ainda com "session") e `Room` (genérico, associado a chat).
