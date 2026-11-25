# 0008 — Avanço da fila: job agendado que confere o Spotify

- **Status:** aceito
- **Data:** 2026-11-25

## Contexto
A Spotify Web API não avisa quando uma música acaba nem quando o host dá play em outra coisa pelo app
do Spotify: não há webhook. O único jeito de saber o que está tocando é perguntar (`GET /me/player`).
Mesmo assim, a jukebox precisa tocar a próxima música da fila sozinha, sem gastar chamadas à toa.

## Decisão
- **Um job por música, agendado para perto do fim** (Solid Queue no mesmo Postgres, rodando dentro do
  Puma). Ele acorda alguns segundos antes do fim previsto e **confere o Spotify antes de agir**
  (`Playback::Reconcile`): se o host pausou, reagenda; se a música está acabando, confere de novo logo
  depois do fim e então toca a próxima da ordem justa (`Playback::Advance`). São ~2 chamadas por música.
- **Tudo é idempotente.** Quem pede para avançar diz o que acha que está tocando; se a fila já andou
  (clique duplo em "Pular", job atrasado ou repetido), a chamada não faz nada. O job é salvo na mesma
  transação que muda a fila, porque fica no mesmo banco.
- **A música tocada direto no app do Spotify "fura a fila".** A jukebox não briga com o host: mostra a
  música dele como tocando (tag "Spotify do host"), conta como tocada a música da fila que foi
  interrompida e retoma a fila quando a dele acaba.
- **Abrir a fila também confere o Spotify**, no máximo uma vez a cada 20 s por party (um `UPDATE`
  condicional decide quem pergunta). Assim, a tela mostra a música do host sem consultar o Spotify o
  tempo todo.
- A primeira música começa sozinha quando entra numa fila parada.

## Consequências
- Poucas chamadas ao Spotify, e só quando há música tocando ou alguém olhando a fila.
- A tela pode ficar até ~20 s atrás do Spotify, e entre uma música e outra há alguns segundos de
  silêncio (a conferência roda logo depois do fim).
- Se a música do host acabar antes da próxima conferência, o Spotify segue para a próxima do álbum dele,
  e a jukebox também a trata como do host.
- Os jobs rodam dentro do servidor web: se a hospedagem "dormir" sem acessos, a fila para de avançar.
  Isso pesa na escolha de hospedagem ([ROADMAP](../ROADMAP.md)).
- Descartados: consultar o Spotify a cada poucos segundos (muitas chamadas), usar a fila do próprio
  Spotify (a API não deixa remover nem reordenar, o que quebra a ordem justa) e o Web Playback SDK (só
  funciona com a aba aberta num computador; fica como ideia para depois).
