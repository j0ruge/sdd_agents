---
missao: 20261117-o-worker-orquestrador
fase: QA
status: done
sessao: c35b9ddf-805f-4458-a123-781325f628b6
data: 2026-11-18 01:56
gate: sem interface (`E2E_CMD` e `APP_URL` vazios); 8 jornadas da CLI `bin/sdd-worker` caminhadas no terminal, sempre em cópias `mktemp -d`, e a delegação real NÃO foi assinada. `tests/run-all.sh` no `699b090` → rc 0, `suite green`, 2129 linhas `ok`, 828 s, `anchors: all 832 mutants still apply`; `tests/check-worker.sh` → 34 `ok`. Campanha real: `level` → `level assisted — illegible: expires '<YYYY-MM-DD HH:MM, hora local>' is not YYYY-MM-DD HH:MM`; `budget` → `no ceiling — illegible`, rc 1; os 7 `allows … --lot L1` → `ask`, rc 1; `next` → `run L1 20261117-l1-a-prosa-do-chapeu` e `ahead plan L2`, rc 0. Assinatura numa cópia: stdin fechado → rc 66 sem escrita; `n` e Enter → rc 0 sem escrita; `y` → só a linha `signed:` muda; sem pager → `assisted — no pager`; com pager → `level full`, e o L6 → `level plan — capped by the lot`. `pr-ready` contra a API real do PR 330 (clone `--shared`, rodada com `reviewed_head:` no head) passa `review`, `codex` (recibo real do bot) e `threads` e para em `not-ready mergeable: the pull request is MERGED`. 3 achados confirmados (Q1 a Q3) → `F1` e `F2` pending; 0 para o humano.
---

# Handoff — QA — O worker orquestrador

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Projeto sem interface: 8 jornadas da CLI `bin/sdd-worker` caminhadas no terminal, em cópias `mktemp -d`; a suíte está verde no `699b090`.
Três achados confirmados, todos na fronteira entre a assinatura e o que ela devia prender. O Q1 é o caro: o teto do lote (o `plan` do L6) mora fora do digest, e uma edição do `campaign.md` depois da assinatura libera `approve` no L6 sob `full`.
Os três viraram dois incrementos de conserto, `F1` (Q1) e `F2` (Q2 e Q3), `pending` no checkpoint. Nenhum vai para o humano.
Nenhum sensor novo foi escrito nesta sessão: o `writes:` do `sdd-qa` não alcança `tests/`, então o regressivo é do executor, em TDD. O vermelho de cada achado foi medido aqui, pelas jornadas J5 e J6 abaixo.
Próximo passo: EXEC roda `F1` e `F2`, e a QA volta para refazer J5 e J6 e reescrever este handoff.

## Estado do repo

- **Branch:** `feat/o-worker-orquestrador`, sem upstream (o PR é fase futura).
- **Último commit:** `699b090` `chore(checkpoint): I11 feito em 3fe5d3e, e o handoff de EXEC` (antes do commit desta fase).
- **Working tree:** limpa antes desta sessão; ela muda só `checkpoint.md`, `checkpoint-notas.md` (uma linha por F, append) e este arquivo.
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 2129 linhas `ok`, 828 s, 832 mutantes aplicam (`--anchors`), rodada no `699b090` às 01:38.
- **E2E:** `E2E_CMD` vazio: o kit não tem interface, e não há spec Playwright a escrever.

## O que foi feito

- o commit `chore(qa): …` desta sessão, o primeiro depois de `699b090`: as jornadas abaixo, os incrementos `F1` e `F2` no checkpoint, duas notas no `checkpoint-notas.md` e este handoff. Nenhum arquivo de produção ou de teste foi tocado.

### As jornadas

Todas com `W=bin/sdd-worker` da raiz do worktree, ou o caminho absoluto dele dentro de uma cópia. As
cópias são um `git init` em `mktemp -d` com `.sdd/config.sh` (`HANDOFF_DIR="docs/handoffs"` e
`ON_ESCALATION_CMD` vazio ou `"true"`) e a campanha real copiada com `cp -r`, nunca a real editada.
⚠️ Rode-as sob `bash`, não no zsh da sessão: o zsh não divide `$a` em palavras, e a primeira passada
da J1 respondeu rc 2 pelo motivo errado, com o verbo e o diretório num argumento só.

| # | Jornada | Resultado |
|---|---|---|
| J1 | Uso: sem verbo, verbo desconhecido, diretório que não existe, `--lot` sem lote, `--lote L1`, ato `deploy`, `pr-ready … abc` e `… 0`, `budget` sem diretório, `next` com argumento a mais | ✅ todos rc 2 com o uso na stderr; o ato fora da tabela diz antes `'deploy' is not an act (run pr review plan merge postmerge approve)` |
| J2 | A campanha real, só leitura: `level`, `level --lot L6` e `--lot L9`, `budget`, os 7 `allows … --lot L1`, `next` | ✅ as respostas do boot da EXEC, uma a uma; o `next` acha o L1 no worktree `~/repos/sdd_agents-l1` (`aprovacao: humano-2026-11-17`, `campaign:` e `lot: L1` declarados) e o `gh pr list --head fix/l1-a-prosa-do-chapeu --state all` real devolve `[]` |
| J3 | O dono assina numa cópia, por pipe: preenche `level: full`, `expires` daqui a 2 h e os tetos 30 e 200 | ✅ `< /dev/null` → rc 66, árvore limpa; `n` e Enter → rc 0, árvore limpa; `y` → `signed: 2026-11-18 01:39 01455c601c82` e `git diff` só nessa linha; sem pager → `assisted — no pager: ON_ESCALATION_CMD is empty in …`; com pager → `level full — signed until …`, L6 → `level plan — capped by the lot`, `allows run`/`plan --lot L6` rc 0, `merge`/`approve --lot L6` rc 1, `approve --lot L1` rc 0; teto da campanha editado → `edited after signing`, desfeito → `full` de novo; `SDD_WORKER_NOW` 3 h à frente → `expired`, em 2020 → sem efeito; `expires` vencido → `not signed — expired`, rc 1 |
| J4 | A mesma assinatura num terminal (`script -qec … /dev/null`, pty de verdade) | ✅ a pergunta aparece, `y` assina, Enter não escreve nada |
| J5 | O teto do lote depois da assinatura (comandos abaixo) | ❌ **Q1** |
| J6 | A identidade da campanha e o instante (comandos abaixo) | ❌ **Q2** e **Q3** |
| J7 | Uma campanha nova de um alvo, a partir de `templates/campaign.md`, `templates/delegation.md` e `templates/missao.md` | ✅ templates crus → `illegible: level '<assisted …>' is not on the ladder`; missão do template com `aprovacao:` placeholder → `approve L1 …`; aprovada, num repo sem remote → `no git remotes found` e rc 3 sem ato; `lots: L1` → `--lot L2` é `lot not covered`; `budget` sobre o ledger real conta as duas missões e soma US$ 47,71, a mesma soma que um `jq` independente dá para as 11 linhas desta missão (o que mostra o `jq` lendo o ledger real sob `LANG=pt_BR.UTF-8`) |
| J8 | `pr-ready` contra o GitHub real (só leitura) | ✅ PR 330 com a rodada da REVIEW → `not-ready review: the newest round names no head`; esta missão, sem rodada → `no 40-review-r<N>.md`; PR 999999 → rc 3 sem item. Num clone `--shared` com `origin` no GitHub e uma rodada `reviewed_head: 6160ae1…` (o head do PR 330): A em tudo → passa `review`, `codex` (o recibo real do `chatgpt-codex-connector[bot]`, `completed`, sem achado) e `threads` (GraphQL real) e para em `not-ready mergeable: the pull request is MERGED and UNKNOWN`; nota `B` e o `<A>` do template → `review`; `reviewed_head` no pai → `tests/check-hat.sh changed after the reviewed head` |

### J5 — o teto do lote depois da assinatura (o vermelho do Q1)

```bash
# numa cópia: git init, .sdd/config.sh com ON_ESCALATION_CMD="true", a campanha real copiada
C=docs/superpowers/campaigns/20261117-zerar-as-issues; D=$C/delegation.md
sed -i "s/^level: .*/level: full/; s/^expires: .*/expires: $(date -d '+2 hours' '+%Y-%m-%d %H:%M')/; s/^budget_mission_usd: .*/budget_mission_usd: 30/; s/^budget_campaign_usd: .*/budget_campaign_usd: 200/" "$D"
printf 'y\n' | "$W" delegate "$C"
"$W" level "$C" --lot L6                  # level plan — capped by the lot: the ceiling of L6 is plan
sed -i 's/^| L6 | \(.*\) | plan | 11 |$/| L6 | \1 | - | 11 |/' "$C/campaign.md"
"$W" level "$C" --lot L6                  # hoje: level full — signed until …      esperado: assisted — edited after signing
"$W" allows "$C" approve --lot L6         # hoje: allowed approve at full, rc 0      esperado: ask …, rc 1
"$W" allows "$C" merge --lot L6           # hoje: allowed merge at full, rc 0        esperado: ask …, rc 1
```

Acrescentar um lote `L7` com teto `-` à tabela, com `lots: all`, é o mesmo buraco: um lote que o dono
nunca viu entra no nível assinado. O re-walk do `F1` refaz os oito comandos e acrescenta esse lote.

### J6 — a identidade da campanha e o instante (o vermelho do Q2 e do Q3)

```bash
# mesma cópia, delegação assinada full com pager
mkdir -p docs/handoffs/m-real docs/handoffs/m-outra
printf -- '---\ncampaign: 20261117-zerar-as-issues\nlot: L1\nbranch: fix/a\naprovacao: humano-2026-11-18\n---\n' > docs/handoffs/m-real/00-missao.md
printf -- '---\ncampaign: outra\nlot: L1\nbranch: fix/b\naprovacao:\n---\n' > docs/handoffs/m-outra/00-missao.md
sed -i 's/^campaign: .*/campaign: outra/' "$C/campaign.md"
"$W" level "$C"     # hoje: level full — signed until …                                esperado: assisted, nomeando o id
"$W" next "$C"      # hoje: approve L1 m-outra — …, rc 0 (a fila de OUTRA campanha)     esperado: stop, rc 1
"$W" budget "$C"    # hoje: campaign US$ 0.00 of 200.00 — 1 mission(s) (a m-real)       esperado: no ceiling, rc 1
sed -i 's/^campaign: .*/campaign: <YYYYMMDD>-<slug — igual ao nome do diretório desta campanha>/' "$C/campaign.md"
"$W" next "$C"      # hoje: plan L1 - — no mission of campaign <YYYYMMDD>-<slug …>, rc 0 esperado: stop, rc 1
# Q3, numa delegação com o id certo:
sed -i 's/^expires: .*/expires: 2026-11-18 99:99/' "$D"; printf 'y\n' | "$W" delegate "$C"
"$W" level "$C"     # hoje: signed …, e level full — signed until 2026-11-18 99:99      esperado: not signed — illegible, rc 1
```

## Achados

### Q1 — o teto do lote não está sob a assinatura (→ `F1`)

- **Onde:** `bin/sdd-worker`, `effective_level` (o teto sai de `lots_table "$dir/campaign.md"`) e
  `delegation_digest` (só as seis chaves de `DELEGATION_KEYS`); o `cmd_delegate` imprime só as seis.
- **O que a missão prometeu:** a decisão 8 do `00-missao.md` ("os itens do L6 têm teto de autonomia
  `plan`, qualquer que seja o nível assinado"), a ADR 0022 §6 ("the design lot of the kit's campaign
  is capped at `plan`, so its approval is never delegated") e a §3 (o `delegate` "shows what is being
  granted").
- **O que acontece:** o teto mora num arquivo que ninguém assina. Uma edição comum do `campaign.md`,
  sem nenhum digest forjado, sobe o L6 de `plan` para o nível assinado, e a assinatura continua
  valendo. O dono assina sem ver os tetos.
- **Por que não é o limite declarado:** a ADR declara que "the signature proves an answer on stdin,
  not a person", e isso é sobre quem responde à pergunta. Aqui ninguém responde nada: é uma edição
  de arquivo, que o contrato diz invalidar a delegação, e não invalida.
- **Direção (do executor):** o digest passa a cobrir as linhas `Lot`/`Ceiling` que o `lots_table` lê
  (não os itens nem os títulos, que a campanha vai riscar), e o `delegate` as imprime antes da
  pergunta. A campanha real está sem assinatura, então nenhuma assinatura existente quebra. O
  contrato muda em `templates/delegation.md`, `docs/pipeline.md` (`## The worker`, "The signature")
  e na prosa do `delegation.md` da campanha real ("Mudar qualquer uma das seis chaves…"), no mesmo
  commit.
- **Custo de produto, aceito:** baixar um teto depois de assinar também pede assinatura nova. É o
  lado seguro, e não é decisão nova: é a regra que a delegação já aplica às suas seis chaves.

### Q2 — o id da campanha não é conferido (→ `F2`)

- **Onde:** `cmd_budget` lê o `campaign:` da delegação; `cmd_next` lê o do `campaign.md`; nenhum
  verbo os compara entre si nem com o nome do diretório, que é o contrato escrito em
  `templates/campaign.md` ("igual ao nome do diretório desta campanha"), `templates/delegation.md`
  ("igual ao campaign: do campaign.md ao lado") e `docs/pipeline.md` ("the id, the directory's name").
- **O que acontece:** com os dois ids diferentes, o `budget` soma as missões de uma campanha e o
  `next` anda na fila de outra: o teto da campanha deixa de medir o que o worker roda. E o id
  placeholder do template passa como id: o `next` responde `plan L1`, rc 0, sobre um `campaign.md`
  que ninguém preencheu, onde devia parar como para no `campaign:` vazio.
- **Direção:** uma regra só, que o `id` é o nome do diretório: fora dela a delegação é ilegível
  (`level` e `allows` → `assisted`, `budget` → `no ceiling`, `delegate` recusa) e o `next` para com
  rc 1 nomeando os dois valores. Os fixtures do `tests/check-worker.sh` já nascem assim (a função
  `campaign()` cria `docs/campaigns/<id>` e escreve `<id>` nos dois arquivos).

### Q3 — um instante que não existe é legível (→ `F2`)

- **Onde:** `delegation_legible`, que só aplica a regex `^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$`.
- **O que acontece:** `2026-11-18 99:99` é assinado e respondido como `signed until 2026-11-18 99:99`.
  O efeito é limitado (a comparação por dígitos o faz vencer antes de `2026-11-19 00:00`), mas o dono
  que digita `2026-11-31` assina um prazo que o relógio não tem e lê de volta a data errada.
- **Direção:** o instante tem de sobreviver a uma ida e volta pelo relógio
  (`date -d "$v" '+%Y-%m-%d %H:%M'` devolve o próprio `$v`), na mesma função.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint.md` | `F1` e `F2` `pending`, com Check vermelho no HEAD (`tests/check-checkpoint.sh --red` → `2 pending Check(s), every one red at HEAD`) |
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` | uma linha por F, dizendo de que achado ele nasceu e a família de asserção que ele usa |
| `docs/handoffs/20261117-o-worker-orquestrador/30-handoff-qa.md` | este handoff |

Não há relatório datado, spec Playwright nem arquivo de bug: o kit não tem interface, e a árvore
`docs/qa/` (que já existia, e esta sessão não tocou) é das skills. Os bugs vivem nos Q acima e nas
linhas F. O registro `docs/qa/bugs/` não tem nenhum `Status: open`.

## Boot da próxima fase

**Para a EXEC (`F1`, depois `F2`):**

1. Leia os achados Q1 a Q3 acima e as duas últimas notas do `checkpoint-notas.md`.
2. TDD: a asserção nova entra primeiro no `tests/check-worker.sh` e fica vermelha. **Use as famílias
   novas** `seal: ` (F1, uma linha) e `legible: ` (F2, duas linhas: a identidade e o instante).
   Nenhuma linha nova nas famílias dos I (`usage: `, `delegate: `, `level: `, `allows: `, `budget: `,
   `next: `, `pr-ready: `, `command: `, `docs: `): os Checks do I2 ao I10 contam essas linhas, e uma a
   mais os deixaria vermelhos. Probe a mais dobra dentro da linha da família.
3. Um mutante por regra no catálogo: `mut_WORKER_seal_*` (F1), `mut_WORKER_legible_*` (F2, dois), cada
   um provado por `tests/check-mutation.sh --only <slug> tests/check-worker.sh`.
4. O F1 muda o digest: o `digest_of` do sensor (que calcula o contrato sem o programa) muda junto, e o
   contrato muda nos três documentos que o Q1 nomeia. O F2 pode exigir ajustar algum fixture do
   sensor cujo diretório não tenha o nome do `campaign:`.
5. Depois de cada F, `tests/run-all.sh` verde (uns 14 min; espere por
   `pgrep -f '^bash tests/run-all\.sh'` e `tail --pid`, nunca por `pgrep -f run-all`).

**Para a QA que volta depois dos F:** refaça J5 e J6 em cópia `mktemp -d` (os comandos estão acima,
com o "esperado" ao lado de cada um), mais a J3 inteira, porque o F1 muda o que o `delegate` imprime
e o digest que ele grava. Reescreva este handoff com o que o reteste viu.

**Para a REVIEW:** o que a QA viu e o revisor não precisa redescobrir: o `pr-ready` lê o recibo real
do Codex e o GraphQL real dos threads (J8, PR 330); o `next` real lê o worktree do L1 (J2); o `budget`
lê o ledger real e bate com um `jq` independente (J7). As três paradas de falha fechada que a QA
tentou quebrar e não quebrou: stdin fechado no `delegate`, `gh` sem remote no `next`, e o `<A>` do
template no `pr-ready`.

**Para a DOCS:** duas derivas pequenas, de prosa, que esta missão criou. (1) `README.md:46` sugere
`ln -s …/bin/sdd ~/.local/bin/sdd` como alternativa ao `PATH`, e nesse arranjo (o desta máquina:
`~/.hermes/bin/sdd` é um symlink) o `sdd-worker` da lista de comandos (`README.md:116`) não está no
`PATH`; o `commands/sdd-worker.md:29` resolve o caminho sozinho, o README não diz como. (2)
`docs/pipeline.md`, no parágrafo do `budget`, diz que as missões são "the folders under the repo's
`HANDOFF_DIR`", e o código (`campaign_mission_dirs`) lê também todo worktree ligado, como o parágrafo
do `next` já diz.

## Pendências / Decisions for a Human

- Nenhuma. Os três achados têm causa técnica e direção que não pedem decisão de produto: o Q1 cumpre
  a decisão 8 e a ADR 0022 §6, e o Q2 cumpre o contrato que os templates já escrevem.

## Riscos e não-feitos

- **O regressivo de cada achado não está commitado ainda.** O `writes:` do `sdd-qa`
  (`$HANDOFF_DIR/$MISSION/**, $QA_DOCS_PATH/**, $E2E_DIR/**`, mais o `TODO.md`) não alcança `tests/`,
  e escrever ali pararia a linha como `hat-crossed`. O vermelho foi medido nas jornadas J5 e J6, e a
  asserção nasce vermelha no TDD do executor, que é quem a commita.
- **Não verificado:** o `next` e o `pr-ready` contra um PR **aberto** do GitHub real (não havia
  nenhum PR da campanha nem desta branch: `gh pr list --head feat/o-worker-orquestrador --state all`
  → `[]`); só contra PRs mergeados, e a fixture do sensor cobre o resto.
- **Não verificado:** o `ON_ESCALATION_CMD` disparando de verdade: os verbos só leem se ele está
  vazio, e a página é da sessão do worker (`commands/sdd-worker.md`, "The five stops").
- **Não rodado:** `./bin/sdd health` (o carimbo), pela regra do dono citada no `00-missao.md`.
- **Fora do alcance de qualquer verbo, e declarado na ADR:** a sessão do worker tem `Bash` e pode
  responder `y` ao próprio `delegate`. O `commands/sdd-worker.md:18` proíbe, e é prosa.

## Achados fora de escopo

- Nenhum novo. O que a EXEC já mandou para cá (o `health_provenance` do `bin/sdd` que não alcança
  `tests/fixtures/codex-review-state.txt`) continua no `20-handoff-exec.md`, e esta sessão não o
  reabriu.
