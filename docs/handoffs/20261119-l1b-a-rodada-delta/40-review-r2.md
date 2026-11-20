---
missao: 20261119-l1b-a-rodada-delta
fase: REVIEW
rodada: 2
status: done
sessao: 3e5a0dae-cf9b-4cd5-9a6f-bf877dbac86e
data: 2026-11-20 13:43
gate: "tests/run-all.sh rc=0 (suite green, 2204 linhas ok, 0 FAIL, 915 mutantes aplicam) sobre 64a5e5f; --only REVIEW_head_reads_last_touch contra check-gates.sh: controle verde, mutante morre rc 1; árvore limpa antes do commit da rodada; scan de segredos 0 achados (regex + gitleaks, 7 arquivos); sdd review-base da missão → base=a6f1817 (40-review-r1.md)"
reviewed_head: 64a5e5f3de8ef75b554a8a18b29e36aaab66bf56
---

# Review — rodada r2 — L1b: a rodada delta

## TL;DR

Rodada **delta** (a primeira da missão), `base=a6f1817..64a5e5f`, confirmada pelo
`sdd review-base`: 7 arquivos, 136 linhas — o conserto `c6c381f` (R1) e os artefatos da missão. O
achado #1 da r1 está fechado: o `review_head_ok` lê o commit que **adicionou** a rodada, o mundo novo
do `check-gates.sh` prova, e o mutante `REVIEW_head_reads_last_touch` morre. Um LOW novo, sem rota
(o Check do I3 hoje responde `6 1`). Nenhum `R<n>`. Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Conserto de uma linha no ponto certo (`--diff-filter=A`), com o comentário da função dizendo o porquê; o fixture recria a rodada em vez de remendar o mundo. |
| Type Safety | A | Nada novo a tipar: a captura continua guardada por `or true` e o vazio continua caindo no `return 0` já declarado. |
| Error Handling | A | O caminho fail-closed da r1 está fechado: um commit posterior que toque a rodada e código fica fora do intervalo, e o mundo "código antes do commit da rodada" segue recusado. |
| Security | A | Scan de segredos limpo (regex + gitleaks) sobre o delta; nenhum valor novo chega a comando. |
| Performance | A | Um `git log` com filtro no lugar de outro, antes da suíte; nenhum custo novo no gate. |
| Test Coverage | A | Um mundo novo que distingue o conserto do mutante, e o `--only` desta rodada mostra o mutante morrendo contra o `check-gates.sh`. |
| Documentation | A | O `20-handoff-exec.md` diz o que o código faz (o R1 e a frase do lock, conferida contra o `cmd_review_base`); só a contagem do Check do I3 ficou para trás (LOW #1). |
| **Overall** | **A** | O único achado da r1 está fechado por commit do executor, com sensor e mutante, e o delta não trouxe defeito funcional. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O Check do I3 (`grep -c '^  ok    gate_REVIEW: reviewed_head'` → `5 1`) responde hoje `6 1`: a asserção do R1 entrou com o mesmo prefixo. A linha está `done` e nenhum gate reexecuta Check de linha `done` (o `--red` só lê `pending`); o `20-handoff-exec.md` já diz `# 6 (5 do I3 + 1 do R1)`. | `docs/handoffs/20261119-l1b-a-rodada-delta/checkpoint.md` (linha I3) |

## Incrementos de conserto (R<n>)

Nenhum. O único achado é LOW e não ganha rota (abaixo, em *O que foi refutado*).

## O que virou incremento

- Achado #1 da r1 (MEDIUM, `review_head_ok` lia o último commit que tocou a rodada) — fechado em
  `c6c381f` pelo `sdd-executor` — prova: a asserção `gate_REVIEW: reviewed_head reads the commit that
  added the round, not a later one that touched it → DOCS` está verde na suíte desta rodada, e
  `tests/check-mutation.sh --only REVIEW_head_reads_last_touch check-gates.sh` dá controle verde e
  `REVIEW_head_reads_last_touch — check-gates.sh dies (rc 1)`.
- Achado #3 da r1 (LOW, frase do lock no handoff de EXEC) — corrigido em `15d7cd9`: a linha do I1
  agora diz "consulta admitida sem o lock do checkout", o que o comentário do `cmd_review_base`
  confirma.

## O que foi refutado

- **Achado #1 desta rodada não virou `R<n>`**: o Check de uma linha `done` prova o incremento no
  commit dele (`1d23ca7`, onde a contagem era 5), e o R1 tem o seu próprio Check. Consertá-lo é
  reescrever uma célula de linha fechada por uma sessão EXEC (~US$ 1–2) e comprar uma r3 para julgar
  uma contagem que o handoff de EXEC já declara. Sem fail-open e sem consumidor que leia o número
  como contrato (D15); fica registrado aqui.
- **"O `--diff-filter=A` abre um fail-open: código depois do commit que adicionou a rodada deixa de
  ser lido"** — não é defeito: é o fluxo desenhado. Código depois da rodada é o conserto do `R<n>`,
  que a rodada **seguinte** revisa a partir do `reviewed_head:` desta; e o revisor que escrevesse
  código depois de adicionar a rodada para a linha antes, como `hat-crossed`.
- **"Uma rodada apagada e recriada lê a adição antiga"** — refutado: `git log -1` devolve a adição
  mais nova, e é exatamente o que o `write_r12` do fixture exerce a cada mundo (rm + add).
- **"Com o path limitado, uma rodada renomeada aparece como `R` e não como `A`, e o gate passa
  vazio"** — refutado: sem `--follow`, o pathspec só enxerga o destino, e a mudança é listada como
  adição; nenhum fluxo do kit renomeia rodada.

## Achados fora de escopo

- Nenhum. (A verificação de prosa da skill não rodou por agente: o subagente teve o `Read` do
  contrato do verificador recusado em sessão headless; os quatro arquivos de prosa do delta foram
  conferidos inline contra o código, no fluxo de sempre.)

## Pendências / Decisions for a Human

Nenhuma.
