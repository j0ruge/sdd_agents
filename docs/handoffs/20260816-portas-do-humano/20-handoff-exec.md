---
missao: 20260816-portas-do-humano
fase: EXEC
status: done
sessao: cf69f052-66d7-4fff-a51b-de1d783bdbd7
data: 2026-08-17 01:20
gate: "`bash tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 50 caught, 0 known gap(s), of 50` (baseline da missão: 44; I1–I4 levaram a 48, F1 a 49, F2 a 50) · 479 asserções `ok` no total. `shellcheck -S warning bin/sdd tests/*.sh` limpo (roda dentro do `run-all.sh`). `./bin/sdd health` verde nos **5** checks: `suite green`, `mutation: score: 50 caught, 0 known gap(s), of 50`, `all 8 gates have a mutation in the catalogue`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 6 known debt(s), none new` — é a segunda metade dos Checks do F1/F2, que ficou insatisfazível enquanto o F2 estava `pending` e agora foi medida de verdade. Os **6** Checks do `checkpoint.md` rodados contra este HEAD: `sdd approve `→3, `branch `→3, `retry `→2, `kaizen-born`→3, `approve resolves`→1, `approve warns`→1, todos batendo com o esperado. Os 6 commits `96a1f68`, `b3b8c2f`, `3ffa586`, `2510c3c`, `5c3d118` e `88ae514` **verificados ancestrais de HEAD** por `git merge-base --is-ancestor`. Métrica do `00-missao.md`: os 4 itens correspondentes do `TODO.md` carregam RESOLVIDO com os 4 hashes dos incrementos, contados por grep → **4**. O `HARNESS-BROKEN` do `check-mutation.sh`, que a QA registrou como desenhado, **liberou-se sozinho** ao fechar o F2 — o controle voltou a pontuar."
---

# Handoff — EXEC — as quatro portas entre humano e runner ganham dono

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

> **Seis passagens pelo EXEC**, uma por incremento: quatro do plano (I1–I4) e duas nascidas da QA
> (F1, F2), todas nesta branch. Este handoff cobre as seis em resumo; **as lições caras estão linha
> a linha nas Notas de execução do `checkpoint.md`**, que é o documento a ler antes de tocar em
> qualquer coisa que esta missão mexeu. Não duplico aqui o que está lá.

## TL;DR

As quatro portas do plano ganharam instrumento (`sdd approve`, campo `branch:` honrado, aviso no
`sdd retry`, gate kaizen-born) e as **duas costuras que a QA achou entre elas foram fechadas**: o
remédio que o gate nomeia agora funciona (F1) e a quinta porta que commita deixou de commitar em
silêncio (F2). Suíte **verde de novo** — mutação **44 → 50, 0 known gaps** —, `sdd health` verde
nos 5 checks, os 4 itens do `TODO.md` carimbados por hash. A QA volta a andar as jornadas de linha
de comando: **não há interface**, e o que mudou desde a rodada anterior são só F1 e F2.

## Estado do repo

- **Branch:** `missao/20260816-portas-do-humano` — nunca empurrada (`git push` é da fase PR)
- **Último commit:** `88ae514` `fix(runner): a quinta porta que commita deixa de ser silenciosa`
  (mais os commits de checkpoint e deste handoff que fecham a sessão)
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **verde**, 479 asserções, mutação 50/50, 0 known gaps
- **E2E:** `E2E_CMD=""` — o kit não tem interface; não rodou por não existir

## O que foi feito

- `96a1f68` — **I1 · `sdd approve <missão>`.** Fechar o `gate_PLAN` era abrir o `00-missao.md` e
  digitar `aprovacao: humano-YYYY-MM-DD` no formato exato que o gate grepa. Agora o comando
  imprime o que se está aprovando (título, tabela PLAN-AUTO, incrementos, pendências), pergunta
  `[y/N]`, escreve com `date +%F` e commita **só** o `00-missao.md`. Idempotente: aprovar duas
  vezes não empilha um segundo commit.
- `b3b8c2f` — **I2 · o runner honra o campo `branch:`.** `ensure_mission_branch()`, **uma**
  definição chamada por `cmd_run` e `cmd_retry`: existe ⇒ checkout, não existe ⇒ cria **da atual**
  (é onde vive o commit do plano), placeholder ou vazio ⇒ no-op silencioso, git recusa ⇒ `die` com
  a mensagem dele. Nunca em `--dry-run`. É a classe SQ-97 — 16 commits em branch alheia, ~US$ 45
  de `rebase --onto` — fechada por sensor.
- `3ffa586` — **I3 · `sdd retry` vira a quarta porta com aviso.** As outras três
  (`cmd_preflight`, `cmd_run`, `cmd_kaizen`) chamavam `warn_if_on_base_branch`; o retry não, e
  disparado da `main` refazia uma fase commitando na `main` em silêncio. A chamada entra **depois**
  do checkout, não antes — avisar antes é gritar lobo para um humano que o runner tira da base na
  linha seguinte.
- `2510c3c` — **I4 · plano kaizen-born nunca se auto-aprova.** `aprovacao: auto` carrega uma
  premissa — "o humano estava na sala" — falsa num plano que o kit escreveu sobre si mesmo. O
  `gate_PLAN` recusa `auto` quando há `05-verdict.md` ao lado e **nomeia o remédio**
  (`run 'sdd approve <missão>'`). Só `auto` é recusado: com aprovação humana a missão anda, ou o
  laço de melhoria do kit não teria estado terminal. Prosa sincronizada no mesmo commit
  (`agents/sdd-planner.md` §6 + cópia instalada byte-idêntica, `docs/pipeline.md` §PLAN-AUTO).

**Rodada de fixes da QA** — os dois achados nasceram nas **costuras entre** os incrementos acima,
onde nenhum sensor de incremento olhava porque cada um foi escrito na sessão do próprio fatia:

- `5c3d118` — **F1 · o remédio que o gate nomeia passa a funcionar.** `gate_PLAN` recusava o plano
  kaizen-born nomeando `sdd approve`, e o `cmd_approve` lia o mesmo `auto` como "already approved":
  os conjuntos eram **aninhados**, então o remédio impresso falhava sempre, nunca às vezes. A
  condição virou **uma** definição (`plan_approves_itself`, `bin/sdd:316`) lida pelos dois — o
  defeito ERA dois leitores discordando, e restatar a regra no segundo reabriria a porta.
- `88ae514` — **F2 · a quinta porta que commita deixa de ser silenciosa.** `cmd_approve` commita e
  não chamava `warn_if_on_base_branch`; o comentário da definição enumerava "the four doors" e o
  approve, escrito na MESMA missão, era a quinta. A chamada entra **no bloco do prompt** (as outras
  quatro chamam no topo): só esta imprime a missão inteira antes de perguntar, e aviso no topo teria
  rolado para fora da tela na hora da decisão. Aviso e nunca `die` — o plano vive legitimamente na
  base antes de a branch ser cortada. A asserção da QA ganhou três cláusulas, uma por sobrevivente
  da sabotagem: **ordem** (antes da pergunta, nunca depois da resposta), **contagem** (exatamente
  um) e uma **terceira invocação com checkpoint ilegível** (a branch é a única coisa de que a
  guarda pode depender). Mutação `APPROVE_base_branch_warn_dead`, 50 no catálogo.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260816-portas-do-humano/checkpoint.md` | a tabela dos 4 incrementos com hash **e as Notas de execução — o documento de valor desta missão** |
| `docs/handoffs/20260816-portas-do-humano/01-plano.md` | o plano; os desvios estão registrados nas Notas (I1 idioma do commit, I2 escopo do `templates/`, I3 ordem das guardas) |
| `bin/sdd` | `cmd_approve`, `frontmatter_write`, `ensure_mission_branch`, `plan_approves_itself`, o ramo kaizen-born do `gate_PLAN`, a quinta chamada de `warn_if_on_base_branch` |
| `tests/check-gates.sh` | 16 asserções novas (13 contadas pelos 6 Checks, 3 nascidas da sabotagem e nomeadas fora dos prefixos de propósito) |
| `tests/check-mutation.sh` | 6 mutações novas: `RUN_approve_writes_auto`, `RUN_branch_switch_dead`, `RETRY_base_branch_warn_dead`, `PLAN_kaizen_born_blind`, `RUN_approve_bails_on_kaizen_born`, `APPROVE_base_branch_warn_dead` |
| `templates/missao.md`, `agents/sdd-planner.md`, `.claude/agents/sdd-planner.md`, `docs/pipeline.md` | contrato de artefato atualizado nos mesmos commits (I2 e I4) |
| `TODO.md` | 64 achados abertos em `73229c1`; os 4 desta missão com `RESOLVIDO por <hash>`, 3 achados novos abertos (corrigido na REVIEW r1: os números eram 62/2 e nenhuma convenção do arquivo os produzia — a própria seção "Achados fora de escopo" deste handoff lista os 3) |

## Boot da próxima fase

Leia, nesta ordem: `00-missao.md` (a métrica), **as Notas de execução do `checkpoint.md`** (é onde
está o caro) e depois este arquivo. Ambiente: nada a subir — `bash tests/run-all.sh` na raiz é
tudo, sem rede e sem token (todo `claude` é stub nos fixtures).

**O diff é visível ao usuário em quatro pontos** — é isto que a QA precisa julgar, e **não há
interface para andar**, então a jornada é de linha de comando:

1. **`sdd approve <missão>` existe.** Num clone de teste com um plano de `aprovacao:` vazio: o
   comando imprime título/PLAN-AUTO/incrementos/pendências, `n` não muda nada, `y` grava
   `humano-<hoje>` e cria **um** commit `chore(missao): plan <missão> approved by the human`
   contendo só o `00-missao.md`. Rodar de novo é no-op.
2. **`sdd run` e `sdd retry` trocam de branch.** Com `branch:` preenchido, o runner faz checkout
   (ou cria a branch da atual) **antes** de abrir sessão, e anuncia `branch: <de> → <para>` na tela
   e no `pipeline.log`. Com `--dry-run`, **não** troca. Working tree suja que o git recuse ⇒ o run
   morre com a mensagem do git, sem seguir.
3. **`sdd retry` na branch base agora avisa** (stderr), como as outras três portas. Continua um
   `warn` e nunca um `die` — quem esquecer de criar a branch ainda consegue retry.
4. **Plano com `05-verdict.md` ao lado e `aprovacao: auto` não roda mais.** O `sdd run` para no
   PLAN dizendo `kaizen-born plan … run 'sdd approve <missão>'`. Afeta só o repo do kit, que é o
   único que roda `sdd kaizen` hoje.

**O que mudou desde a rodada anterior de QA são só F1 e F2** — as jornadas 1–4 já foram andadas e
estão no `gate:` do `30-handoff-qa.md`; o diff novo é `5c3d118` + `88ae514`. Duas coisas a re-andar:

5. **Obedecer o gate agora sai do laço.** Plano kaizen-born com `aprovacao: auto`: `sdd why` recusa
   nomeando `sdd approve`, e o comando **avisa** ("born of sdd kaizen…"), pergunta, grava
   `humano-<hoje>` e commita. O irmão `auto` **sem** verdict continua no-op e não é avisado — é o
   par que impede o conserto preguiçoso de apagar a procedência do PLAN-AUTO.
6. **`sdd approve` de pé na branch base avisa uma vez, antes da pergunta.** Fora da base, silêncio.
   Continua `warn` e nunca `die`: aprovar da base é o fluxo normal, é de lá que a branch é cortada.

⚠️ **Não "corrija" o assunto do commit do `sdd approve` para pt-BR.** É inglês por decisão
registrada nas Notas do I1: o runner é superfície do kit, roda em repo de qualquer `OUTPUT_LANG`,
e a frase pt-BR original é insatisfazível pelo `tests/check-lang.sh`.

## Pendências / Decisions for a Human

- Nenhuma. As quatro portas foram fechadas dentro do escopo aprovado; o que exigia decisão humana
  (o eixo do juiz / I13.4, que precisa de ADR) já estava **fora de escopo** no `00-missao.md` e
  segue no `TODO.md`.

## Riscos e não-feitos

- **`docs/pipeline.md` não tem seção para o `sdd approve` nem para o campo `branch:`.** A prosa
  nova do I4 cita o comando em texto e não em link porque a âncora não existe. Não é drift criado
  aqui — os dois nasceram nesta missão —, mas é **trabalho da fase DOCS**, anotado duas vezes nas
  Notas (I2 e I4).
- **`frontmatter_write` não tem guarda de read-back.** A 11ª degradação da sabotagem do I1
  sobreviveu verde: remover a releitura do valor após escrever não quebra asserção nenhuma. Está
  no `TODO.md` como achado aberto, não como conserto desta missão.
- **A ordem checkout-antes-do-aviso é regra sem probe no `cmd_run`.** O `cmd_retry` ganhou a
  asserção no I3; o `cmd_run`, que tem a mesma ordem pelo mesmo motivo, não. Vizinho, fora do
  escopo, no `TODO.md`.
- **O marcador kaizen-born é a presença do arquivo, não seu conteúdo.** Um `05-verdict.md` de zero
  byte contaria como verdict. Nenhum caminho do runner cria um, então não virou probe — mas é a
  suposição sobre a qual o ramo novo se apoia.
- **Score de mutação é global.** Os 50 incluem os 6 desta missão; outra missão mexendo no catálogo
  move o número, e é por isso que nenhum Check de incremento o fixa — só a métrica final o cita.
  ⚠️ A métrica do `00-missao.md` diz **44 → 48**: está desatualizada por dois, e os dois são F1 e
  F2, que não existiam quando o plano foi escrito. O número real é **50**.
- **Duas colocações alternativas do aviso do F2 sobrevivem à sabotagem de propósito** (topo do
  `cmd_approve`, ou uma linha acima das `dim`): continuam antes da pergunta, uma vez só, silenciosas
  fora da base. São **controle**, não buraco — asserção que as matasse estaria medindo estilo.
- **`sdd health` morre mudo com a suíte vermelha** (achado do F1, pré-existente, no `TODO.md`):
  `out="$( … run-all.sh )"` sob `set -e` mata o script antes do `health_bad "suite red"`. Com a
  suíte verde ele funciona — foi assim que o Check do F2 pôde ser medido.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (o kit é o alvo desta missão). Aqui fica só o ponteiro,
> para o PR conseguir citar.

- `frontmatter_write` sem guarda de read-back → `TODO.md` (aberto, achado no I1)
- ordem checkout-antes-do-aviso sem probe no `cmd_run` → `TODO.md` (aberto, achado no I3)
- `sdd health` morre mudo com a suíte vermelha → `TODO.md` (aberto, achado no F1, commit `829f889`)
- **A sessão do F2 não achou nada novo fora de escopo.** As 26 degradações da sabotagem ou morreram
  ou eram controle; o `TODO.md` não foi tocado.
