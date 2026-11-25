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
- `GET /me/party`: a party ativa do host (`Party`), ou `404` com `no_active_party`.
- `GET /me/devices`: devices em que o Spotify do host está aberto agora (`Device[]`, pode vir vazia).
  Devices restritos, que não aceitam comandos pela API, ficam de fora. Se o Spotify falhar, `502` com
  `spotify_unavailable`; se o host revogou o acesso no Spotify, `401`.

### Parties
- `POST /parties`: cria uma party. Só o host. Body `{ "name": "...", "deviceId": "..." }`, com o
  `deviceId` vindo de `GET /me/devices`. Devolve `201` com a `Party`. Erros:
  - `403 premium_required`: o host não tem Spotify Premium.
  - `409 active_party_exists`: o host já tem uma party ativa; a resposta traz também `party` (a atual).
  - `422 device_unavailable`: o device não está mais aberto (ou não é do host).
  - `422 invalid_party`: nome vazio ou com mais de 60 caracteres.
- `GET /parties/{id}`: dados públicos da party (`PublicParty`), sem login. `404 party_not_found` se o
  id não existe. Uma party expirada aparece como `ended`.
- `POST /parties/{id}/end` ✅: o host encerra a party (token do host). Pausa o Spotify e avisa todas as
  telas (`party_ended`). `204`, também se ela já tinha acabado; `404 party_not_found` se a party não é
  desse host.
- `POST /parties/{id}/participants`: o convidado entra, sem login. Body `{ "displayName": "Ana" }`
  (opcional; sem nome vira "Convidado N"). Devolve `201` com
  `{ "participantToken": "...", "participant": Participant }`. Erros: `404 party_not_found`,
  `410 party_ended` (party encerrada ou expirada) e `422 invalid_participant` (nome com mais de 40
  caracteres).
- `GET /parties/{id}/participants/me`: o participante dono do token (`Participant`). Serve para quem
  volta à página conferir se o token salvo no aparelho ainda vale. Com o token do host da party,
  devolve o participante do próprio host. `401` se o token não é dessa party, `410` se a party acabou.

### Busca e fila ✅
Estes endpoints aceitam o token do participante **ou** o token do host da party. Todos respondem
`404 party_not_found`, `410 party_ended` e `401` sem token válido. As chamadas ao Spotify usam a conta
do host: se ela desconectou, `503 host_spotify_disconnected`; se o Spotify falhar, `502
spotify_unavailable`.

- `GET /parties/{id}/search?q=...`: busca até 10 músicas (`Track[]`) que podem tocar no país do host.
  `422 invalid_query` para busca vazia ou com mais de 100 caracteres.
- `GET /parties/{id}/queue`: a fila (`Queue`). `upNext` já vem na ordem de tocar
  ([ADR 0007](adr/0007-fila-justa.md)).
- `POST /parties/{id}/queue`: adiciona uma música. Body `{ "trackId": "..." }`, com o id vindo da busca.
  Título, artista e capa são buscados no Spotify. Devolve `201` com o `QueueItem`. Erros:
  - `409 already_queued`: a música já está esperando ou tocando.
  - `409 queue_limit_reached`: o participante já tem 5 músicas esperando.
  - `422 invalid_track`: o id não é de uma faixa que pode tocar.
- `DELETE /parties/{id}/queue/{itemId}`: tira da fila uma música que ainda está esperando. Só o host
  (`403 forbidden` para convidado). `204`, ou `404 queue_item_not_found` se ela não está mais esperando.

Uma música adicionada a uma fila parada começa a tocar na hora. Abrir a fila também confere o que o
Spotify está tocando, no máximo uma vez a cada 20 s por party ([ADR 0008](adr/0008-avanco-da-fila.md)).

### Playback ✅
Só o host (`403 forbidden` para convidado). As duas respondem `204`, ou `422 device_unavailable` se o
Spotify não está aberto no device da party.

- `POST /parties/{id}/playback/next`: pula a música que está tocando e toca a próxima da fila. Com a
  música do host tocando, volta para a fila.
- `POST /parties/{id}/playback/start`: toca a fila quando nada está tocando (por exemplo, depois de o
  Spotify parar) ou volta para a fila no lugar da música do host. Não pula a música que já está tocando.

### Eventos ✅
- `GET /parties/{id}/events`: stream SSE (`text/event-stream`), sem token. Manda só avisos, sem dados
  (ver abaixo e [ADR 0004](adr/0004-sse-com-postgres-listen-notify.md)). `404 party_not_found` se a
  party não existe.

## DTOs

### Host
```json
{
  "id": "string",
  "displayName": "string",
  "premium": true
}
```

### Device
```json
{
  "id": "string",
  "name": "Notebook",
  "type": "Computer",
  "isActive": true
}
```
`type` vem do Spotify (`Computer`, `Smartphone`, `Speaker`...). `isActive` indica o device que está
tocando agora.

### Party
```json
{
  "id": "string",
  "name": "string",
  "status": "active",
  "deviceName": "pablo-note",
  "shareUrl": "https://.../p/{id}",
  "expiresAt": "2026-01-05T23:00:00Z",
  "createdAt": "2026-01-05T17:00:00Z"
}
```

### PublicParty
O que qualquer pessoa com o link vê. Não inclui device nem link de convite.
```json
{
  "id": "string",
  "name": "string",
  "status": "active",
  "hostName": "string",
  "expiresAt": "2026-01-05T23:00:00Z"
}
```

### Participant
```json
{
  "id": "string",
  "displayName": "string",
  "role": "guest",
  "joinedAt": "2026-01-05T17:00:00Z"
}
```
`role` é `guest` ou `host`.

### Track
```json
{
  "trackId": "string",
  "title": "Garota de Ipanema",
  "artist": "Tom Jobim, Vinicius de Moraes",
  "durationMs": 215000,
  "imageUrl": "https://i.scdn.co/image/... | null"
}
```
Com mais de um artista, os nomes vêm juntos, separados por vírgula. A capa é a de ~300 px.

### QueueItem
Um `Track` mais:
```json
{
  "id": "string",
  "status": "pending",
  "addedBy": { "id": "string", "displayName": "string" },
  "addedAt": "2026-01-05T17:00:00Z",
  "startedAt": "2026-01-05T17:03:00Z | null"
}
```
`startedAt` existe quando a música já começou a tocar: com ele e `durationMs`, a tela desenha o
progresso. `externalTrack` (a música do host pelo Spotify) também traz `startedAt`, estimado pela API a
partir do progresso que o Spotify informou.

### Queue
```json
{
  "nowPlaying": "QueueItem | null",
  "upNext": ["QueueItem"],
  "maxPendingPerParticipant": 5,
  "playbackState": "playing",
  "externalTrack": "Track | null"
}
```
`playbackState`:
- `playing`: tocando uma música da fila (`nowPlaying`).
- `external`: tocando uma música que o host colocou direto no app do Spotify (`externalTrack`). A fila
  volta quando ela acaba.
- `paused`: o Spotify parou no meio de uma música; o host toca de novo com `playback/start`.
- `idle`: nada tocando.

## Eventos SSE
Todos com `data: {}`: o evento diz o que mudou, e a tela busca o estado pela API.

| Evento | Quando | O que a tela faz |
| --- | --- | --- |
| `connected` | ao abrir o stream (e a cada reconexão) | recarrega a fila (pega o que perdeu offline) |
| `queue_changed` | música adicionada, tocada, pulada ou removida; música do host pelo Spotify | recarrega a fila |
| `party_ended` | o host encerrou ou a party expirou | mostra que a party terminou e fecha o stream |

Entre os eventos vai um comentário `: heartbeat` a cada 15 s. O servidor fecha o stream depois de
alguns minutos e o `EventSource` reconecta sozinho.
