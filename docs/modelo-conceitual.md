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
- **expiresAt**: momento em que a party expira automaticamente (renovado a cada atividade)
- **endedAt**: quando a party foi encerrada
- **externalTrack**: música que o host colocou direto no app do Spotify, quando é o caso (ver regras)
- **createdAt**: data/hora de criação

O link de compartilhamento e o QR code são **derivados** do `id` (não são armazenados).

### Participant
Um convidado que entrou na party pelo link ou QR code. Não tem login.

- **id**: identificador único
- **displayName**: nome escolhido ao entrar (opcional; sem nome vira "Convidado N", até 40 caracteres)
- **role**: `guest` (convidado) ou `host`
- **joinedAt**: data/hora de entrada

O participante recebe um token anônimo ao entrar e o usa para se identificar nas requisições. Como no
host, o banco guarda só o hash do token. O token vale enquanto a party estiver ativa.

O host também é um participante da própria party (`role: host`), para poder adicionar músicas. Esse
participante é criado na primeira vez que o host precisa dele e não tem token próprio: o host usa o
token de host. Cada party tem no máximo um participante host.

### QueueItem
Uma música adicionada à fila.

- **id**: identificador único
- **trackId**: identificador da faixa no Spotify
- **title / artist / durationMs / imageUrl**: metadados copiados do Spotify no momento da inclusão
  (nunca enviados pelo cliente)
- **addedBy**: participante que adicionou
- **status**: `pending` | `playing` | `played` | `removed`
- **addedAt / startedAt**: datas de inclusão e de início da reprodução

---

## Regras de Negócio
- **Fila justa**: os itens `pending` tocam na ordem de chegada, mas ninguém toca 3 músicas seguidas
  enquanto outra pessoa tem música esperando. A ordem é calculada a cada leitura, não armazenada. Ver
  [ADR 0007](adr/0007-fila-justa.md).
- **Até 5 músicas esperando por participante** (host incluído).
- **Sem duplicatas simultâneas**: uma faixa não pode ser adicionada se já estiver `pending` ou `playing`
  na mesma party. Depois de tocada, pode voltar à fila. Garantida também por índice único parcial no banco.
- **Party efêmera**: a party expira depois de 6 h sem atividade (cada música adicionada ou tocada
  renova o prazo) e então é encerrada. Os dados de uma party encerrada (convidados e fila) são apagados
  24 h depois. Ver [ADR 0002](adr/0002-postgresql-party-efemera.md).
- **Encerrar**: quando o host encerra, a música para e todas as telas ficam sabendo na hora. Quando a
  party expira, o Spotify do host não é tocado (ele pode estar ouvindo outra coisa).
- **Uma party ativa por host**: para criar outra, o host precisa encerrar a atual (ou esperar ela
  expirar). Garantida também por índice único parcial no banco.
- **Avanço automático**: quando uma música acaba, a próxima da ordem justa toca sozinha. A primeira
  começa assim que entra numa fila parada. Ver [ADR 0008](adr/0008-avanco-da-fila.md).
- **Música do host pelo Spotify**: se o host dá play direto no app do Spotify, essa música "fura a fila":
  aparece como tocando, a música da fila que foi interrompida conta como tocada, e a fila volta quando
  ela acaba.
- **Controle do host**: apenas o host pode pular faixa, remover itens da fila, tocar a fila parada e
  encerrar a party.
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
