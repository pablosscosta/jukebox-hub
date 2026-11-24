# API

> Contrato planejado para o MVP. Cada endpoint é confirmado e testado (request spec) na
> funcionalidade que o implementa; ver [ROADMAP](ROADMAP.md).

Convenções: JSON com chaves em `camelCase`, datas em ISO 8601 (UTC), erros no formato
`{ "error": { "code": "string", "message": "string" } }`.

Autenticação (ver [ADR 0006](adr/0006-autenticacao-do-host.md)):
- **Host**: header `Authorization: Bearer <token>`, recebido no fim do login com o Spotify.
- **Participante**: header `Authorization: Bearer <participantToken>`, recebido ao entrar na party.

Sem token válido, a resposta é `401` com `{ "error": { "code": "unauthorized", ... } }`.

## Endpoints

### Autenticação do host ✅
O login é feito por navegação no navegador (não por `fetch`):

1. O frontend leva o host para `GET /auth/spotify`, que redireciona para o consentimento do Spotify.
2. O Spotify volta para `GET /auth/spotify/callback`. A API troca o código pelos tokens, salva o host e
   redireciona para `{FRONTEND_ORIGIN}/auth/callback?code=<código de uso único>`. Em caso de erro, vai
   `?error=` com um destes valores: `access_denied`, `invalid_state`, `login_failed` ou
   `spotify_not_configured`.
3. O frontend troca o código pelo token.

- `POST /auth/token`: body `{ "code": "..." }`. Devolve `201` com `{ "token": "...", "host": Host }`.
  O código vale 1 minuto e só funciona uma vez; senão, `401` com `invalid_login_code`.
- `DELETE /auth/token`: logout; o token deixa de funcionar. `204`.
- `GET /me`: o host logado (`Host`).
- `GET /me/devices`: lista os devices Spotify do host.

### Parties
- `POST /parties`: cria uma party (`name`, `deviceId`). Só o host.
- `GET /parties/{id}`: dados públicos da party.
- `POST /parties/{id}/end`: encerra a party. Só o host.
- `POST /parties/{id}/participants`: entra na party (`displayName` opcional) e devolve o `participantToken`.

### Fila
- `GET /parties/{id}/queue`: fila atual (item tocando + pendentes).
- `POST /parties/{id}/queue`: adiciona uma faixa (`trackId`).
- `DELETE /parties/{id}/queue/{itemId}`: remove um item. Só o host.

### Playback
- `POST /parties/{id}/playback/next`: pula para a próxima faixa. Só o host.

### Eventos
- `GET /parties/{id}/events`: stream SSE (`text/event-stream`).

## DTOs

### Host
```json
{
  "id": "string",
  "displayName": "string"
}
```

### Party
```json
{
  "id": "string",
  "name": "string",
  "status": "active",
  "shareUrl": "https://.../p/{id}",
  "expiresAt": "2026-01-05T23:00:00Z",
  "createdAt": "2026-01-05T17:00:00Z"
}
```

### Participant
```json
{
  "id": "string",
  "displayName": "string | null",
  "joinedAt": "2026-01-05T17:00:00Z"
}
```

### QueueItem
```json
{
  "id": "string",
  "trackId": "string",
  "title": "string",
  "artist": "string",
  "durationMs": 215000,
  "status": "pending",
  "addedBy": { "id": "string", "displayName": "string | null" },
  "addedAt": "2026-01-05T17:00:00Z"
}
```

## Eventos SSE
| Evento | Quando | Payload |
| --- | --- | --- |
| `queue_updated` | fila alterada | lista de `QueueItem` |
| `track_started` | nova faixa começou | `QueueItem` |
| `party_ended` | party encerrada ou expirada | `{ "partyId": "string" }` |
