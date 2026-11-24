# 0006 — Login do host: OAuth no backend e token Bearer no frontend

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
O host entra com a conta do Spotify, e a API precisa dos tokens dele para controlar o player. Depois do
login, o frontend (React) precisa de algum jeito de provar para a API quem é o host.

Em produção o frontend e a API ficam em domínios diferentes no Render (`*.onrender.com`). Para o
navegador, um cookie da API chamado a partir do frontend é cookie de terceiros, e os navegadores estão
bloqueando esse tipo de cookie cada vez mais.

## Decisão
- **O OAuth inteiro acontece no backend** (Authorization Code + PKCE). O client secret e os tokens do
  Spotify nunca chegam ao navegador. Os tokens ficam no banco, criptografados com Active Record
  Encryption (chaves derivadas do `secret_key_base`).
- **`state` e o verifier do PKCE vão num cookie criptografado da própria API**, que só existe entre
  `/auth/spotify` e o callback. Como essas duas páginas são navegações normais no domínio da API, o
  cookie é de primeira parte. Ele também amarra o login ao navegador que começou o fluxo, o que impede
  CSRF de login.
- **No fim do callback, a API manda o host de volta ao frontend com um código de uso único** (válido
  por 1 minuto). O frontend troca esse código por um **token de acesso** (`POST /auth/token`) e passa a
  enviá-lo em `Authorization: Bearer`. O token não vai direto na URL para não ficar em histórico e logs.
- **No banco ficam só os hashes** (SHA-256) do código e do token. O token vale 7 dias e é apagado no
  logout.

## Consequências
- O mesmo esquema (token Bearer) serve para o participante, então a API tem um só jeito de autenticar.
- O token fica no `localStorage`, então um XSS no frontend poderia roubá-lo. Isso é mitigado com token
  aleatório, expiração, revogação no logout e o fato de o React escapar o conteúdo por padrão.
- O `EventSource` (SSE) não envia headers. Quando o SSE chegar, o token vai precisar ir de outro jeito
  (ex.: um token curto na query string).
- Trocar o `secret_key_base` deixa os tokens do Spotify ilegíveis, e os hosts precisam logar de novo.
- Descartado: cookie de sessão entre domínios (problema dos cookies de terceiros) e servir o frontend
  pela própria API (mudaria o deploy decidido no [ADR 0001](0001-monorepo.md)).
