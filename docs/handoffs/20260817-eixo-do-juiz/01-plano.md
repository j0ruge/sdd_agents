---
missao: 20260817-eixo-do-juiz
data: 2026-08-17
---

# Plano — o eixo do juiz

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Todas as âncoras relidas em `main` **depois** do merge do PR #5 (`8481f43`) e da limpeza do
`TODO.md` (`96a9bf1`). Elas valem para o HEAD desta branch.

- `autonomy_kit_stamp()` — `bin/sdd:901`. Carimba `kit_sha` por LINHA. **Não mexer** (decisão 1).
  ⚠️ É chamada, nunca `$(...)`: o corpo mexe em global e o subshell mataria o one-shot warn — o
  comentário de `bin/sdd:896-899` conta a história.
- Eixo/recorte e piso do guard — `bin/sdd:2455-2470`; a linha do piso é
  `sufficient: ($observed >= 3)` em `:2469`, com o comentário "I13.4 revisits".
- `$observed` tem **uma** binding (`bin/sdd:2462`) para o campo exposto e o veredito do guard não
  divergirem. Campo novo do guard entra com a mesma disciplina.
- `ledger_repo_root()` — `bin/sdd:865`. Devolve `$REPO_ROOT` se setado, senão
  `git rev-parse --show-toplevel`. Chamadores: `bin/sdd:2248` (`cmd_autonomy`) e `:2375`
  (`kaizen_series`).
- `ledger_row_is_local()` — `bin/sdd:887`. Emite **texto jq** (`def ledger_row_is_local: …`) que é
  interpolado nos programas; é UM predicado para os três leitores. É por aqui que o I3 entra.
- Definições únicas por programa em jq: `def on_axis` em `:2307` (cmd_autonomy) e `:2403`
  (kaizen_series); `def is_escalation` em `:2310` e `:2394`; `def is_unrecognized` em `:2311`.
  O comentário de `:2396-2402` explica por que cada programa tem UMA definição — e por que não há
  apóstrofo dentro do programa jq (a string shell é single-quoted e um apóstrofo a encerraria).
- `kaizen_reminder()` — a partir de `bin/sdd:2483`; lê **através** de `kaizen_series`, então herda
  qualquer filtro. Não tem filtro próprio, de propósito.
- `gate_KAIZEN` exige `guard.sufficient` da MESMA série que o agente é mandado citar
  (`bin/sdd:2550-2552`): veredito diferente de `indeterminado` com guard insuficiente reprova.
- ADRs existentes: `docs/adr/0001-judge-split-deterministic-series-model-verdict.md` e
  `0002-kaizen-plans-headless-bad-verdict-stops-the-line.md`. Formato: `# NNNN — título`,
  `Date: · Status: accepted`, seções `## Context`, `## Decision`, `## Consequences`.
- Baseline da suíte nesta branch: **`score: 55 caught, 0 known gap(s), of 55`** (medido no fecho do
  PR #5). Alvo desta missão: **60**.
- Os 5 Checks rodados contra este HEAD em 2026-08-17: todos **0** (vermelhos), com
  `tests/check-kaizen.sh` e `tests/check-autonomy.sh` **rc 0** (verdes). Nenhum nasce verde.
- Modelo de asserção diferencial: o par `degraded`/`blocked` em `tests/check-kaizen.sh` — dois
  fixtures, saídas comparadas **entre si**, nenhum regime de fixture o satisfaz por acidente.

**Armadilhas da casa que mordem nestes arquivos** (todas já custaram missões, ver `CLAUDE.md`):
`printf … | grep -q` devolve 141 quando ACHA sob `pipefail` — use herestring · comentário `#`
dentro de bloco continuado por `\` quebra em silêncio e `bash -n` não acusa · função com efeito em
global é **chamada**, nunca substituída · mawk é byte-oriented: classe negada só com ASCII ·
apóstrofo dentro do programa jq encerra a string shell · editar `agents/*.md` exige sincronizar
`.claude/agents/` **byte-idêntico** (o preflight compara com `cmp -s`).

## Arquitetura da mudança

Tudo em `bin/sdd`, com sensores em `tests/check-kaizen.sh` e `tests/check-autonomy.sh`, mutações em
`tests/check-mutation.sh`, e prosa em `docs/pipeline.md` + `agents/sdd-kaizen.md` onde o schema da
série é descrito. Um arquivo novo: o ADR.

O contrato que muda é o **schema da série** que o juiz é mandado citar: dois campos entram —
`guard.degenerate_axis` (bool) e `excluded.no_repo` (int). Os dois são **derivados**, não fatos
novos: nenhum evento do ledger nasce ou muda, e `autonomy_kit_stamp` fica intocado. O literal do
ledger vazio (`bin/sdd:2382`) é o **segundo produtor** da mesma shape e precisa dos dois campos no
mesmo commit — foi assim que `excluded` ganhou o quarto balde na missão passada, e
`tests/check-kaizen.sh` compara os dois produtores como conjuntos de chave.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — ADR 0003: a pergunta que o juiz responde

⚠️ **Este incremento é um ADR, não código, e vem PRIMEIRO.** A tentação é tratar markdown como
"documentação depois": aqui o ADR é o artefato que autoriza os outros quatro. Sem ele, o I2 cita
um documento que não existe.

**O quê:** `docs/adr/0003-judge-axis-evidence-from-target-repos.md`, no formato dos dois
existentes. Registra: a decisão (evidência de veredito vem de repo-alvo real; o eixo `kit_sha`
não muda; o piso `>= 3` não afrouxa), a medição que a motivou (24 shas × 1 sessão; latest/previous
virando duas fases da mesma missão, US$ 1,48 vs US$ 7,31), a alternativa descartada com o motivo
(carimbar por missão não resolve — cada missão do kit produz o próprio sha) e as consequências (o
kit não é fonte de veredito sobre si mesmo; `indeterminado` lá é correto; o I13.4 depende de
missões em alvo).
**Onde:** `docs/adr/0003-*.md`.
**Como (TDD):** as 2 asserções primeiro, vermelhas.
**Check:** conta `^  ok    adr 0003` → `2`.
**Sensor durável:** duas asserções em `tests/check-kaizen.sh` com o prefixo `adr 0003`: (1) o
arquivo existe e tem as três seções do formato; (2) **`bin/sdd` cita a string `0003`** — ADR órfão
de código é rótulo, e é a segunda asserção que impede o documento de virar decoração.
**Reversível por:** remover o arquivo + as 2 asserções.

### I2 — o runner explica o `indeterminado` estrutural

**O quê:** hoje o humano lê `sufficient: false` e não distingue "faltam missões" de "este eixo não
funciona aqui". A série passa a expor `guard.degenerate_axis: true` quando **todo** sha do recorte
tem exatamente 1 sessão **e** há mais de um sha (um sha só é "começou agora", não degenerado), e
`cmd_kaizen` imprime a frase citando o ADR 0003.
⚠️ **Uma definição por programa.** O predicado nasce como `def` único no programa jq de
`kaizen_series`, ao lado de `is_escalation`/`on_axis` (`bin/sdd:2394-2403`) — nunca repetido nos
dois leitores. É a regra que já custou o par `blocked`/`degraded`: escrito à mão em três lugares,
dois aprenderam o evento novo e o terceiro ficou cego.
⚠️ O literal do ledger vazio (`bin/sdd:2382`) recebe `degenerate_axis: false` no mesmo commit.
**Onde:** `bin/sdd` (programa jq de `kaizen_series`, literal vazio, `cmd_kaizen`), mais a prosa do
schema em `docs/pipeline.md` e `agents/sdd-kaizen.md` (sincronizar `.claude/agents/`).
**Como (TDD):** asserção diferencial primeiro — fixture do kit degenerado (3 shas × 1 sessão) ⇒
`degenerate_axis: true` **e** a frase na saída do comando; fixture de alvo (3 missões no mesmo sha)
⇒ `false` **e a ausência** da frase. Exigir o texto do ramo certo e a ausência do marcador do
outro é o que impede a asserção de passar pelo regime do fixture.
**Check:** conta `^  ok    degenerate axis` → `2`.
**Sensor durável:** as 2 asserções + mutação `KAIZEN_degenerate_axis_blind`.
**Reversível por:** remover o `def`, o campo, a frase e as asserções.

### I3 — `--all-repos` nos três leitores

**O quê:** flag em `sdd autonomy` e `sdd kaizen --series`, e por herança no `kaizen_reminder`.
Liga/desliga `ledger_row_is_local` (`bin/sdd:887`) — o predicado único é o ponto de entrada certo,
sem quarta cópia da pergunta. Com a flag, `excluded.other_repo` vira `0` e as linhas entram. O
`usage()` documenta que o default é local **e por quê** (contaminação de fixture, `d99a7fc`).
**Onde:** `bin/sdd` (`ledger_row_is_local`, parsers de opção de `cmd_autonomy` e `cmd_kaizen`,
`usage`), `config/schema.md` se a chave aparecer lá, `docs/pipeline.md`.
**Como (TDD):** asserção diferencial primeiro, no MESMO ledger de dois repos: sem flag
`other_repo: N` e `missions: M`; com flag `other_repo: 0` e `missions > M`. As duas saídas
comparadas entre si — nenhum regime de fixture satisfaz as duas por acidente.
**Check:** conta `^  ok    all-repos` → `2`.
**Sensor durável:** as 2 asserções + mutação `AUTONOMY_all_repos_ignored` (a flag vira no-op).
**Reversível por:** remover a flag + asserções.

### I4 — identidade de repo sobrevive a worktree

**O quê:** `ledger_repo_root` (`bin/sdd:865`) passa a derivar a identidade do `.git` compartilhado
(`git rev-parse --git-common-dir`, normalizado para caminho absoluto do repo lógico) em vez do
toplevel, que é por worktree. `$REPO_ROOT` continua respeitado quando aponta para o mesmo repo
lógico. Worktree é fluxo de primeira classe aqui (o próprio `superpowers:using-git-worktrees` e o
item de multi-missão do `TODO.md` assumem isso).
⚠️ Mudar a identidade muda o valor gravado em `repo:`. Linhas antigas do ledger seguem com o
toplevel antigo — o plano NÃO migra o arquivo (ledger é imutável); documentar no ADR/na prosa que
linhas pré-conserto de um worktree seguem contadas em `other_repo`, e que isso é histórico, não bug.
**Onde:** `bin/sdd:865-869`.
**Como (TDD):** asserção diferencial primeiro — fixture com repo principal + `git worktree add`:
linha escrita no worktree é lida como **local** no checkout principal, e vice-versa. Antes do
conserto as duas leituras discordam; depois, concordam.
**Check:** conta `^  ok    worktree` → `2`.
**Sensor durável:** as 2 asserções + mutação `LEDGER_repo_root_toplevel` (voltar ao
`--show-toplevel`).
**Reversível por:** restaurar as duas linhas + asserções.

### I5 — linha sem `repo` ganha balde próprio

**O quê:** `ledger_row_is_local` trata linha sem o campo `repo` como local em **todo** repo
(`else true end`), e o comentário de `bin/sdd:785` afirma que os leitores as classificam em voz
alta — mas `is_unrecognized` (`bin/sdd:2311`) olha `.event`, não `.repo`. Passa a existir
`excluded.no_repo`: contado, nunca somado ao recorte, nunca descartado em silêncio (número que se
move sem explicação é o defeito que o filtro por repo existe para remover). O comentário mentiroso
é corrigido **no mesmo commit** — as três afirmações falsas que a missão passada achou ficaram com
⚠️ e o motivo, e é essa a convenção.
⚠️ `excluded` tem **dois** produtores da mesma shape (o `jq` e o literal vazio de `bin/sdd:2382`):
os dois recebem `no_repo` no mesmo commit, e `tests/check-kaizen.sh` já compara os dois como
conjuntos de chave.
**Onde:** `bin/sdd` (`ledger_row_is_local` ou o programa jq, literal vazio, comentário de `:785`).
**Como (TDD):** fixture com 3 linhas de sessão bem-formadas **sem** `repo` ⇒ `no_repo: 3` e
`guard.sufficient` **permanece** `false`. A segunda metade é a asserção que prova que o balde não
é decorativo: hoje essas 3 linhas viram `sufficient: true`.
**Check:** conta `^  ok    no-repo` → `2`.
**Sensor durável:** as 2 asserções + mutação `LEDGER_no_repo_counted_as_local`.
**Reversível por:** remover o balde + asserções.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `--git-common-dir` devolve caminho relativo (`.git`) quando rodado na raiz | **alta** — é o comportamento documentado do git | normalizar com `cd`+`pwd -P` ou `readlink -f`; o probe do worktree pega, porque compara as duas leituras |
| `degenerate_axis` disparar em alvo novo com 1 sessão só | média | exigir **mais de um sha** no recorte; o fixture de alvo com 1 missão é o probe negativo |
| Campo novo do guard divergir do que o guard gateia | média | reusar a binding única `$observed` (`bin/sdd:2462`) como precedente; `check-kaizen.sh` compara os dois produtores da shape |
| Mudança de identidade reclassificar linhas antigas como `other_repo` | **certa** | é histórico, não bug: documentar no ADR e na prosa; ledger é imutável e não se migra |
| I2/I5 acrescentarem campo e o agente `sdd-kaizen` não saber citá-lo | média | a prosa do schema em `agents/sdd-kaizen.md` e `docs/pipeline.md` muda no mesmo commit (contrato em três lugares) |

## Verificação end-to-end

1. `bash tests/run-all.sh` → `suite green` e `score: 60 caught, 0 known gap(s), of 60`.
2. `./bin/sdd health` → verde nos cinco checks (mutação por gate, proveniência, catraca).
3. `./bin/sdd kaizen --series` neste repo → `guard.degenerate_axis: true`, `sufficient: false`; e
   `./bin/sdd kaizen --dry-run` imprime a explicação citando **ADR 0003**.
4. `./bin/sdd autonomy` vs `./bin/sdd autonomy --all-repos` no ledger real → a segunda enxerga o
   que a primeira exclui, com `other_repo` caindo a `0` e `missions` subindo.
5. `git worktree add` num diretório temporário, escrever uma linha de ledger de lá, e conferir que
   o checkout principal a lê como local.
6. Os 5 itens do `TODO.md` (guarda insatisfazível; juiz cego a repo-alvo; worktree; linha sem
   `repo`; lembrete pós-pipeline que manda a um comando que não vê o que contou) carregam
   `RESOLVIDO por <hash>` — contados por `grep`.
