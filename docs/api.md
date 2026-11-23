# API

> Contrato planejado para o MVP. Cada endpoint é confirmado e testado (request spec) na
> funcionalidade que o implementa; ver [ROADMAP](ROADMAP.md).

Convenções: JSON com chaves em `camelCase`, datas em ISO 8601 (UTC), erros no formato
`{ "error": { "code": "string", "message": "string" } }`.

Autenticação:
- **Host**: sessão criada após o OAuth do Spotify.
- **Participante**: header `Authorization: Bearer <participantToken>`, recebido ao entrar na party.

## Endpoints

### Autenticação do host
- `GET /auth/spotify`: redireciona para o consentimento do Spotify.
- `GET /auth/spotify/callback`: recebe o código, troca pelos tokens e cria a sessão do host.
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
