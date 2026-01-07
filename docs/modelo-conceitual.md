# Modelo Conceitual

## Visão Geral
O Modelo Conceitual descreve as principais entidades, atributos e regras de negócio da aplicação **Jukebox Hub**.  
Ele representa uma visão abstrata do sistema, sem detalhes de implementação em banco de dados ou código, servindo como referência para design e desenvolvimento.

---

## Entidades

### Sessão (Session)
Representa uma sessão ativa da jukebox.

- **id**: identificador único da sessão  
- **hostUserId**: identificador do usuário host (Spotify)  
- **deviceId**: dispositivo ativo do Spotify  
- **sessionName**: nome atribuído pelo host à sessão  
- **shareLink**: link único para compartilhamento da sessão  
- **qrCodeUrl**: QR code gerado para acesso rápido  
- **status**: estado da sessão (`Active` | `Ended`)  
- **createdAt**: data/hora de criação  
- **users**: coleção de participantes  
- **queue**: coleção de músicas na fila  

---

### Usuário (User)
Representa um participante que acessa a sessão via link ou QR code.

- **id**: identificador único (gerado automaticamente pelo sistema)  
- **displayName**: nome opcional do participante  
- **joinedAt**: data/hora de entrada na sessão  
- **lastActions**: histórico de ações (para controle de limite de músicas consecutivas)  

---

### Item da Fila (QueueItem)
Representa uma música adicionada à fila.

- **id**: identificador único  
- **trackId**: identificador da faixa no Spotify  
- **addedByUserId**: identificador do usuário que adicionou  
- **addedAt**: data/hora de inclusão  
- **status**: estado do item (`Pending` | `Playing` | `Played`)  

---

## Regras de Negócio
- **Fila FIFO**: músicas são tocadas na ordem em que foram adicionadas.  
- **Sem duplicatas simultâneas**: não é permitido adicionar a mesma faixa se já estiver na fila.  
- **Limite de músicas consecutivas por dispositivo/usuário**: um participante não pode adicionar mais de duas músicas seguidas.  
- **Sessão efêmera**: no MVP, as sessões são mantidas apenas em memória.  
- **Playback controlado pelo host**: apenas o host pode avançar ou encerrar a sessão.  

---

## Relacionamentos
- **Sessão → Usuários**: uma sessão possui vários participantes.  
- **Sessão → Fila**: uma sessão possui uma fila de músicas.  
- **Usuário → Item da Fila**: cada música adicionada é associada ao usuário que a incluiu.  

Representação simplificada:

```text
Session
 ├── Users [*]
 │     └── User (id, displayName, joinedAt)
 └── Queue [*]
       └── QueueItem (id, trackId, addedByUserId, status)
```

