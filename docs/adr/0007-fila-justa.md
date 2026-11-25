# 0007 — Fila justa: limite de músicas esperando e ordem calculada

- **Status:** aceito
- **Data:** 2026-11-25

## Contexto
A regra original era uma fila FIFO em que ninguém podia ter mais de 2 músicas seguidas no fim da fila.
Na prática, isso trava quem chega primeiro: numa party que está começando, o primeiro convidado só
consegue colocar 2 músicas e precisa esperar outra pessoa adicionar alguma.

Queríamos duas coisas ao mesmo tempo: deixar cada pessoa colocar várias músicas de uma vez e não deixar
ninguém dominar a party.

## Decisão
- **Cada participante pode ter até 5 músicas esperando** (`pending`). O host segue o mesmo limite.
  Quando uma música dele começa a tocar, libera uma vaga.
- **A ordem de tocar é calculada, não salva.** `QueueItems::PlayOrder` é uma função pura: recebe as
  músicas pendentes (em ordem de chegada) e quem teve as últimas músicas tocadas, e devolve a ordem.
  A regra é a ordem de chegada, com uma exceção: se as 2 últimas músicas são da mesma pessoa e
  outra pessoa tem música esperando, a música mais antiga dessa outra pessoa passa na frente. Se só
  aquela pessoa tem músicas esperando, as dela continuam tocando.
- **A adição trava a linha da party** (`with_lock`), para duas músicas enviadas juntas não passarem
  ao mesmo tempo pela checagem do limite. O Spotify é consultado antes do lock.
- **Sem duplicatas** enquanto a música está `pending` ou `playing`, com índice único parcial no banco.

## Consequências
- Como a ordem é recalculada a cada leitura, não existe uma coluna de posição para manter em sincronia.
  Quando alguém adiciona uma música, as posições das outras podem mudar.
- A regra fica isolada numa classe sem banco nem relógio, testada por cenários.
- Para a fila ficar no tamanho certo, o cálculo considera todas as pendentes da party. Com o limite de
  5 por pessoa, isso é pouco trabalho.
- Reordenar a fila na mão pelo host não combina com a ordem calculada. Fica para avaliar depois (ver
  [ROADMAP](../ROADMAP.md)).
- Descartado: guardar a posição de cada música (exige reorganizar a fila a cada inclusão) e o limite
  original de 2 seguidas no fim da fila (trava quem chega primeiro).
