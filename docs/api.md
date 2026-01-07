# API

## Endpoints

### Sessão
- `POST /sessions`  
  Cria nova sessão vinculada ao host (Spotify + device_id) e atribui um nome.  
  Retorna também o link único e QR code para compartilhamento.

- `POST /sessions/{id}/end`  
  Encerra sessão.

### Fila
- `GET /sessions/{id}/queue`  
  Retorna fila atual.

- `POST /sessions/{id}/queue`  
  Adiciona música à fila (trackId + identificador automático do dispositivo/usuário).

- `DELETE /sessions/{id}/queue/{itemId}`  
  Remove música da fila (opcional, apenas host).

### Playback
- `POST /sessions/{id}/playback/next`  
  Avança para próxima música (apenas host).

### Eventos
- `GET /sessions/{id}/events`  
  SSE para atualizações em tempo real (fila, playback).

## DTOs

### QueueItem
```json
{
  "id": "string",
  "displayName": "string",
  "joinedAt": "2026-01-05T17:00:00Z"
}
```

### User (Participante)
```json
{
  "id": "string",
  "pin": "string",
  "displayName": "string",
  "joinedAt": "2026-01-05T17:00:00Z"
}
```

### Session
```json
{
  "id": "string",
  "hostUserId": "string",
  "deviceId": "string",
  "sessionName": "string",
  "shareLink": "string",
  "qrCodeUrl": "string",
  "status": "Active",
  "createdAt": "2026-01-05T17:00:00Z"
}
```

## Eventos SSE

- `queueUpdated` → fila foi alterada
- `trackStarted` → nova música começou
- `trackEnded` → música terminou