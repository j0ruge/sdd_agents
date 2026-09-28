---
missao: 20260928-os-achados-da-janela
data: 2026-09-28
---

# Plano — os achados da janela do juiz

> **Teste de autocontenção:** uma sessão nova, lendo só `00-missao.md` + este arquivo +
> `checkpoint.md`, executa. O texto dos cinco achados a registrar está no I1, porque a fonte deles
> (`~/.claude/plans/2026-09-28-handoff-achados-do-kit.md`) mora fora do repo.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi lido nesta sessão de `sdd kaizen` (2026-09-28, `HEAD` = `4fd0f31` na branch
`kaizen/o-veredito-da-janela-do-juiz`). Número de linha envelhece: ancore no símbolo.

- `qa_substep()` — `bin/sdd:1873`: sem `E2E_CMD` e sem `APP_URL` responde `close`; sem charter
  responde `plan`; senão `report="$(latest_matching "$qa/reports/*.md")"` e `close` se
  `report_closed "$report"`. Nada amarra o relatório à missão.
- `gate_QA()` — `bin/sdd:1126`; a Âncora 1 (`bin/sdd:1160`) repete o mesmo `latest_matching` sobre
  `$REPO_ROOT/$QA_DOCS_PATH/reports/*.md`, depois `report_closed` e a Âncora 2 (`Pending`) sobre o
  **mesmo** arquivo. `latest_matching()` — `bin/sdd:770`.
- Item aberto do `TODO.md`: **`gate_QA` aceita relatório de QA de OUTRA missão** (primeiro item de
  "Sensores que faltam", âncora `bin/sdd:1155`), fail-open desde 2026-08-27.
- `close_return_home()` — `bin/sdd`, imediatamente acima de `cmd_close()`: sai calado sem
  `DEFAULT_BRANCH`, avisa e fica se a árvore está suja, `git checkout "$DEFAULT_BRANCH"`, e
  `ok "back on '$DEFAULT_BRANCH' — the mission branch is merged and spent"`. Nunca `die` (o
  comentário acima dela explica: o close já teve sucesso). **Sem probe**:
  `grep -n "merged and spent\|staying on\|could not return" tests/*.sh` → vazio.
- `COORDINATION_PYTHON=(python3 -I -S)` — `bin/sdd:9718`, uma definição para os quatro sítios; o
  `die "CHECKOUT-UNAVAILABLE: coordinated commands require Python 3 and Linux procfs"` —
  `bin/sdd:9754` — cobre só a ausência de `python3`.
- `bin/sdd-coordination.py`: `sys.exit('CHECKOUT-UNAVAILABLE: Python 3.9+ is required')` na linha
  17; `pidfd_capability()` (linha ~104) chama `os.pidfd_open` e `signal.pidfd_send_signal` e testa
  `/proc/<pid>/task/<tid>/children`; o `except (OSError, ValueError, AttributeError)` do `__main__`
  imprime a lista inteira de requisitos + o erro cru. Um `os` sem `pidfd_open` levanta
  `AttributeError` — a mensagem hoje não diz nem que foi o `pidfd_open`, nem qual interpretador.
- `tests/check-coordination.sh` já tem probes `unavailable pidfd refuses before config: missing` e
  `help survives unavailable pidfd: missing` — o mundo "sem pidfd" existe; o I3 acrescenta a
  asserção sobre o **texto**, não o mundo.
- Sensores imprimem `  ok    <asserção>` na stdout (conferido em `check-coordination.sh` e
  `check-gates.sh`). Checks ancoram em `^  ok    `.
- `bash tests/check-todo.sh --count TODO.md` → `83`; `tests/health-baseline.txt` → `todo-findings 83`.
- O `sdd-kaizen` não escreve fora de `docs/handoffs/<missão>/**` e `KAIZEN_LOG.md` (`writes:` do
  chapéu) — por isso o registro no `TODO.md` é o I1 desta missão, e não da sessão que a planejou.
- Este repo é o kit: `sdd health` roda **depois do último commit de código** e antes do merge
  (`gate_PR` exige o carimbo). `tests/health-baseline.txt` invalida o carimbo — o I1 vem primeiro
  por isso.

## Triagem do `TODO.md` (sessão do `sdd kaizen`)

- **Lido corpo a corpo:** 83 abertos (`bash tests/check-todo.sh --count TODO.md` → `83`).
- **Resolvidos a apagar:** nenhum. `grep -n 'RESOLVED by' TODO.md` só acha a linha 693, que está
  na seção `<!-- sdd:decided -->` (é uma decisão sobre o próprio token, não um item fechado).
- **Escolhidos para esta missão:** o item aberto do achado 4 (fail-open: a Âncora 1 promete "a QA
  desta missão fechou" e mede "existe alguma QA fechada"), mais os achados 7 e 8 da janela, que têm
  consumidor fora da suíte (a missão seguinte no alvo; o humano no terminal). Os três com o maior
  dano medido na janela e o menor raio de mudança.
- **Admissão (D15) dos cinco que entram no I1:** 2 e 3 são fail-open (prometem medir o que não
  medem); 1, 5 e 6 têm consumidor fora da suíte (missões de alvo). Nenhum é dívida de sensor que
  caiba num cabeçalho de limites declarados — por isso não há seção "vai para o cabeçalho" neste plano.
- **Os outros 82 abertos ficam onde estão, intocados.**

## Arquitetura da mudança

Três consertos independentes no runner e um registro no backlog. Nenhum contrato entre fases muda:
o `gate_QA` fica **mais estrito** sobre qual arquivo lê, o `sdd close` faz um passo a mais depois
do sucesso, e o helper de coordenação diz mais na mesma recusa (mesmo rc, mesmo prefixo).

## Incrementos

### I1 — registrar os cinco achados que esta missão não conserta

**O quê:** cinco itens novos na seção `<!-- sdd:open -->` do `TODO.md`, no formato de
`templates/todo.pt-BR.md` (~6 linhas, teto 8, âncora em código a ≤10 linhas de um símbolo citado,
último campo `— descoberto por \`sdd-kaizen\` na missão \`20260928-os-achados-da-janela\` (2026-09-28)`,
ou pelo agente e missão de origem se o executor os achar no ledger). Antes de escrever, procure
duplicata no `TODO.md`. Os cinco (texto-fonte; a âncora exata o executor confere):

1. **Célula Commit de incremento fora do git** — `templates/checkpoint.md` (bloco da célula Commit):
   não diz o que vai na célula de um incremento cujo produto não é commit (config num IdP); o
   `gate_EXEC` exige forma de SHA. Missão `20260927-idioma-da-spa-pelo-idp` (lighthouse, LH-4).
2. **`gate_TICKET` só lê o frontmatter** — `agents/sdd-ticket.md` promete que o runner confirma a
   issue; o gate lê só o `10-ticket.md`. Fail-open (promete mais do que mede). Mesma missão.
3. **O preflight aceita app de outro produto na `APP_URL`** — o probe diz "something is listening"
   e passa com o `sales_quote` na `:5173` do `lighthouse`. Fail-open. Direção: `<title>` ou marcador
   do produto. Mesma missão.
4. **A Âncora 3 do `gate_QA` conta bug legado de outra missão** — a QA fica sem status honesto e
   satisfazível; foi a escalada `handoff-blocked` da LH-4. Mesma missão.
5. **A DOCS contorna pelo Bash a negativa do harness em `.claude/rules/`** — `agents/sdd-docs.md`
   declara `.claude/rules/**` no `writes:` e não diz o que fazer quando o harness nega o `Edit`
   (caminho sensível, headless); a sessão escreveu com `python3` pelo Bash em
   `20260927-breadcrumb-numero-cotacao` e `20260928-ver-vira-olho-na-lista`. Direção: UMA regra — ⛔
   com texto proposto, ou permissão explícita.

E no item existente **`gate_QA` aceita relatório de QA de OUTRA missão**: uma linha com as duas
recorrências (`20260927-idioma-da-spa-pelo-idp` e `20260928-ver-vira-olho-na-lista`) e o
`qa_substep` como segundo sítio — sem passar do teto de 8 linhas.
**Onde:** `TODO.md`, `tests/health-baseline.txt` (`todo-findings 83` → `88`, mesmo commit).
**Como (TDD):** o Check falha antes (`83`), passa depois (`88`), e `check-todo.sh` segue verde.
**Check:** ver `checkpoint.md`.
**Sensor durável:** `tests/check-todo.sh` (forma, âncora, teto) e a catraca `todo-findings`.
**Reversível por:** `git revert` do commit.

### I2 — o `sdd close` deixa a `DEFAULT_BRANCH` em dia

**O quê:** depois do `git checkout "$DEFAULT_BRANCH"` bem-sucedido em `close_return_home`, se a
branch tem upstream: `git fetch` só daquela branch e `git merge --ff-only @{upstream}`. Falha de
rede ou divergência **avisa e segue** (`warn`, nunca `die`, pelo mesmo argumento do comentário da
função), e o `ok` final diz se fez fast-forward ou não. Sem upstream: comportamento de hoje.
**Onde:** `bin/sdd` (`close_return_home`), `tests/check-autonomy.sh` (é lá que moram os regimes do
`cmd_close`; conferir antes com `grep -n cmd_close tests/check-autonomy.sh`), `docs/pipeline.md`
(o parágrafo do `sdd close`).
**Como (TDD):** fixture com um remoto bare local, `DEFAULT_BRANCH` local um commit atrás da remota,
branch de missão limpa; a asserção `close: fast-forwards the default branch to its upstream` exige
`git rev-parse <branch> == git rev-parse <branch>@{upstream}` depois do close — vermelha antes. Mais
um mundo divergente: asserção `close: a diverged default branch is warned, never forced` (o sha local
não muda e o aviso aparece).
**Check:** ver `checkpoint.md`.
**Sensor durável:** as duas asserções + um mutante no catálogo (`tests/check-mutation.sh`) que apaga
o `merge --ff-only` e é pego.
**Reversível por:** revert; o close volta a só fazer checkout.

### I3 — o `CHECKOUT-UNAVAILABLE` diz qual requisito caiu e em qual Python

**O quê:** em `bin/sdd-coordination.py`, a recusa nomeia o requisito que falhou (ex.: `os.pidfd_open
is missing from this Python build`, `procfs has no task children enumeration`, `Python 3.9+`) e
sempre anexa `sys.executable` e `platform.python_version()`, mais o remédio (`put a python3 that has
os.pidfd_open first in PATH, e.g. /usr/bin/python3`). O prefixo `CHECKOUT-UNAVAILABLE:` e o rc não
mudam — há probes e o `bin/sdd` que os leem. No `bin/sdd`, o `die` de "sem `python3`" passa a dizer
qual `PATH` foi procurado.
**Onde:** `bin/sdd-coordination.py`, `bin/sdd` (o `die` junto de `COORDINATION_PYTHON`),
`tests/check-coordination.sh`.
**Como (TDD):** no mundo que o probe `unavailable pidfd refuses before config: missing` já monta,
nova asserção `unavailable: names the interpreter and the missing requirement` exige o caminho do
interpretador e o nome `pidfd_open` na saída — vermelha antes.
**Check:** ver `checkpoint.md`.
**Sensor durável:** a asserção nova em `check-coordination.sh`.
**Reversível por:** revert; a mensagem volta à lista genérica.

### I4 — a QA só fecha com o relatório da própria missão

**O quê:** UMA função (ex.: `mission_qa_report`) que devolve o relatório mais recente de
`$QA_DOCS_PATH/reports/*.md` **que pertence à missão** e vazio se nenhum pertence; `qa_substep` e a
Âncora 1 do `gate_QA` passam a chamá-la no lugar do `latest_matching` cru (uma definição, dois
leitores — regra do enum do `CLAUDE.md`). Critério proposto (confirmar no grill, `00-missao.md`
§ Pendências): o arquivo foi adicionado ou modificado em `git merge-base "$DEFAULT_BRANCH" HEAD..HEAD`
**ou** aparece em `git status --porcelain`. Sem relatório da missão: `qa_substep` responde `exec`
(se há charter) e o `gate_QA` reprova com `no report of this mission in <dir> (newest is <arquivo>,
from before the mission branch)`. Ramo "projeto sem interface" intocado. Captura guardada contra
`set -e` (`|| true` / `if out=…`), como o `CLAUDE.md` exige.
**Onde:** `bin/sdd` (`qa_substep`, `gate_QA`, função nova perto de `latest_matching`),
`tests/check-gates.sh`, `tests/check-mutation.sh`, `docs/pipeline.md` (Âncora 1 do QA),
`agents/sdd-qa.md` se ele descrever a escolha do relatório (conferir com `grep -n reports agents/sdd-qa.md`).
**Como (TDD):** fixture git: relatório `closed` commitado na base (outra missão), branch de missão
sem relatório → asserções `QA gate refuses a closed report from another mission` e `qa_substep
does not close on another mission's report` (vermelhas antes); relatório da missão commitado na
branch → `QA gate accepts the mission's own closed report` (verde antes e depois — controle).
**Check:** ver `checkpoint.md`.
**Sensor durável:** as asserções + mutantes: um que troca a função nova por `latest_matching` no
gate, outro no `qa_substep` (um mutante por leitor).
**Reversível por:** revert; volta o fail-open documentado no `TODO.md`.

### I5 — docs, backlog e registro

**O quê:** `RESOLVED by <hash do I4>` no item do `TODO.md` do achado 4; entrada no `KAIZEN_LOG.md`
com o antes/depois medido (os quatro fatos da Métrica); linha na gaveta
(`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`) se alguma frente dela se mexeu;
`.claude/rules/anatomia-do-agente.md` § 4 se a dívida "Âncoras 1 e 2 satisfeitas por relatório de
outra missão" estiver lá (está: fechar a linha no mesmo commit).
**Onde:** `TODO.md`, `KAIZEN_LOG.md`, `.claude/rules/anatomia-do-agente.md`, gaveta.
**Check:** ver `checkpoint.md`.
**Sensor durável:** `check-todo.sh` (forma do `RESOLVED by`); o resto é prosa.
**Reversível por:** revert.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Alvo onde a skill `qa-execution` **não commita** o relatório e a sessão limpa a árvore antes do gate | média | o critério aceita arquivo sujo; se o gate ler árvore limpa sem commit, o `sdd-qa` já commita o handoff — conferir no fixture com o fluxo real do `sdd-qa.md` |
| Missão cuja branch não nasce da `DEFAULT_BRANCH` (merge-base antigo) aceitar relatório velho | baixa | o merge-base é o ponto de partida da missão por construção do `ensure_mission_branch`; declarar o limite no comentário da função |
| `git fetch` no close pendurar sem rede | baixa | `GIT_TERMINAL_PROMPT=0` e aviso em falha; nunca `die` |
| Não verificado: que `tests/check-autonomy.sh` já tem fixture de `cmd_close` reaproveitável | — | se não tiver, o fixture do I2 nasce no `check-gates.sh` ou num regime novo; o executor decide e anota |
| Mutantes novos quebrarem âncoras de outros | média | `bash tests/check-mutation.sh --anchors` antes de cada commit de código |

## Verificação end-to-end

`bash tests/run-all.sh` verde; os quatro Checks do `checkpoint.md` com o esperado; `./bin/sdd health`
uma vez depois do último commit de código, com `N caught of N` e o carimbo; `todo-findings 88` sem
achado novo no health.
