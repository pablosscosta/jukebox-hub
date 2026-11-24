# Modelo Conceitual

## Visão Geral
Descreve as entidades, atributos e regras de negócio do **Jukebox Hub**, sem detalhes de banco ou código.
Os nomes seguem o código: `Party` (antes "Sessão") e `Participant` (antes "Usuário") — ver
[ADR 0003](adr/0003-nomes-party-participant.md).

---

## Entidades

### Host
Quem entra com a conta do Spotify e cria parties. A música toca na conta dele.

- **id**: identificador único
- **spotifyUserId**: usuário Spotify (único: logar de novo atualiza o mesmo host)
- **displayName**: nome exibido no Spotify
- **product**: plano do Spotify (`premium`, `free`...), atualizado a cada login. Só Premium cria party.
- **tokens do Spotify**: access e refresh token, guardados criptografados, mais a data de expiração do
  access token. Quando ele expira, a API renova sozinha com o refresh token.

O frontend se identifica com um token de acesso próprio da API (não o do Spotify). Do token, o banco
guarda só o hash. Ver [ADR 0006](adr/0006-autenticacao-do-host.md).

### Party
Uma sessão da jukebox, criada por um host autenticado no Spotify.

- **id**: UUID, público e não sequencial (usado no link de convite, então não pode ser adivinhado)
- **name**: nome atribuído pelo host (1 a 60 caracteres)
- **host**: o `Host` que criou a party
- **deviceId** e **deviceName**: dispositivo Spotify onde a música toca (o nome é guardado para exibição)
- **status**: `active` | `ended`
- **expiresAt**: momento em que a party expira automaticamente
- **createdAt**: data/hora de criação

O link de compartilhamento e o QR code são **derivados** do `id` (não são armazenados).

### Participant
Um convidado que entrou na party pelo link ou QR code. Não tem login.

- **id**: identificador único
- **displayName**: nome opcional
- **joinedAt**: data/hora de entrada

O participante recebe um token anônimo ao entrar e o usa para se identificar nas requisições.
O host também é um participante da própria party.

### QueueItem
Uma música adicionada à fila.

- **id**: identificador único
- **trackId**: identificador da faixa no Spotify
- **title / artist / durationMs**: metadados copiados do Spotify no momento da inclusão
- **addedBy**: participante que adicionou
- **status**: `pending` | `playing` | `played` | `removed`
- **addedAt / startedAt**: datas de inclusão e de início da reprodução

---

## Regras de Negócio
- **Fila FIFO**: os itens `pending` tocam na ordem de `addedAt`.
- **Sem duplicatas simultâneas**: uma faixa não pode ser adicionada se já estiver `pending` ou `playing`
  na mesma party. Depois de tocada, pode voltar à fila. Garantida também por índice único parcial no banco.
- **Limite de músicas consecutivas**: um participante não pode ter mais de **2** músicas seguidas no final
  da fila de pendentes.
- **Party efêmera**: a party expira após um período sem atividade (padrão: 6h) e então é encerrada;
  um job remove os dados de parties encerradas. Ver [ADR 0002](adr/0002-postgresql-party-efemera.md).
- **Uma party ativa por host**: para criar outra, o host precisa encerrar a atual (ou esperar ela
  expirar). Garantida também por índice único parcial no banco.
- **Controle do host**: apenas o host pode pular faixa, remover itens da fila e encerrar a party.
- **Party encerrada é somente leitura**: não aceita novos participantes nem músicas.

---

## Relacionamentos
```text
Host
 └── Parties [*]

Party
 ├── Participants [*]
 └── QueueItems [*] ──> addedBy: Participant
```
