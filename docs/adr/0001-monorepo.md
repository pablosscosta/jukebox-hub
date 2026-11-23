# 0001 — Monorepo com backend e frontend independentes

- **Status:** aceito
- **Data:** 2026-11-23

## Contexto
O projeto tem uma API Rails e uma SPA React. Ele é mostrado no portfólio como um produto único, e
mudanças de funcionalidade costumam mexer nas duas partes ao mesmo tempo.

## Decisão
Um repositório só, com `backend/` e `frontend/` como aplicações independentes, cada uma com suas
dependências, lint e testes. Os docs e ADRs ficam na raiz. O CI roda um job por aplicação, filtrado por
caminho.

## Consequências
- Um PR pode alterar o contrato da API e a tela que o consome juntos.
- O portfólio fica num lugar só, com um README.
- Não há ferramenta de monorepo (Nx, Turborepo): as aplicações não compartilham código, então não precisa.
- Descartados: dois repositórios (exigem coordenar versões) e Rails servindo o build do React
  (acopla os deploys e esconde a separação API-first).
