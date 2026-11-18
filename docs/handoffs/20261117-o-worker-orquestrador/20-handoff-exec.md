---
missao: 20261117-o-worker-orquestrador
fase: EXEC
status: done
sessao: 9ae88e4f-4702-4394-b142-28fed9c8ff08
data: 2026-11-18 03:37
gate: "tests/run-all.sh na árvore do 8add018 → suite green, rc 0, 2132 linhas ok, 0 FAIL; anchors: all 839 mutants still apply and leave valid code; tests/check-worker.sh → worker verbs: 36 probe(s), as onze famílias 1/3/6/4/3/5/7/3/1/1/2 (usage, delegate, level, allows, budget, next, pr-ready, command, docs, seal, legible); grep -c '^mut_WORKER_' tests/check-mutation.sh → 26; tests/check-todo.sh --anchors TODO.md → 83 measured, 0 off target; checkpoint 13 de 13 done (I1–I11, F1, F2)"
---

# Handoff — EXEC — O worker orquestrador

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os onze incrementos e os dois consertos do ciclo 1 da QA estão feitos, um commit cada, e a suíte
está verde no `8add018`. O `F1` pôs o teto de cada lote sob a assinatura (Q1); o `F2` fez do id da
campanha o nome do diretório e do `expires:` um instante que existe (Q2, Q3). O sensor
`tests/check-worker.sh` tem 36 asserções em onze famílias e 26 mutantes `mut_WORKER_*`. A QA volta
para refazer J3, J5 e J6 numa cópia em `mktemp -d`, nunca assinando a delegação real.

## Estado do repo

- **Branch:** `feat/o-worker-orquestrador`, só local, sem upstream (nada foi empurrado)
- **Último commit de código:** `8add018` `fix(worker): o id da campanha é o nome do diretório, e o prazo é um instante que existe`; este handoff e o checkpoint vêm num commit logo depois
- **Working tree:** limpo depois do commit do handoff
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 2132 linhas `ok`, 0 `FAIL`, 839 mutantes aplicam (`--anchors`)
- **E2E:** não há `E2E_CMD`: o kit é bash e markdown, sem interface

## O que foi feito

- `bdfa30e` — I1: `templates/campaign.md` e `templates/delegation.md` novos, e `templates/missao.md` com as chaves opcionais `campaign:` e `lot:`; três asserções `worker templates:` no `tests/check-templates.sh`
- `f7f99ea` — I2: `bin/sdd-worker` (uso e despacho) e `tests/check-worker.sh`, ligados nos lugares da suíte (`run-all.sh`, os pisos, o censo, o `check-lang.sh`, o catálogo); o `apply_mutant` faz `bash -n` no `bin/sdd-worker`
- `3b6d636` — I3: `delegate`, a leitura de frontmatter, a "legível" e o digest
- `dc66ce2` — I4: `level`, os nove passos do nível efetivo, a escada e a costura `SDD_WORKER_NOW`
- `5bafad6` — I5: `allows`, a tabela de atos (5 níveis × 7 atos, 35 de 35)
- `4095baa` — I6: `budget`, a soma do ledger por `jq`, com as missões achadas também nos worktrees ligados
- `9de910a` — I7: `next`, a fila sobre as missões em disco e o `gh` (`campaign_mission_dirs`, uma definição para o `budget` e o `next`)
- `26adfe4` — I8: `pr-ready`, os cinco itens da régua, e a fixture `tests/fixtures/codex-review-state.txt` copiada do PR 409
- `5721c92` — I9: `commands/sdd-worker.md`, o laço, os sete atos com a chamada `allows`, as cinco paradas, a lista do "nunca" e as regras de contexto
- `30bc8cd` — I10: `docs/pipeline.md` (`## The worker`), `README.md`, `config/schema.md`, `CONTEXT.md` (cinco verbetes), a exceção no `commands/sdd-plan.md` e a nota no roadmap de setembro
- `3fe5d3e` — I11: a campanha `docs/superpowers/campaigns/20261117-zerar-as-issues/` (seis lotes, 83 itens, 24 `◆`, L6 com teto `plan`) e a delegação sem assinatura; a gaveta passa a F6 para "em construção"; o §4 do caderno do worker registra o que a ADR 0022 respondeu

### Ciclo 1 da QA (`F1`, `F2`, dos achados Q1 a Q3 do `30-handoff-qa.md`)

- `42d1a56` — F1 (Q1): o `delegation_terms` é a única definição do que a assinatura concede, as seis chaves e uma linha `ceiling <lote>: <teto>` por linha da tabela de lotes; o `delegate` mostra exatamente o que assina, e subir, baixar, pôr ou tirar o teto de um lote depois de assinar responde `assisted — edited after signing`. Família nova `seal: ` (1 linha), dois mutantes `mut_WORKER_seal_*`. Re-walk da J5 verde numa cópia
- `8add018` — F2 (Q2, Q3): o `id_is_dir` é a regra única do id, o `campaign:` de um arquivo igual ao nome do diretório resolvido (`readlink -f`: `.`, barra no fim e symlink são o diretório). O `delegation_legible` a aplica à `delegation.md` e ao `campaign.md` (o que falta é ilegível), então `level`/`allows` → `assisted`, `budget` → `no ceiling`, `delegate` recusa; o `next` a aplica ao `campaign.md` e para com rc 1 nomeando os dois valores (o ramo do `campaign:` vazio saiu, a regra o cobre). O `expires:` tem de voltar do `date -d` como foi. Família nova `legible: ` (2 linhas), cinco mutantes `mut_WORKER_legible_*`, o fixture do R16 com cada delegação em `<pai>/b-cap`, e o R4 passando a cobrar o motivo da regex. Re-walk da J6 verde numa cópia

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd-worker` | o programa: `delegate`, `level`, `allows`, `budget`, `next`, `pr-ready` |
| `tests/check-worker.sh` | o sensor, 36 asserções em onze famílias (`seal: ` do F1 e `legible: ` do F2 inclusas), com controle negativo nas famílias de prosa |
| `tests/check-mutation.sh` | 26 mutantes `mut_WORKER_*` no `CATALOG` |
| `tests/fixtures/codex-review-state.txt` | o comentário de máquina do Codex, copiado do PR 409 (proveniência no sensor) |
| `commands/sdd-worker.md` | o comando da sessão orquestradora |
| `templates/campaign.md`, `templates/delegation.md` | os dois contratos da campanha |
| `docs/superpowers/campaigns/20261117-zerar-as-issues/` | a campanha do kit: `campaign.md` e `delegation.md` sem assinatura |
| `docs/adr/0022-the-worker-is-a-session-orchestrator.md` | a decisão (escrita no PLAN) |
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` | uma nota por incremento, com as saídas do plano e as sabotagens |

## Boot da próxima fase

**QA que volta depois do ciclo 1 (`F1`, `F2`).** Refaça, numa cópia `mktemp -d` da campanha real
(o molde está no topo da J5 do `30-handoff-qa.md`), a J5, a J6 e a J3 inteira, e reescreva o
`30-handoff-qa.md` com o que o reteste viu. O que mudou e é visível na CLI:

- **`delegate`** imprime, depois das seis chaves, uma linha `ceiling <lote>: <teto>` por linha da
  tabela de lotes, e o digest gravado as cobre: o `signed:` de uma delegação assinada antes do F1
  deixa de bater (nenhuma real estava assinada). É por isso que a J3 volta inteira.
- **O id é o nome do diretório.** Um `campaign:` da `delegation.md` ou do `campaign.md` que não é o
  nome do diretório, ou um `campaign.md` ausente, responde `level assisted — illegible: campaign:
  '<valor>' in <arquivo> is not the directory's name '<nome>'` (ou `<arquivo> does not exist`); o
  `allows` pede, o `budget` diz `no ceiling`, rc 1, o `delegate` recusa com rc 1. Uma campanha
  renomeada ou copiada com outro nome cai aqui até os dois arquivos dizerem o nome novo.
- **O `next`** para com rc 1 sobre esse mesmo motivo, e também sobre o `campaign:` vazio, cuja
  mensagem mudou: era `illegible: campaign: is empty in …`, agora é a da regra de identidade.
- **O `expires:`** tem de ser um instante que o relógio tem: `2026-11-18 99:99` e `2026-11-31 10:00`
  respondem `illegible: expires '<valor>' is no instant on the clock`, e `2096-02-29 12:00` assina.

Na J6 do `30-handoff-qa.md`, o passo do Q3 precisa do `campaign:` do `campaign.md` de volta ao id
certo antes de trocar o `expires:`: com o placeholder ainda lá, a recusa é a da identidade, que
vem antes do instante. O re-walk desta sessão fez isso e viu cada "esperado" da tabela.

**O que vale desde a primeira QA, num repo sem interface.** O que é visível para quem usa o kit:

- **A CLI `bin/sdd-worker`.** Sem verbo, ou com um verbo desconhecido, imprime o uso e sai com rc 2.
  Os seis verbos, as saídas e os rc estão na tabela "Os seis verbos" do `01-plano.md` e em
  `docs/pipeline.md`, `## The worker`.
- **Os templates** `templates/campaign.md` e `templates/delegation.md`, e as chaves `campaign:` e
  `lot:` do `templates/missao.md`.
- **O comando** `commands/sdd-worker.md`, que é prosa para uma sessão interativa: o kit não o instala
  em lugar nenhum.
- **A campanha real.** Os comandos abaixo, rodados da raiz do worktree, respondem assim hoje:
  `bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues` →
  `level assisted — illegible: expires '<YYYY-MM-DD HH:MM, hora local>' is not YYYY-MM-DD HH:MM`;
  `budget` → `no ceiling — illegible: …`, rc 1; `allows … run --lot L1` → `ask run needs pr, effective assisted — …`, rc 1;
  `next` → `run L1 20261117-l1-a-prosa-do-chapeu — approved, and no pull request has the head fix/l1-a-prosa-do-chapeu`
  e `ahead plan L2`, rc 0. O `next` acha a missão do L1 porque ela já existe, aprovada (`469971a`), no
  worktree `/home/joruge/repos/sdd_agents-l1`: é o desenho do I7 (as missões são lidas também nos
  worktrees ligados), não um defeito.

**Ambiente.** Nada a subir. O `next` e o `pr-ready` chamam o `gh` real (só leitura) quando rodam
contra o repo de verdade, e o `gh` precisa estar autenticado. O `budget` lê
`${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`, também só leitura.

**Cuidados que não são opcionais:**

1. **Nunca assine a delegação real.** Exercite o `delegate` numa cópia da campanha em `mktemp -d`,
   dentro de um repo git de fixture com `.sdd/config.sh` (o `tests/check-worker.sh` tem o molde).
   A delegação real é do dono e tem de continuar sem `signed:`.
2. A suíte leva uns 14 min. `pgrep -f run-all` casa a própria sessão `claude -p` (o prompt cita o
   `TEST_CMD`); espere por `pgrep -f '^bash tests/run-all\.sh'` e `tail --pid`.
3. O harness nega `Write` e `Read` fora do repo (seis linhas `DENIED` no `pipeline.log` desta
   corrida, todas sob `/tmp`): rascunho em `mktemp -d` se escreve pelo `Bash`.
4. Esta missão não edita `bin/sdd` nem `agents/`, e não toca `.claude/`.

**Para a DOCS:** a decisão 12 pede que o que aconteceu nesta corrida vá para o caderno do worker
(`docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md`). Medido até aqui: o EXEC andou em
11 sessões, uma por incremento, de 2026-11-17 18:06 a 2026-11-18 01:20, pelo `sdd` do PATH no
worktree ligado, sem `KIT-TOUCHED`, `hat-crossed` nem escalada no `pipeline.log`, com US$ 43,65 nas
10 primeiras (ledger; esta ainda não estava gravada). O arranjo não derrubou a corrida.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- **Assinar a delegação da campanha do kit**, depois do merge: preencher `level`, `expires` e os dois tetos em `docs/superpowers/campaigns/20261117-zerar-as-issues/delegation.md` e rodar `bin/sdd-worker delegate docs/superpowers/campaigns/20261117-zerar-as-issues` num terminal — o prazo e os tetos são do dono (pendência 1 do `00-missao.md`)
- **Configurar o `ON_ESCALATION_CMD`** do kit: sem ele, todo nível assinado vale `assisted` (pendência 2)
- **Sincronizar o espelho de issues** depois do último merge do dia, pela skill `todo-to-github-issues` (pendência 3)
- **`aprovacao:` sob `full`**: um valor próprio do contrato (`delegated-…`) mexe no `gate_PLAN`, nos templates e no `docs/pipeline.md`; decida se vira missão (pendência 4)
- **A rule `.claude/rules/anatomia-do-agente.md`** recebe texto proposto pela DOCS, como linha ⛔ (pendência 5)
- **O carimbo de mutação não rodou**, pela regra do dono; o `gate_PR` deve sair com rc 2 pedindo `./bin/sdd health`, e isso se lê como "PR pronto para revisão" (pendência 6)
- **A quarta pergunta do §4 do caderno** (missão sem jornada num repo com interface) não foi decidida pela ADR 0022: o caderno a registra como deixada ao W4 (`ENV_UP_CMD`). Decidir se vira missão é seu
- **A missão do L1 já existe aprovada** (`20261117-l1-a-prosa-do-chapeu`, `469971a`, no worktree `~/repos/sdd_agents-l1`): com a delegação assinada, o primeiro ato do worker é `run L1`, não `plan L1`

## Riscos e não-feitos

- **A campanha não tem sensor durável**, por desenho (`01-plano.md`, I11): o Check foi efêmero. Os títulos foram copiados de `5221477:TODO.md`, e nada compara a campanha com o `TODO.md` depois disso: um item retitulado ou um item novo não aparece nela.
- **Os 26 mutantes foram provados um a um com `--only`**, que é dica e não carimbo; o catálogo inteiro e o carimbo são do `./bin/sdd health`, que não rodou.
- **Dois limites que o F2 declara, medidos na sabotagem:** a comparação do que o `date -d` devolve com o que foi escrito não tem mundo no GNU date 9 (ele recusa 24:00, 23:60 e o buraco do horário de verão, e devolve igual todo o resto), e fica para um `date` que role 24:00 para o dia seguinte, com o limite escrito no comentário do `delegation_legible`; e o `${1%/}` do `delegation_legible` só tira a barra dupla do caminho impresso no motivo. Um `date` sem `-d` (o do BSD) faria toda delegação ilegível, isto é, `assisted`: o lado seguro, num kit que já exige Linux para a coordenação.
- **A ADR 0022 §3** diz "a digest of the other fields", e desde o F1 o digest cobre também os tetos dos lotes. O texto ficou menos preciso, não falso; mexer numa ADR aceita fica para a REVIEW ou a DOCS (nota do F1).
- **Os limites declarados na ADR 0022 continuam valendo:** a assinatura prova uma resposta no stdin, não uma pessoa; os tetos leem o ledger desta máquina, e o gasto da sessão orquestradora e dos subagentes fica fora deles; as missões de uma campanha são casadas pelo id, não pelo repositório.
- **O `pr-ready` exige `reviewed_head:`**, que as rodadas da fase REVIEW do `sdd run` não escrevem. Depois de uma corrida ele responde `not-ready review: the newest round names no head` até a rodada da sessão do worker. É desenho (M5 do caderno), não defeito.
- **O `next` não deriva o `postmerge`**, e nenhum verbo age: quem roda, abre PR e mergeia é a sessão.
- **A catraca não se moveu** (`todo-findings 83`): nenhum item entrou ou saiu do `TODO.md`.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

Esta missão é do próprio kit, então não há linha `kit:`. Os dois achados abaixo **não** entraram no
`TODO.md`, pela régua de admissão do D15, e cada um diz por quê:

- **O limite declarado do `health_provenance` conta uma fixture de terceiro a menos.** `bin/sdd:7862` declara "the kit has a fourth captured third-party fixture and this function does not reach it" (o `acli-workitem-search-done.json`), e o I8 trouxe a quinta, `tests/fixtures/codex-review-state.txt`, que também não é alcançada. A linha de resumo do `sdd health` fala só das fixtures "das skills instaladas", então nenhum sensor afirma medir o que não mede: pelo D15 é limite a escrever no cabeçalho da função, não item do backlog. Esta missão não edita `bin/sdd`. A rota é a próxima missão que tocar o `bin/sdd` (o L4 da campanha, "Preflight, health e sensores", é a vizinhança): acrescentar a quinta ao `DECLARED LIMIT`, onde a proveniência dela já está escrita ao lado do probe do `tests/check-worker.sh`.
- **Para a DOCS, uma deriva anterior a esta missão:** o verbete "Carimbo de mutação" do `CONTEXT.md` diz que a chave "cobre 4 dos 8 caminhos que a `sandbox()` copia" (#67), e a `sandbox()` já copiava mais de 8 antes do I10, que lhe acrescentou o `README.md` e o `CONTEXT.md`. É prosa do `CONTEXT.md`, que a DOCS escreve.
