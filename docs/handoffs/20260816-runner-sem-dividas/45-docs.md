---
missao: 20260816-runner-sem-dividas
fase: DOCS
status: done
data: 2026-08-16 13:40
---

# Documentação — 20260816-runner-sem-dividas

> Uma linha por área que o diff tocou. `✅` carrega o hash do commit que atualizou o doc; `n/a`
> carrega justificativa concreta. Nenhum `✗` fica pendente.

## TL;DR

O diff é de **19 arquivos** fora de `docs/handoffs/` (`7045e0f..08c6634`), e as fases anteriores já
haviam sincronizado a maior parte da prosa **no mesmo commit do conserto**, como o `CLAUDE.md`
manda. Esta fase fechou **quatro drifts que sobraram** e escreveu o `KAIZEN_LOG.md` que o K8 do
plano cobra — tudo em `8658954`.

O achado próprio da fase não estava em doc nenhum: **15 âncoras `arquivo:linha` do `TODO.md`, em 11
itens, apontavam linha errada**. O `bin/sdd` foi de 2287 para 2324 linhas durante a própria missão
que escreveu as âncoras.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `latest_matching()` `sort -V` + sites QA/REVIEW (I2) | `docs/pipeline.md:105,124` | n/a | o doc já dizia "the most recent report" / "the most recent `40-review-r<N>.md`"; era **prosa aspiracional** contra um runner lexicográfico, e o I2 (`6c7b1df`) a tornou verdadeira. Doc correto, código moveu-se até ele — nada a editar |
| `bin/sdd` — dependência de `sort -V` | `README.md` § Requirements | n/a | a linha "the kit calls `md5sum`, `date -Iseconds` and `sort -V`" já existia e o `sdd preflight` (`bin/sdd:1082`) já sondava a ferramenta; nenhuma dependência nova entrou |
| `bin/sdd:1095` — guarda do `sdd install` sem `starter.conf` (I3) | `docs/failure-modes.md` § "`sdd install` refuses to run" | ✅ | seção nova em `8658954`, com a arqueologia do `.sdd/config.sh` de 0 byte que versões antigas deixavam |
| `bin/sdd` — `sdd install` continua idempotente | `README.md:38` | n/a | a guarda é caminho de erro, não muda instalar/usar; pela disclosure progressiva a profundidade foi para `failure-modes.md`, que o README já roteia |
| `bin/sdd:298` — `bad_rows` removido (I4) | — | n/a | remoção de escrita morta, zero mudança de comportamento; nenhum doc descrevia o contador |
| `bin/sdd:843,880` — comentário do `${var:0:200}` (I4) | — | n/a | comentário de código corrigido no próprio commit (`3ef23f4`); é prosa interna sobre corte de `GATE_WHY`, nenhum doc externo a promete |
| `bin/sdd:1841,1923` — uma definição de `on_axis` (I7) | `docs/pipeline.md:368` | n/a | o doc resume as exclusões como "dirty-kit rows"; a linha que separaria as definições (`kit_dirty: null` **com** `kit_sha`) **não é produzida hoje** por nenhum produtor, então a prosa descreve corretamente toda linha existente. O sensor de drift desse schema já tem item próprio no `TODO.md` |
| `bin/sdd:1950,1976` — `guard` ganha `missions_with_session` e `sessions` (I8) | `docs/pipeline.md:366` (guarda) | ✅ | `2132cf5` |
| idem — o campo é de **grupo**, não só da guarda | `docs/pipeline.md:357` (lista de campos por grupo) | ✅ | `8658954` — a lista não citava o campo novo; consumidor lendo-a não saberia que existe |
| idem — contrato que o agente juiz é mandado citar | `agents/sdd-kaizen.md:30` | ✅ | `2132cf5` |
| idem — a cópia que o harness de fato carrega | `.claude/agents/sdd-kaizen.md:30` | ✅ | `5ca2835` (7/7 cópias em sincronia; o sensor que falta é pré-existente e está no `TODO.md`) |
| idem — verbete de glossário "Guarda das 3 missões" | `CONTEXT.md:19` | ✅ | `8658954` — ainda dizia "3 missões observadas" depois de o piso virar missões **com sessão comparável** |
| `bin/sdd:1644` — fim do giro REVIEW→PR→REVIEW (I9) | `docs/pipeline.md:303` | ✅ | `4f98354` |
| idem | `docs/failure-modes.md:166` § "The runner published a draft PR by itself" | ✅ | `4f98354` (inclui como ler ledger antigo com `budget-exhausted` em PR) |
| idem | `config/schema.md:68` (`PUBLISH_ON_REVIEW_BLOCKED`) | ✅ | `4f98354` |
| idem — verbete "Degradação (`review-to-draft`)" | `CONTEXT.md:16` | ✅ | `5ca2835` |
| `bin/sdd:949,973,995` — `run_phase` passa a logar stream (I10) | `docs/pipeline.md:245-260` § "Costs and logs" | ✅ | `f4f859b` |
| idem — o novo artefato em disco é o que o humano vai abrir | `docs/failure-modes.md:228` § "Cost higher than expected" | ✅ | `f4f859b` |
| `bin/sdd:924` — `stream_summary` tolera stream truncado | `docs/pipeline.md` § "Costs and logs" | ✅ | `e470e74` |
| `bin/sdd:1006` — `cost` vazio vira `?` | `docs/pipeline.md` § "Costs and logs" | n/a | o contrato já prometia `?` para custo desconhecido; `628901e` fez o código cumprir a prosa existente |
| `tests/check-pipefail.sh` — sensor novo (I5) | `CLAUDE.md` § "TDD aqui dentro" | ✅ | `f249b87` — nove → **dez** sensores, e duas → **três** com auto-teste |
| `tests/run-all.sh` — lint cobre `tests/*.sh` (I6) | `CLAUDE.md` § "TDD aqui dentro" | ✅ | `f249b87` |
| `tests/check-mutation.sh` — catálogo 30 → 38 | `KAIZEN_LOG.md` | ✅ | `8658954` (o `README.md` fala em "100% mutation score", sem contagem — segue verdadeiro) |
| `tests/check-{gates,autonomy,kaizen,preflight,dry-run}.sh` — asserções e fixtures | — | n/a | asserções internas da suíte; nenhum doc as enumera, e a convenção que as governa (mutação por gate, vermelho pelo motivo certo) já está no `CLAUDE.md` e não mudou |
| `tests/check-lang.sh` — piso de superfície 32 → 33 | — | n/a | consequência mecânica do arquivo novo; a regra da catraca no `CLAUDE.md` § Idioma não mudou |
| `.sdd/config.sh` — `LINT_CMD` nomeia `tests/*.sh` | `CLAUDE.md` § "TDD aqui dentro" | ✅ | `f249b87`. `config/schema.md` descreve a chave genericamente ("Runs in the REVIEW gate when set") e não prescreve alvo — a escolha é deste repo, não do kit |
| `TODO.md` — seção "Runner — defeitos e dívidas" eliminada | o próprio arquivo de achados | ✅ | `8658954` (âncoras + 2 achados novos); métrica da missão medida abaixo |
| `CLAUDE.md`, `CONTEXT.md`, `config/schema.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `agents/sdd-kaizen.md` | — | n/a | aparecem no diff como **destino** do sync, não como origem de drift: cada um já tem linha própria com hash acima. Nenhum ficou sem dono |
| `docs/handoffs/20260816-runner-sem-dividas/*` | — | n/a | artefatos da própria missão, escritos por cada fase; não são documentação viva do repo |

## Disclosure progressiva

Nada foi acrescentado a índice. As duas seções novas foram para o documento **específico**:
o modo de falha do `sdd install` para `docs/failure-modes.md` (que o `README.md` já roteia pela
tabela "Documentation"), e o antes/depois para o `KAIZEN_LOG.md`. O `README.md` **não cresceu** —
foi avaliado linha a linha e nada nele deixou de ser verdade.

Nenhuma regra nova foi inventada. O `CLAUDE.md` mudou nesta missão **uma** vez (`f249b87`) e por
convenção que de fato mudou: a suíte passou a ter dez sensores e o lint passou a cobrir `tests/`.

## Achados do arquivo de findings conferidos nesta missão

`bash tests/check-todo.sh` → **52 finding(s), all within 8 lines and carrying anchor + date**,
selftest de 75 probes, rc 0.

Os **13 itens** que esta missão criou ou modificou foram conferidos um a um contra as cinco partes
que a regra 5 exige (o quê · `arquivo:linha` · por que importa · descoberto por `<agente>` ·
na missão `<slug>` (YYYY-MM-DD)). **Nenhum estava sem uma das partes.** O defeito era outro:

| Defeito | Itens | Conserto |
|---|---|---|
| Âncora presente e **apontando linha errada** | 15 âncoras em 11 itens | resolvidas contra o `HEAD`, uma a uma, em `8658954` |
| Título afirmando causa que o próprio corpo refuta | 1 (flake do `check-autonomy.sh`) | título passa a dizer "causa desconhecida"; a refutação da r2 continua no corpo |
| Alegação de contagem obsoleta | 1 ("**dois** sensores pulados por `SDD_MUTANT`" — o I5 fez três) | corrigido para três, nomeando o do I5 |

Das 15 âncoras, a maioria **apodreceu** (o `bin/sdd` cresceu de 2287 para 2324 linhas durante a
missão que as escreveu) e **três nasceram erradas**. Exemplos medidos: `bin/sdd:1226` caía no bloco
de *plugins* e não no laço de agentes; `bin/sdd:1901` caía num comentário de key-set e não onde o
critério `d` vive (`templates/missao.md:44`); `tests/run-all.sh:41,48` caía em comentários de
diretiva `shellcheck`.

Itens **pré-existentes** com desvio de forma foram deixados como estão e **não** entram neste diff
(regra 5 — não desviar escopo): `TODO.md:213` e `:388` não nomeiam agente, `:378` usa "medido por"
com missões no plural. São variantes antigas, não dívida desta missão.

## Achados novos registrados (regra 5)

1. **O `check-todo.sh` mede a FORMA da âncora, nunca se ela ainda aponta o que o item diz** — é
   "rótulo, não artefato" dentro do arquivo que cataloga essa família. É a causa raiz das 15
   correções acima, e sem sensor elas voltam na próxima missão que mexer no `bin/sdd`.
2. **`.claude/napkin.md` é rastreado, cita `30/30` e `~33 s`, e o harness barra a fase DOCS de
   editá-lo** — runbook lido toda sessão afirmando um ratchet vencido. A correção foi tentada e
   recusada por permissão (arquivo sensível), então a decisão — entra na superfície que o DOCS
   mantém, ou sai do versionamento — fica registrada em vez de perdida.

## Instrumentos rodados nesta sessão

| Instrumento | Resultado |
|---|---|
| `bash tests/run-all.sh` (HEAD) | verde · `score: 38 caught, 0 known gap(s), of 38` · **44,55 s** |
| `bash tests/run-all.sh` (`7045e0f`, worktree descartável) | verde · `score: 30 caught, 0 known gap(s), of 30` · **33,95 s** |
| `./bin/sdd health` | verde nos 5 checks · ratchet 6 dívidas conhecidas, nenhuma nova |
| `bash tests/check-todo.sh` | `52 finding(s)` · selftest 75 probes |
| `bash tests/check-lang.sh` | `0 of 33 surface path(s) still in the allowlist, 0 new` |
| `grep -c 'Runner — defeitos e dívidas' TODO.md` | **`0`** — a métrica da missão |

Os dois tempos foram medidos na mesma máquina e na mesma sessão, o que torna o `+31%` comparável:
são os 8 mutantes novos (cada um roda uma suíte inteira) mais o lint de 11 arquivos a mais.

## Estado do repo ao fim da fase

- **Branch:** `missao/20260816-runner-sem-dividas` — nunca empurrada (o push é da fase PR)
- **Commits desta fase:** `8658954` (sync de documentação + âncoras) e o commit deste artefato
- **Working tree:** limpo
- **Nenhum `✗` na checklist** — toda área do diff tem hash ou justificativa concreta
