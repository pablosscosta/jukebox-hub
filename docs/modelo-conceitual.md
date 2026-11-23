# Modelo Conceitual

## Visão Geral
Descreve as entidades, atributos e regras de negócio do **Jukebox Hub**, sem detalhes de banco ou código.
Os nomes seguem o código: `Party` (antes "Sessão") e `Participant` (antes "Usuário") — ver
[ADR 0003](adr/0003-nomes-party-participant.md).

---

## Entidades

### Party
Uma sessão da jukebox, criada por um host autenticado no Spotify.

- **id**: identificador público e não sequencial (usado no link de convite)
- **name**: nome atribuído pelo host
- **spotifyUserId**: usuário Spotify do host
- **deviceId**: dispositivo Spotify onde a música toca
- **status**: `active` | `ended`
- **expiresAt**: momento em que a party expira automaticamente
- **createdAt**: data/hora de criação

O link de compartilhamento e o QR code são **derivados** do `id` (não são armazenados).
Os tokens OAuth do host ficam guardados criptografados e nunca são expostos pela API.

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
- **Controle do host**: apenas o host pode pular faixa, remover itens da fila e encerrar a party.
- **Party encerrada é somente leitura**: não aceita novos participantes nem músicas.

---

## Relacionamentos
```text
Party
 ├── Participants [*]
 └── QueueItems [*] ──> addedBy: Participant
```
