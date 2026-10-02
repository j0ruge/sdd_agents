---
missao: 20261002-onde-o-comando-do-humano-escreve
fase: REVIEW
rodada: 1
status: done
sessao: sdd-reviewer r1 (headless, 2026-10-02)
data: 2026-10-02 17:19
gate: tests/run-all.sh rc 0, suite green em 305 s (1690 linhas ok, anchors 541 de 541) sobre 29be081; árvore limpa antes deste commit; Error Handling em B pelo achado #1, que virou R1
---

# Review — rodada r1 — Onde o comando do humano escreve

## TL;DR

Revisei o diff `6a11733..29be081`: `bin/sdd`, `tests/run-all.sh`, `tests/check-mutation.sh`, os
quatro sensores tocados e o `TODO.md`. Saíram 5 achados, nenhum CRITICAL ou HIGH. Um MEDIUM foi
reproduzido de ponta a ponta e virou o `R1`: o I3 trocou uma morte barulhenta por uma afirmação
falsa (`intervention noted`) quando a nota não chega ao `checkpoint.md`. Os outros quatro são limite
declarado, decisão do plano ou caso sem consumidor, e não viram incremento. A suíte está verde em
305 s e o pre-scan de segredos está limpo. Nota: B em Error Handling, A no resto, Overall B.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A regra de branch virou uma definição só (`mission_branch_declared`), lida pelo run, pelo retry e pelo approve. O prazo também tem uma tabela só (`step_timeout`), e o `run()` recusa passo que ela não nomeia. |
| Type Safety | A | Não há tipos em bash. As leituras novas usam `ENVIRON` no awk, `-- <paths>` no git e array para a lista de caminhos, sem expansão solta. |
| Error Handling | B | Achado #1, reproduzido: com o diretório da missão sem escrita (layout antigo), o `mv` falha, o `\|\| rm -f` engole a falha e o runner avisa `intervention noted … the commit failed`, sem nota escrita. Antes de 813f808 o mesmo mundo morria com rc 1. |
| Security | A | `frontmatter_write` e `cmd_install` recusam symlink antes de escrever, link quebrado incluído. O pre-scan de segredos não achou nada (`findings: []`). |
| Performance | A | A suíte leva 305 s, contra 271 s antes da missão, e todo passo roda com prazo. Dentro do mutante o estouro devolve 124 e não compra ponto. |
| Test Coverage | A | Cada um dos 10 incrementos tem probe nomeado e mutante próprio (catálogo 532 → 541, `--anchors` verde). O mundo do achado #1 não tinha probe, e ele entra pelo R1. |
| Documentation | A | Os comentários novos nomeiam a issue, o limite declarado e o mundo que o probe não constrói. O drift de README, pipeline e CONTEXT é da fase DOCS, listado no `01-plano.md`. |
| **Overall** | **B** | O diff está sólido e todo incremento está provado. Resta uma regressão pequena de tratamento de erro no caminho da nota de intervenção, que vai como R1. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | Desde o I3, falha do `mv` no ramo do layout antigo é engolida por `\|\| rm -f "$tmp"`. A função segue, o `git commit` não tem o que commitar, e o aviso diz `intervention noted in m/checkpoint.md but the commit failed — commit … by hand`, com rc 0. A nota não existe. A linha `- intervention:` é o que o `sdd autonomy --by-mission` conta, então a intervenção some do ledger, e a mensagem afirma o contrário. Reproduzido com o diretório da missão em 555: em `6a11733` o runner sai com rc 1 e a mensagem do `mv`; em HEAD sai com rc 0, o `nothing to commit, working tree clean` do git e o aviso falso | `bin/sdd:494`, `bin/sdd:503` |
| 2 | LOW | `timeout --foreground` sinaliza só o processo de topo do passo. Os descendentes sobrevivem ao estouro: um `bash -c "sleep 7; touch survivor"` sob `timeout --foreground --kill-after=2 1` devolveu 124 e o `survivor` apareceu 7 s depois | `tests/run-all.sh:118-128` |
| 3 | LOW | O approve troca de branch antes das recusas do `frontmatter_write` (symlink, chave `aprovacao:` ausente). Uma recusa deixa a árvore na branch declarada, sem escrita e sem commit. Foi apontado pela QA | `bin/sdd:7504` |
| 4 | LOW | `sdd close` sem `50-pr.md` volta à base e imprime `the mission branch is merged and spent` sem ter conferido merge nenhum. O I4 estendeu ao ramo sem JIRA o que o ramo JIRA já fazia. Foi apontado pela QA | `bin/sdd:10681`, `close_return_home` |
| 5 | LOW | Sem `timeout(1)` no PATH, todo passo responde 127 e aparece como `✗ failed`, sem nomear a ferramenta ausente | `tests/run-all.sh:128` |

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achado #1 da r1 (único MEDIUM/LOW barato; lote de um) | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the intervention note never claims a note it could not write' <<< "$o"` → `1` |

## O que virou incremento

- Achado #1 virou o `R1`. Para fechar, o Check exige uma asserção nova em `tests/check-autonomy.sh`.
  O mundo dela: missão no layout antigo (sem `checkpoint-notas.md`) e diretório da missão sem
  escrita. A asserção exige três coisas: nenhuma linha diz `intervention noted`, o aviso nomeia que
  a nota NÃO foi escrita (ou o comando morre com `error:`, como antes do I3), e nenhum `sdd-ck-*`
  sobra no `TMPDIR` privado. O mutante vai ao catálogo junto com ela: reverter para
  `\|\| rm -f "$tmp"` puro tem de ser pego.

## O que foi refutado

- **Achado #2 como incremento.** O limite está declarado no comentário do `run()` ("its descendants
  may outlive it"), e a troca é deliberada: sem `--foreground`, o Ctrl-C do humano deixa de chegar
  ao passo, o que o probe `surface: an interrupt still stops the suite while a step runs` cobra. Não
  é fail-open, porque o passo estourado sai vermelho e com nome, e os gates leem a saída de arquivo,
  então o sobrevivente não segura pipe. Pela régua D15 é limite declarado, não backlog.
- **Achado #3 como incremento.** A recusa não escreve nem commita. O
  `ok branch: <de> → <para>` do `ensure_mission_branch` é impresso antes da recusa, então a troca
  aparece na tela. O approve seguinte funciona dali. A ordem ("depois do `y` e antes do
  `frontmatter_write`") é a decisão 3 do grill. Antecipar a recusa de symlink para o `cmd_approve`
  criaria uma segunda definição da regra que hoje mora só no `frontmatter_write`.
- **Achado #5 como incremento.** Não é fail-open. Sem `timeout(1)` a suíte limpa fica vermelha, e o
  `sdd health` reprova pelo `suite red` antes de qualquer veredito do catálogo (`bin/sdd:5940`).
  O kit já exige Linux com coreutils (Python 3.9+, pidfd), e `close_return_home` é o único sítio que
  trata a ausência, porque roda no checkout do humano e não na suíte.

## Achados fora de escopo

- Nenhum novo. O achado #4 já está no `TODO.md` desde o commit da QA (`70a698e`, catraca 87 → 88).

## Pendências / Decisions for a Human

- **Achado #4: o `sdd close` sem `pr_url:` afirma `merged and spent`.** O I4 seguiu a decisão 5 do
  grill ("nos outros casos, `close_return_home`"), então isso não desvia do plano. A frase afirma
  algo que o runner não conferiu, e a regra da casa é "dizer só o que o runner sabe". Há três
  saídas: (a) o close sem `pr_url:` recusa ou fica onde está; (b) a mensagem diz só o que foi
  feito ("back on '<base>'"); (c) manter como está. Cabe ao humano escolher. O item no `TODO.md`
  carrega o achado.
