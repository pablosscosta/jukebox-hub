# Vídeo de demonstração

Grava a interface real do `frontend/` com o Playwright, respondendo todas as chamadas da API com dados
fictícios (`fixtures.mjs`). Assim dá para mostrar a Jukebox Hub funcionando sem conta do Spotify e sem
dado pessoal na tela. A música não toca de verdade.

## O que a gravação mostra
Duas telas gravadas ao mesmo tempo, com o mesmo estado:

- **Host** (desktop, 1000×844): a party "Churrasco de sábado" com a música atual e a fila.
- **Convidado** (celular, 390×844): entra pelo link como Bruno, busca "Tim Maia" e adiciona uma música.

A fila do host atualiza ao vivo com a música do Bruno (que entra antes da segunda música da Ana, pela
regra justa). Depois a música atual acaba e a próxima começa nas duas telas.

## Como funciona
- `page.route` intercepta tudo que vai para `http://127.0.0.1:3000` e responde segundo o contrato de
  `docs/api.md`. O script sobe o Vite na porta 5174 com `VITE_API_URL` apontando para esse endereço.
- O tempo real usa o `EventSource` de verdade: a conexão SSE fica parada até algo mudar, recebe
  `queue_changed` e termina; o navegador reconecta e espera o próximo aviso.
- O login é pulado gravando um token fictício no `localStorage` do host.
- As capas são SVGs gerados, sem arte de álbum.

## Regravar
Requisitos: Node 24, as dependências do `frontend/` instaladas e o `ffmpeg` no PATH.

```bash
cd docs/demo
npm install
npx playwright install chromium   # só na primeira vez (cerca de 170 MB)
npm run record
```

Saída em `docs/assets/`:

| Arquivo | Uso |
| --- | --- |
| `demo.mp4`, `demo.jpg` | as duas telas lado a lado (1414×844), para embutir em sites |
| `demo-host.mp4`, `demo-host.jpg` | vídeo e poster da tela do host |
| `demo-convidado.mp4`, `demo-convidado.jpg` | vídeo e poster da tela do convidado |
| `demo.gif` | as duas telas lado a lado, para o README |

O Playwright fica só aqui, com `package.json` próprio: não entra nas dependências do app nem no CI.
