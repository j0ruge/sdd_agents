---
missao: 20261117-o-worker-orquestrador
fase: QA
status: done
sessao: 88bbb544-df78-408c-abe1-362ae691960b
data: 2026-11-18 04:14
gate: sem interface (`E2E_CMD` e `APP_URL` vazios); reteste depois de `F1` (42d1a56) e `F2` (8add018), jornadas da CLI `bin/sdd-worker` caminhadas no terminal em cópias `mktemp -d`, sem assinar a delegação real. `tests/run-all.sh` no `5fa1eac` → rc 0, `suite green`, 2132 linhas `ok`, 14 min 01 s, `anchors: all 839 mutants still apply and leave valid code`; `tests/check-worker.sh` → 37 `ok`, 0 linhas fora delas (`seal: ` 1, `legible: ` 2). Os 7 mutantes dos F (`mut_WORKER_seal_*` 2, `mut_WORKER_legible_*` 5) → `check-worker.sh dies (rc 1)` cada um por `tests/check-mutation.sh --only` contra o `check-worker.sh` sozinho. J3: `delegate` mostra as seis chaves e `ceiling L1: -` a `ceiling L6: plan`; `< /dev/null` → rc 66, `n` e Enter → rc 0, sem escrita; `y` → só `signed: 2026-11-18 03:55 b89e28b3243a`, e um sha256 independente das seis chaves mais as seis linhas `ceiling` dá o mesmo `b89e28b3243a`. J5 (Q1): o L6 trocado de `plan` para `-` → `level assisted — edited after signing`, `allows approve`/`merge --lot L6` → `ask`, rc 1; o L7 acrescentado sob `lots: all` → `assisted`; o L1 baixado para `pr` → `assisted`; item riscado e título/contagem do L2 reescritos → `level full`, L6 `plan`. J6 (Q2 e Q3): `campaign: outra` no `campaign.md` → `level`/`allows` `assisted — illegible`, `next` → `stop`, rc 1, `budget` → `no ceiling`, rc 1, `delegate` recusa, rc 1; o id placeholder → `next` `stop`, rc 1; `campaign: outra` na delegação → `illegible`; `dir/`, `.` e symlink → `full`; `expires: 2026-11-18 99:99` → `delegate` rc 1 e `level` `illegible: … is no instant on the clock`, idem `2026-11-31 10:00`. Campanha real: `level` → `assisted — illegible`, `budget` → rc 1, `next` → `run L1 20261117-l1-a-prosa-do-chapeu`. 0 achados novos, 0 F pending, 0 para o humano.
---

# Handoff — QA — O worker orquestrador

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Reteste do ciclo 1 da QA, sem interface: J3, J4, J5, J6 e J7 refeitas no terminal em cópias `mktemp -d`, e a J2 sobre a campanha real (só leitura); a suíte está verde no `5fa1eac`.
Os três achados do ciclo 1 estão fechados: Q1 por `F1` (42d1a56), Q2 e Q3 por `F2` (8add018). Cada "esperado" das jornadas J5 e J6 foi visto, e nenhuma jornada achou defeito novo.
Os sensores regressivos existem e morrem com o bug de volta: famílias `seal: ` e `legible: ` no `tests/check-worker.sh`, e os 7 mutantes dos F são pegos, cada um por `--only`.
0 achados novos, 0 F `pending`, 0 para o humano. Próximo passo: REVIEW.

## Estado do repo

- **Branch:** `feat/o-worker-orquestrador`, sem upstream (o PR é fase futura).
- **Último commit:** `5fa1eac` `chore(checkpoint): F2 feito em 8add018, e o handoff de EXEC do ciclo 1 da QA` (antes do commit desta fase).
- **Working tree:** limpa antes desta sessão; ela muda só este arquivo e acrescenta uma linha ao `checkpoint-notas.md`.
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 2132 linhas `ok`, 14 min 01 s, 839 mutantes aplicam (`--anchors`), rodada no `5fa1eac` das 03:53 às 04:07.
- **E2E:** `E2E_CMD` vazio: o kit não tem interface, e não há spec Playwright a escrever.

## O que foi feito

- `7d624d7` (ciclo 1 da QA): oito jornadas, os achados Q1 a Q3 e os incrementos `F1` e `F2`.
- `42d1a56` (`F1`, EXEC) e `8add018` (`F2`, EXEC): os consertos e os sensores, retestados aqui.
- o commit `chore(qa): …` desta sessão, o primeiro depois de `5fa1eac`: o reteste abaixo, uma nota no `checkpoint-notas.md` e este handoff. Nenhum arquivo de produção ou de teste foi tocado.

### O reteste

Todas com `W=bin/sdd-worker` pelo caminho absoluto do worktree. As cópias são um `git init` em
`mktemp -d` com `.sdd/config.sh` (`HANDOFF_DIR="docs/handoffs"`, `ON_ESCALATION_CMD` vazio ou
`"true"`) e a campanha real copiada com `cp -r`; os scripts rodaram sob `bash` e a cópia foi apagada
no fim. A delegação real não foi editada nem assinada.

| # | Jornada | Resultado |
|---|---|---|
| J2 | A campanha real, só leitura: `level`, `budget`, `next` | ✅ `level assisted — illegible: expires '<YYYY-MM-DD HH:MM, hora local>' is not YYYY-MM-DD HH:MM`; `budget` → `no ceiling — illegible`, rc 1; `next` → `run L1 20261117-l1-a-prosa-do-chapeu — approved, and no pull request has the head fix/l1-a-prosa-do-chapeu` e `ahead plan L2`, rc 0 |
| J3 | O dono assina numa cópia, por pipe (`level: full`, prazo daqui a 2 h, tetos 30 e 200) | ✅ o `delegate` mostra as seis chaves e seis linhas `ceiling` (`L1` a `L5` com `-`, `L6` com `plan`) antes da pergunta; `< /dev/null` → rc 66, árvore limpa; `n` e Enter → rc 0, árvore limpa; `y` → `git diff` de uma linha só (`signed: 2026-11-18 03:55 b89e28b3243a`), e o digest bate com um sha256 calculado fora do programa; sem pager → `assisted — no pager`; com pager → `level full`, L6 → `level plan — capped by the lot`, `allows run`/`plan --lot L6` rc 0, `merge`/`approve --lot L6` rc 1, `approve --lot L1` rc 0; teto da campanha editado → `edited after signing … now give 350e9e1f13a9`, desfeito → `full`; `SDD_WORKER_NOW` 3 h à frente → `expired`, em 2020 → sem efeito; prazo vencido → `delegate` `not signed — expired`, rc 1 |
| J4 | A mesma assinatura num pty de verdade (`script -qec`) | ✅ a pergunta aparece depois das linhas `ceiling`; Enter → nada escrito; `y` → assina, e o `level --lot L6` de uma delegação `merge` responde `plan — capped by the lot` |
| J5 | O teto do lote depois da assinatura (comandos abaixo) | ✅ **Q1 fechado** |
| J6 | A identidade da campanha e o instante (comandos abaixo) | ✅ **Q2 e Q3 fechados** |
| J7 | Uma campanha nova de um alvo, a partir de `templates/campaign.md` e `templates/delegation.md` | ✅ templates crus → `illegible: campaign: '<YYYYMMDD>-<slug …>' in …/delegation.md is not the directory's name`, e o `next` → `stop`, rc 1, pelo id do `campaign.md`; ids preenchidos → `illegible: level '<assisted …>' is not on the ladder`; preenchida e assinada `full` → o `delegate` mostra `ceiling L1: -` e `ceiling L2: plan`, L1 → `full`, L2 → `plan — capped by the lot`, `approve --lot L2` → `ask`, rc 1; `next` → `plan L1 - — no mission of campaign 20261118-alvo-novo declares lot: L1` |

As jornadas J1 (uso) e J8 (`pr-ready` contra o GitHub real) não foram refeitas: os dois F não tocam
o `usage` nem o `cmd_pr_ready` (`git show --stat 42d1a56 8add018`), e o `tests/check-worker.sh`
cobre as duas famílias (`usage: `, `pr-ready: `) verde no `5fa1eac`.

### J5 — o teto do lote depois da assinatura (o Q1, refeito)

```bash
# numa cópia: git init, .sdd/config.sh com ON_ESCALATION_CMD="true", a campanha real copiada,
# delegação preenchida full e assinada por printf 'y\n' (J3)
C=docs/superpowers/campaigns/20261117-zerar-as-issues; D=$C/delegation.md
"$W" level "$C" --lot L6                  # level plan — capped by the lot: the ceiling of L6 is plan
sed -i 's/^| L6 | \(.*\) | plan | 11 |$/| L6 | \1 | - | 11 |/' "$C/campaign.md"
"$W" level "$C" --lot L6                  # level assisted — edited after signing: signed b89e28b3243a, … now give b093329499d5
"$W" allows "$C" approve --lot L6         # ask approve needs full, effective assisted — edited after signing …, rc 1
"$W" allows "$C" merge --lot L6           # ask merge needs merge, effective assisted — edited after signing …, rc 1
# desfeito; depois um L7 com teto - acrescentado à tabela, sob lots: all
"$W" level "$C" --lot L7                  # level assisted — edited after signing …; allows approve --lot L7 → ask, rc 1
# desfeito; depois o teto do L1 baixado de - para pr
"$W" level "$C" --lot L1                  # level assisted — edited after signing … (o custo aceito: baixar também pede assinatura)
# desfeito; depois o 1º item riscado (- [ ] → - [x]) e o título e a contagem do L2 reescritos
"$W" level "$C"                           # level full — signed until …
"$W" level "$C" --lot L6                  # level plan — capped by the lot: the ceiling of L6 is plan
```

### J6 — a identidade da campanha e o instante (o Q2 e o Q3, refeitos)

```bash
# mesma cópia, delegação assinada full com pager
mkdir -p docs/handoffs/m-real docs/handoffs/m-outra
printf -- '---\ncampaign: 20261117-zerar-as-issues\nlot: L1\nbranch: fix/a\naprovacao: humano-2026-11-18\n---\n' > docs/handoffs/m-real/00-missao.md
printf -- '---\ncampaign: outra\nlot: L1\nbranch: fix/b\naprovacao:\n---\n' > docs/handoffs/m-outra/00-missao.md
sed -i 's/^campaign: .*/campaign: outra/' "$C/campaign.md"
"$W" level "$C"                # level assisted — illegible: campaign: 'outra' in …/campaign.md is not the directory's name '20261117-zerar-as-issues'
"$W" allows "$C" run --lot L1  # ask run needs pr, effective assisted — illegible: …, rc 1
"$W" next "$C"                 # stop - - — illegible: campaign: 'outra' in …/campaign.md …, rc 1
"$W" budget "$C"               # no ceiling — illegible: campaign: 'outra' …, rc 1
printf 'y\n' | "$W" delegate "$C"   # not signed — illegible: campaign: 'outra' …, rc 1
sed -i 's/^campaign: .*/campaign: <YYYYMMDD>-<slug — igual ao nome do diretório desta campanha>/' "$C/campaign.md"
"$W" next "$C"                 # stop - - — illegible: campaign: '<YYYYMMDD>-<slug …>' … is not the directory's name …, rc 1
# campaign.md desfeito; a delegação com campaign: outra
"$W" level "$C"                # level assisted — illegible: campaign: 'outra' in …/delegation.md is not the directory's name …
# desfeito: o diretório pelo caminho, com barra no fim, por . e por um symlink
"$W" level "$C"; "$W" level "$C/"; (cd "$C" && "$W" level .); "$W" level "$T/atalho"   # level full — signed until … (as quatro)
# Q3, com os ids certos:
sed -i 's/^expires: .*/expires: 2026-11-18 99:99/' "$D"; printf 'y\n' | "$W" delegate "$C"   # not signed — illegible: expires '2026-11-18 99:99' is no instant on the clock, rc 1
"$W" level "$C"                # level assisted — illegible: expires '2026-11-18 99:99' is no instant on the clock
sed -i 's/^expires: .*/expires: 2026-11-31 10:00/' "$D"
"$W" level "$C"                # level assisted — illegible: expires '2026-11-31 10:00' is no instant on the clock
```

## Achados

### Q1 — o teto do lote não estava sob a assinatura → `F1` (42d1a56), fechado

O `delegation_terms` passou a ser a única definição do que a assinatura concede (as seis chaves e
uma linha `ceiling <lote>: <teto>` por linha do `lots_table`), lida pelo `delegate` que a mostra e
assina e pelo `effective_level` que a confere. O teto e o digest saem do mesmo leitor
(`lots_table`), então não há duas leituras da tabela para divergir. Sensor: família `seal: ` (R34)
e `mut_WORKER_seal_ceilings_unsigned` e `mut_WORKER_seal_ceilings_unshown`, ambos pegos aqui.

### Q2 — o id da campanha não era conferido → `F2` (8add018), fechado

O `id_is_dir` é a regra única (o `campaign:` igual ao nome do diretório resolvido por
`readlink -f`), aplicada pelo `delegation_legible` aos dois arquivos e pelo `next` ao `campaign.md`.
Sensor: família `legible: ` (R35) e quatro dos cinco `mut_WORKER_legible_*`.

### Q3 — um instante que não existe era legível → `F2` (8add018), fechado

O `expires:` tem de voltar do `date -d` como foi. Sensor: `legible: ` (R36) e
`mut_WORKER_legible_instant_unchecked`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261117-o-worker-orquestrador/30-handoff-qa.md` | este handoff, reescrito depois do `F2` |
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` | uma linha do reteste (append) |
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint.md` | `F1` e `F2` `done` pela EXEC; esta sessão não o tocou |
| `tests/check-worker.sh` | os regressivos dos três achados (`seal: `, `legible: `), commitados pela EXEC nos F |

Não há relatório datado, spec Playwright nem arquivo de bug: o kit não tem interface, e a árvore
`docs/qa/` (que já existia, e esta sessão não tocou) é das skills. O registro `docs/qa/bugs/` não
tem nenhum `Status: open`.

## Boot da próxima fase

**Para a REVIEW:** o que a QA viu e o revisor não precisa redescobrir:

1. O `pr-ready` lê o recibo real do Codex e o GraphQL real dos threads (J8 do ciclo 1, PR 330); o
   `next` real lê o worktree do L1 (J2, refeita hoje); o `budget` lê o ledger real e bate com um
   `jq` independente (J7 do ciclo 1).
2. As paradas de falha fechada que a QA tentou quebrar e não quebrou: stdin fechado no `delegate`
   (rc 66), `gh` sem remote no `next` (rc 3), o `<A>` do template no `pr-ready`, e depois dos F o
   teto editado, o lote acrescentado, os ids divergentes e o placeholder do id.
3. O digest do `signed:` é reproduzível fora do programa: sha256 das linhas `key: value` das seis
   chaves, na ordem `campaign level lots expires budget_mission_usd budget_campaign_usd`, seguidas
   de `ceiling <lote>: <teto>` por linha da tabela, primeiros 12 hex (J3).
4. A ADR 0022 §3 ainda diz "the signature carries a digest of the other fields" (linha 72-73), e
   desde o `F1` o digest também cobre o teto de cada lote do `campaign.md`. A EXEC deixou a ADR
   aceita como estava (nota do `F1`): a frase ficou menos precisa, não falsa. Decidir se ela muda é
   da REVIEW ou da DOCS.

**Para a DOCS:** três derivas pequenas, de prosa, que esta missão criou, todas conferidas no
`5fa1eac`. (1) `README.md:46` sugere `ln -s …/bin/sdd ~/.local/bin/sdd` como alternativa ao `PATH`,
e nesse arranjo (o desta máquina: `~/.hermes/bin/sdd` é um symlink) o `sdd-worker` da lista de
comandos (`README.md:116`) não está no `PATH`; o `commands/sdd-worker.md` resolve o caminho sozinho,
o README não diz como. (2) `docs/pipeline.md:1917-1920`, no parágrafo do `budget`, diz que as
missões são "the folders under the repo's `HANDOFF_DIR`", e o código (`campaign_mission_dirs`) lê
também todo worktree ligado, como o parágrafo do `next` já diz. (3) A frase da ADR 0022 §3 do item 4
acima, se a REVIEW não a decidir.

## Pendências / Decisions for a Human

- Nenhuma. Os três achados do ciclo 1 tinham causa técnica e estão fechados; o reteste não achou
  nada que peça decisão de produto.

## Riscos e não-feitos

- **Não refeitas:** J1 e J8 (os F não tocam o `usage` nem o `cmd_pr_ready`; o sensor cobre as duas
  famílias). O `pr-ready` e o `next` contra um PR **aberto** do GitHub real seguem não verificados
  (não havia nenhum: `gh pr list --head feat/o-worker-orquestrador --state all` → `[]` no ciclo 1);
  a fixture do sensor cobre esse mundo.
- **Não verificado:** o `ON_ESCALATION_CMD` disparando de verdade: os verbos só leem se ele está
  vazio, e a página é da sessão do worker (`commands/sdd-worker.md`, "The five stops").
- **Não rodado:** `./bin/sdd health` (o carimbo), pela regra do dono citada no `00-missao.md`. Os 7
  mutantes dos F foram provados por `--only`, que é dica e não carimbo.
- **Fora do alcance de qualquer verbo, e declarado na ADR:** a sessão do worker tem `Bash` e pode
  responder `y` ao próprio `delegate`. O `commands/sdd-worker.md` proíbe, e é prosa.
- **Limites que a EXEC declarou nos F, e que a QA não conseguiu quebrar:** a comparação de volta do
  `date -d` não tem mundo no GNU date 9 (24:00, 23:60 e o buraco do horário de verão já são
  recusados pelo `date`); o `${1%/}` do `delegation_legible` só muda a barra dupla no caminho do
  motivo. A J6 viu `dir/`, `.` e symlink lidos como o próprio diretório.

## Achados fora de escopo

- Nenhum novo. O que a EXEC já mandou para cá (o `health_provenance` do `bin/sdd` que não alcança
  `tests/fixtures/codex-review-state.txt`) continua no `20-handoff-exec.md`, e esta sessão não o
  reabriu.
