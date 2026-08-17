---
missao: 20260816-portas-do-humano
fase: EXEC
status: done
sessao: 2087440b-0590-485c-af8a-d88a1fed9b0a
data: 2026-08-16 23:58
gate: "`bash tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 48 caught, 0 known gap(s), of 48` (baseline da missão: 44) · 420 asserções `ok` no total. `shellcheck -S warning bin/sdd tests/*.sh` limpo (roda dentro do `run-all.sh`). `./bin/sdd health` verde nos 5 checks: suíte, `mutation: score: 48 caught, 0 known gap(s), of 48`, `all 8 gates have a mutation in the catalogue`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 6 known debt(s), none new`. `bash tests/check-todo.sh` → `62 finding(s), all within 8 lines and carrying anchor + date` + `selftest: 75 probe(s)`. Os 4 Checks do `checkpoint.md` rodados contra este HEAD: `sdd approve `→3, `branch `→3, `retry `→2, `kaizen-born`→3, todos batendo com o esperado. Os 4 commits `96a1f68`, `b3b8c2f`, `3ffa586` e `2510c3c` **verificados ancestrais de HEAD** por `git merge-base --is-ancestor`. Métrica do `00-missao.md`: os 4 itens correspondentes do `TODO.md` carregam RESOLVIDO com os 4 hashes acima (linhas 59, 68, 187 e 313), contados por grep → **4**."
---

# Handoff — EXEC — as quatro portas entre humano e runner ganham dono

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

> **Quatro passagens pelo EXEC**, uma por incremento, todas nesta branch. Este handoff cobre as
> quatro em resumo; **as lições caras estão linha a linha nas Notas de execução do
> `checkpoint.md`**, que é o documento a ler antes de tocar em qualquer coisa que esta missão
> mexeu. Não duplico aqui o que está lá.

## TL;DR

As quatro portas entre humano e runner ganharam instrumento: aprovar plano é `sdd approve`, o
campo `branch:` deixou de ser decorativo, `sdd retry` virou a quarta porta com aviso de branch
base, e plano nascido do `sdd kaizen` não se auto-aprova mais — agora por gate, não por prosa.
Suíte verde, mutação **44/44 → 48/48**, `sdd health` verde nos 5 checks, os 4 itens do `TODO.md`
carimbados por hash. A QA começa decidindo o que neste diff é visível ao usuário — é, em quatro
pontos listados no "Boot da próxima fase", e **não há interface para andar**.

## Estado do repo

- **Branch:** `missao/20260816-portas-do-humano` — nunca empurrada (`git push` é da fase PR)
- **Último commit:** `2510c3c` `feat(runner): plano nascido do kaizen nunca se auto-aprova`
  (mais os commits de `TODO.md`, checkpoint e deste handoff que fecham a sessão)
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **verde**, 420 asserções, mutação 48/48, 0 known gaps
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

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260816-portas-do-humano/checkpoint.md` | a tabela dos 4 incrementos com hash **e as Notas de execução — o documento de valor desta missão** |
| `docs/handoffs/20260816-portas-do-humano/01-plano.md` | o plano; os desvios estão registrados nas Notas (I1 idioma do commit, I2 escopo do `templates/`, I3 ordem das guardas) |
| `bin/sdd` | `cmd_approve`, `frontmatter_write`, `ensure_mission_branch`, o ramo kaizen-born do `gate_PLAN` |
| `tests/check-gates.sh` | 14 asserções novas (11 contadas pelos 4 Checks, 3 nascidas da sabotagem e nomeadas fora dos prefixos de propósito) |
| `tests/check-mutation.sh` | 4 mutações novas: `RUN_approve_writes_auto`, `RUN_branch_switch_dead`, `RETRY_base_branch_warn_dead`, `PLAN_kaizen_born_blind` |
| `templates/missao.md`, `agents/sdd-planner.md`, `.claude/agents/sdd-planner.md`, `docs/pipeline.md` | contrato de artefato atualizado nos mesmos commits (I2 e I4) |
| `TODO.md` | 62 achados; os 4 desta missão com `RESOLVIDO por <hash>`, 2 achados novos abertos |

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
- **Score de mutação é global.** Os 48 incluem os 4 desta missão; outra missão mexendo no catálogo
  move o número, e é por isso que nenhum Check de incremento o fixa — só a métrica final o cita.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (o kit é o alvo desta missão). Aqui fica só o ponteiro,
> para o PR conseguir citar.

- `frontmatter_write` sem guarda de read-back → `TODO.md` (aberto, achado no I1)
- ordem checkout-antes-do-aviso sem probe no `cmd_run` → `TODO.md` (aberto, achado no I3)
