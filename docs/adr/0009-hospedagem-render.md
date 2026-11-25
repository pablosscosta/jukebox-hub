# 0009 — Hospedagem: Render gratuito, com a API em Docker

- **Status:** aceito
- **Data:** 2026-11-25

## Contexto
O projeto é um portfólio, sem receita: a hospedagem precisa ser gratuita. A aplicação tem três
partes: a API Rails (com jobs que avançam a fila e streams SSE), o Postgres e o frontend estático.

O que a API precisa de um servidor:
- **Ficar de pé enquanto a música toca:** um job acorda no fim de cada música para tocar a próxima
  ([ADR 0008](0008-avanco-da-fila.md)).
- **Conexões longas:** os streams de tempo real ficam abertos por minutos
  ([ADR 0004](0004-sse-com-postgres-listen-notify.md)).
- **Ruby 4.0**, que nem todo serviço oferece pronto.

Opções avaliadas em nov/2026:
- **Fly.io:** sem plano gratuito para contas novas. **Koyeb:** o servidor gratuito desliga após 1 h
  sem acessos. **Neon:** o banco gratuito suspende após 5 min e o `LISTEN` não passa pelo pooler.
  **Vercel e Netlify:** ótimas para o frontend, mas rodam funções curtas, sem processo contínuo para
  Puma, jobs e SSE.
- **VM gratuita da Oracle + Kamal:** nunca dorme e o banco não expira, mas a Oracle desliga VMs
  gratuitas ociosas (abaixo de 20% de CPU por 7 dias), o que é o normal de um portfólio, além de exigir
  domínio e manutenção do servidor.
- **Render gratuito:** zero manutenção e HTTPS automático, mas a API dorme e o banco expira.

## Decisão
- **Render gratuito**, declarado em [`render.yaml`](../../render.yaml): a API como web service, o
  frontend como site estático (que não dorme) e o Postgres gratuito.
- **A API roda em Docker** ([`backend/Dockerfile`](../../backend/Dockerfile)): o ambiente nativo do Render
  não garante o Ruby 4.0. A imagem aplica as migrations ao subir.
- **Solid Queue em modo `async`** dentro do Puma: worker, dispatcher e agendador como threads, e não
  como processos separados, para caber nos 512 MB do plano gratuito. O modo padrão (`fork`) é o
  recomendado pelo Solid Queue; aqui a memória é o motivo para trocar. O modo `async` exige o Puma em
  modo simples (um processo só): em modo cluster o Solid Queue tentaria iniciar no processo principal,
  que não carrega a aplicação. O Render define `WEB_CONCURRENCY` sozinho, então o `puma.rb` força o
  modo simples sempre que o Solid Queue está em `async`.
- **`SECRET_KEY_BASE` gerado pelo Render**, então a `master.key` não sai da máquina de quem desenvolve.

## Consequências
- **A API dorme após 15 min sem requisições** e leva até ~1 min para acordar. O frontend mostra
  "o servidor está acordando" quando a espera passa de alguns segundos.
- **Enquanto uma tela da Jukebox Hub está aberta** (como a do host no notebook), os streams SSE se
  renovam a cada 5 min e mantêm a API acordada. Se todas fecharem com música tocando, a fila para de
  avançar até alguém voltar. Celular com a tela bloqueada não conta: o navegador suspende a conexão.
- **O banco gratuito expira em 30 dias** e não tem backup: ele é recriado quando o Render avisar. Como
  a party é efêmera ([ADR 0002](0002-postgresql-party-efemera.md)), perde-se pouco; os hosts fazem login
  de novo.
- O modo de desenvolvimento do Spotify aceita até 5 contas de host, cadastradas no painel do Spotify.
- **Se o app crescer,** o próximo passo é um servidor que não dorme (a VM da Oracle com Kamal, ou um
  plano pago). A imagem Docker já serve para isso.
