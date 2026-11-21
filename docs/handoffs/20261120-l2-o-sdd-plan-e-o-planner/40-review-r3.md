---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: REVIEW
rodada: 3
status: done
sessao: 723ca6a1-33c8-4c2b-b659-719fb963a190
data: 2026-11-21 01:31
gate: "tests/run-all.sh rc=0 (suite green, 2237 linhas ok, 0 FAIL, 926 mutantes aplicam) sobre 7a168ad, com a árvore parada (a 1ª corrida, rc 1 com 4 FAIL no check-autonomy por kit-touched, teve este arquivo escrito no worktree durante a suíte); scan de segredos 0 achados (regex + gitleaks, 27 arquivos, 2595 linhas, errors: []); sdd review-base → full — merge 4b60b47 entered after 40-review-r2.md"
reviewed_head: 7a168adca69c34460ee8911cf917dabdb4cc8f7a
---

# Review — rodada r3 — L2: o `/sdd-plan` e o planner

## TL;DR

Rodada do worker, **inteira** pelo `sdd review-base` (`full — merge 4b60b47 entered after
40-review-r2.md`), com `/codereview:codereview base=daf51f9`. O merge-base com a `origin/main` é o
`daf51f9`, e a rodada leu a branch toda: `daf51f9..7a168ad`, 27 arquivos, +2595/−57. Foram 5
revisores por arquivo (sonnet) e a varredura de código morto, todos com o marcador de fim, mais a
leitura cruzada. Os cinco consertos dos achados do CodeRabbit no `cec8c9b` fecham o achado como
escrito, cada um reproduzido aqui: guarda do `HOME` igual à gramática em 21 de 21 casos; as duas
asserções novas do `check-hat.sh` ficam vermelhas sobre o `sdd-plan.md` de antes; o `red_one` de
antes enxertado numa cópia deixa vermelhos os 3 probes novos (rc 90); o `PROBE_FLOOR=451` reprova
(rc 92). A refutação do achado 6 se sustenta, mas com a conta corrigida: hoje o Check do I6 responde
`16`, e não `15`. Saíram um MEDIUM de prosa e cinco LOW, nenhum num verbo de confiança, e nada fica
abaixo de A. Nenhum `R<n>`: o lote vai ao chore pós-merge do L2. Feita como subagente da sessão
orquestradora (o `sessao:`). Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O pré-passo e o seletor do --only leem agora o mesmo array, por igualdade, e a guarda do HOME no config repete a gramática do read_extra_dir_ok sem divergir dela (21 de 21 casos comparados). |
| Type Safety | A | Não se aplica a bash; os arrays novos (pend, named) nascem declarados local -a e nada fica sem guarda de set -u no sensor. |
| Error Handling | A | O --only recusa a lista com elemento vazio, espaço ou quebra de linha (rc 96) e o id que é pedaço de outro (rc 1); o único LOW é o config morrer com HOME não definido, caso em que o ledger do runner já morre. |
| Security | A | O scan de segredos (regex e gitleaks) deu 0 achados em 27 arquivos, e o READ_EXTRA segue só leitura, agora sem nascer com um HOME que a gramática recusa. |
| Performance | A | Os laços novos percorrem a lista de ids pendentes, de poucos elementos, e a guarda do HOME é um case; nada roda a mais na suíte. |
| Test Coverage | A | Os 3 probes novos do --only ficam vermelhos sobre o código de antes (reproduzido por enxerto), o piso 450 é justo (451 reprova) e as 2 asserções novas do check-hat.sh reprovam o comando de antes. |
| Documentation | A | Os achados do CodeRabbit estão fechados no texto, e o que sobra é um MEDIUM de prosa no template e quatro LOW de forma ou de evidência, que a régua manda ao lote sem segurar a nota. |
| **Overall** | **A** | Nenhum achado CRITICAL ou HIGH, nem MEDIUM num verbo de confiança; a suíte rápida dos sensores avulsos está verde e os consertos dos bots foram reproduzidos nos dois sentidos. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM (prosa) | A linha-modelo do contexto verificado aceita um `arquivo:linha` nu e pede o comando só "ao lado de toda contagem". O parágrafo logo acima, no mesmo template, pede o comando ao lado de toda contagem **e de toda âncora**, e o `/sdd-plan` diz o mesmo e devolve ao planner "a count or an anchor with no command beside it". O mesmo pede o `agents/sdd-planner.md:109`, e o `:105` ainda diz "with `file:line` or the command output". O planner que segue a linha-modelo tem as âncoras devolvidas no aceite, com o humano esperando. Nenhum gate lê essa seção. | `templates/plano.md:19`, contra `templates/plano.md:15-17`, `commands/sdd-plan.md:283-285`, `agents/sdd-planner.md:105` |
| 2 | LOW | O `case "$HOME"` lê o `HOME` sob o `set -u` do runner. Com o `HOME` não definido, o `source` morre (reproduzido: `env -u HOME bash -c 'set -u; source .sdd/config.sh'` → `HOME: variável não associada`, rc 127), e o comentário promete que "nesse HOME a chave fica vazia". No `daf51f9` o config não lia o `HOME` (0 ocorrências). O `sdd run` já morreria pelo ledger (`${SDD_STATE_DIR:-$HOME/.sdd}`, `bin/sdd:3667`), mas o `sdd status --no-gates` não morria. Direção: `case "${HOME:-}"`, com `''` no braço da recusa. O `HOME` vazio dá `/.claude/…`, que a gramática aceita e não faz mal. | `.sdd/config.sh:57` |
| 3 | LOW | Os dois probes `notran "$rc_w"` não têm controle positivo durável de que o Check da linha `I1,I2` consegue criar o `ran-c`. Reproduzido aqui que hoje alcança: com o `red_one` de antes enxertado numa cópia, o terceiro probe reprova com `notran …/ran-c did not hold`, rc 90. Um probe `ran` do modo inteiro sobre o mesmo fixture manteria isso provado. | `tests/check-checkpoint.sh:3449-3461` |
| 4 | LOW | "Without it the subagent inherits the model of this session, whatever the hat says" foi medido com um chapéu sem `model:` no frontmatter (só a prosa dizia Fable). Com o `model: fable` declarado agora, o que o harness faz sem o modelo na chamada não foi medido; é a pendência 4 do `00-missao.md`. A frase deveria dizer o que se mediu. | `commands/sdd-plan.md:116` |
| 5 | LOW | O ramo `auto` do aceite manda `git switch -c <branch>` ou `git switch <branch>` e commitar ali, mas não cobre o `branch:` placeholder, que o chapéu admite com `JIRA_ENABLED=true` (`agents/sdd-planner.md:302-304`, a TICKET cria a branch). Com ele, o relay cortaria uma branch com o nome do placeholder. Direção: placeholder → cair no "Anywhere else". | `commands/sdd-plan.md:345-351` |
| 6 | LOW | O "Depois" do KAIZEN diz `PROBE_FLOOR=447` e `--count` → **105**, medidos no head da DOCS (`07f581e`, e o ponto da medida está escrito). No `HEAD` são 450 (`00b8fad`) e 106 (o merge `4b60b47` trouxe o item do #455). O delta da própria branch segue +7 (99 → 106). | `KAIZEN_LOG.md:26`, `:30` |

## Incrementos de conserto (R<n>)

Nenhum. Pela régua A da rodada, só um CRITICAL/HIGH, ou um MEDIUM reproduzido num verbo de confiança,
abre `R<n>`. O #1 é prosa de template e os #2 a #6 são LOW. Os seis vão **num lote** ao chore
pós-merge do L2, cuja rodada os confere, como os LOW da r4 do L1b vieram a ele. O #2 e o #3 tocam
`.sdd/config.sh` e `tests/`, mas são de uma linha cada, e cabe ali o Check de comando:

- #2: `env -u HOME bash -c 'set -u; . .sdd/config.sh; echo "[${READ_EXTRA-unset}]"'` → `[unset]`;
- #3: `bash tests/check-checkpoint.sh` → rc 0, com o `PROBE_FLOOR` subindo junto com o probe novo.

## O que virou incremento

Nenhum `R<n>` novo. Os seis achados do CodeRabbit sobre o `cec8c9b`, conferidos contra o código do
`HEAD`:

1. **`.sdd/config.sh`, `READ_EXTRA` com um `HOME` fora da gramática**: fechado em `4c44ac6`. O `case`
   foi comparado com o `read_extra_dir_ok` do `bin/sdd:5453`, extraído do próprio runner, sobre o
   caminho inteiro que a chave formaria, em 21 `HOME`s: com espaço, `+`, `//`, barra final, `/`,
   relativo, `.`/`..` no meio e no fim, `..x`, `ü`, `$`, `*`, tab, quebra de linha e vazio. Deu **0
   divergências**. Resíduo: o `HOME` não definido (achado #2).
2. **A saída do tópico já planejado vinha depois da do checkout ocupado**: fechado em `a1d4338`. A
   do tópico é a primeira, com o porquê no texto, e a referência do passo 2 virou "the second exit
   of step 1" (`commands/sdd-plan.md:83`). A asserção lê a ordem pelo número da linha, e com o
   `sdd-plan.md` de `a1d4338^` numa cópia ela reprova (`FAIL  command: /sdd-plan takes the worktree
   route of a held checkout before it looks for a folder that already covers the topic…`).
3. **A vigia do checkout principal parava em toda edição não commitada da corrida**: fechado em
   `a1d4338`, como escrito. O arquivo rastreado que mudou vai ao humano na linha do hand-back, e a
   parada fica só para o `??` novo fora da pasta da missão. O limite está declarado: nada atribui um
   caminho não commitado, e a anatomia § 6 só atribui commit. O que sobra cai do lado seguro: a
   corrida que cria um arquivo novo ainda não commitado para o grill até o humano dizer de quem é.
   A asserção nova reprova o comando de antes (mesma cópia).
4. **"Isola o effort"**: fechado em `7a168ad`, no `KAIZEN_LOG.md`, que é o registro que persiste. A
   entrada diz agora que a comparação é observacional e por quê, e nomeia a frase do `00-missao.md`
   que corrige. Deixar o `00-missao.md` como foi aprovado se sustenta: é o plano que o humano
   aprovou. As razões 37,9/22,8 = 1,66 e 3,49/1,32 = 2,6 conferem.
5. **O `--only` casava o id como pedaço da lista juntada**: fechado em `00b8fad`. O `red_one` de
   `00b8fad^`, enxertado no sensor do `HEAD` numa cópia (`git archive`), deixa vermelhos os 3 probes
   novos: `wanted rc 1, got 0` duas vezes e `notran …/ran-c did not hold`, rc 90. No `HEAD` o sensor
   sai rc 0, com 0 `FAIL` e a linha `rule: --red --list … (38 probe(s))`. O `PROBE_FLOOR=451` numa
   cópia sai rc 92 (`only 450 probe(s) ran`): o piso é justo. Conferi também as bordas da lista:
   `I7,`, `,I7` e `I7,,R1` saem rc 96, e `I7,I7` roda o I7 uma vez (`1 of 2 … a partial measure`).
6. **O Check do I6 espera `14`**: a refutação se sustenta (seção seguinte).

Os achados abertos das rodadas anteriores: o #3 da r1 (a ordem do `gate_EXEC` no `plan-only.md`)
foi fechado em `0da9417`, e o revisor do arquivo conferiu a lista nova contra o `gate_EXEC`
(`bin/sdd:1429`). O #2 da r1 (o `pgrep` sem pasta de missão) segue aberto no `TODO.md:902`, e o
revisor do `sdd-plan.md` o achou de novo (não é item novo).

## O que foi refutado

- **Achado 6 do CodeRabbit** (`checkpoint.md:56`, o Check do I6 espera 14 e responde outro número).
  A refutação se sustenta: nenhum leitor re-roda o Check de uma linha `done`. O `gate_EXEC`
  (`bin/sdd:1429`) lê o status e o hash de cada linha e roda o `TEST_CMD`, e o `--red` só roda
  linhas `pending`. Medido no fechamento: `df7b55e:TODO.md` tem 15 `RESOLVED by`, e o merge-base de
  então, `079bc39`, tem 1, logo **14**, como a célula diz. **A conta da refutação está errada, porém**:
  hoje o comando responde **16**, e não 15. São 14 do I1 ao I5, 1 do I7 (`d48f7c9`) e 1 da DOCS
  (`0da9417`, o item do `plan-only.md`), contra 0 no merge-base de hoje, `daf51f9`. O "15º é do I7"
  do `20-handoff-exec.md` e o "15 `RESOLVED by`" da linha do `TODO.md` no `45-docs.md` eram verdade
  antes do `07f581e`. São registros datados, que não pedem conserto, mas a resposta ao bot deve dizer 16.
- **Revisor do `check-checkpoint.sh`, "o `--only` não abre janela" exagera**: o cabeçalho
  (`tests/check-checkpoint.sh:115-120`) diz só que "an id that is no pending row is refused before
  any Check runs". Dos refusals, esse é o único que o pré-passo faz, e o comentário do `red_one`
  fala desse mesmo. As recusas de forma e de verde de uma linha nomeada seguem no laço, como no modo
  inteiro, e o texto não promete outra coisa.
- **Revisor do `check-autonomy.sh`/`check-dry-run.sh`, a limpeza só é provada pela linha que arma**:
  é o desenho, e o comentário o declara. Apagar a limpeza e o `export` juntos fica verde só onde
  nenhum `EFFORT_*` chega exportado. Onde chega, a suíte reprova: falha fechada, não fail-open.
- **Revisor do `.sdd/config.sh`, o `EFFORT_EXEC` vem do ambiente**: deliberado e comentado
  (`.sdd/config.sh:45-48`), e o `config_reload` restaura a foto do ambiente a cada volta. Voltar ao
  literal `medium` é decisão do chore pós-merge, pelo critério que o dono já escreveu.

## Achados fora de escopo

- **Um terceiro sensor lê o `EFFORT_*` de quem chama: o regime do `sdd close` do
  `tests/check-gates.sh`.** O primeiro `close_run` (`tests/check-gates.sh:6387`) roda sem limpar o
  ambiente e espera `unset:-` e `effort=settings` (`:6410`). O `load_config` mantém um `EFFORT_TICKET`
  exportado (`bin/sdd:161`), e o `cmd_close` o passa como `--effort` (`bin/sdd:12922`), então um
  lançamento com `EFFORT_TICKET=… sdd run` deixa o `gate_EXEC` vermelho, como o L2 viu com o
  `EFFORT_EXEC`. Não reproduzido ponta a ponta: o mecanismo foi lido no código, e o `check-gates.sh`
  é longo demais para rodar ao lado da suíte em curso. LOW: falha fechada, sem consumidor medido, e
  em código que a branch não tocou. É a forma que a direção do item do `d48f7c9` ("numa definição
  só, no molde do `tests/isolate-git.sh`") teria coberto, e que o I7 trocou por dois sítios. Vai ao
  `TODO.md` como item novo, porque o resolvido nomeia "dois sensores" e sai no merge. Quem registra
  é a sessão orquestradora; esta rodada não edita o `TODO.md`.
- O `pgrep` do passo 1 sem pasta de missão (`commands/sdd-plan.md:30-31`, contra "a live `sdd run`
  of this repository" na `:39`) segue no item aberto do `TODO.md:902`. Não ganha linha nova.

## Pendências / Decisions for a Human

Nenhuma.
