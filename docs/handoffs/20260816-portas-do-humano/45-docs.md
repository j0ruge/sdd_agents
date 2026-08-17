---
missao: 20260816-portas-do-humano
fase: DOCS
status: done
sessao: bd359d9c-c7a4-4a9c-98ca-94a2fd40097a
data: 2026-08-17 02:25
gate: "Checklist de drift abaixo com **27 linhas**, uma por área do diff: 20 `✅` com hash e 7 `n/a` com justificativa medida. Nenhum `✗`. Medido no HEAD desta fase: `bash tests/run-all.sh` → rc `0`, `suite green`, `score: 55 caught, 0 known gap(s), of 55`, **490** asserções `ok` (2:28,96) — o mesmo score de mais duas passadas num worktree limpo (2:27,10 e 2:27,59). `./bin/sdd health` → `kit healthy` nos cinco checks, incluindo `all 8 gates have a mutation in the catalogue` e `ratchet: 6 known debt(s), none new`. Os quatro sensores que leem markdown rodados um a um: `check-lang.sh` (0 de 35 caminhos de superfície na allowlist), `check-todo.sh` (72 achados, todos com âncora e dentro de 8 linhas), `check-checkpoint.sh` e `check-templates.sh`, rc 0 nos quatro. As 7 cópias de `.claude/agents/` byte-idênticas por `cmp -s`. Os 8 commits de documentação desta fase (`3157023`, `7f87c71`, `66b5dd5`, `b233a83`, `614aaaa`, `30e6f6c`, `e9ee8bf`, `9b9175d`) verificados ancestrais do HEAD por `git merge-base --is-ancestor`; árvore limpa. `./bin/sdd why 20260816-portas-do-humano DOCS` → `drift checklist complete`."
---

# Documentação — 20260816-portas-do-humano

> A missão nasceu um comando (`sdd approve`), transformou um campo decorativo do frontmatter em
> carga executável (`branch:`), fechou o silêncio de duas portas que commitam e pôs uma restrição
> de origem no enum de `aprovacao:`. Três dos quatro contratos **já aprenderam durante o EXEC e a
> REVIEW** — a regra do `CLAUDE.md` manda consertar contrato nos três lugares no mesmo commit, e
> ela foi obedecida. Esta fase fecha o que sobrou: a casa própria do campo `branch:` e o modo de
> falha que ele criou, os termos novos no glossário, as âncoras podres do `TODO.md`, e o kaizen
> com o antes/depois medido — inclusive a correção da métrica que o próprio `00-missao.md` errou.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `cmd_approve()` + `usage()` (I1): o gate humano ganha comando | `README.md` § Usage | ✅ | linha do comando em `1280bf7`; parágrafo de superfície (o que imprime, o `[y/N]`, o commit de 1 arquivo, a rota para o porquê) em `3157023` |
| idem | `docs/pipeline.md` § PLAN | ✅ | "that explicit approval is a command, not a hand edit", `2510c3c` |
| `bin/sdd` — `frontmatter_write()` (helper novo do I1) | — | n/a | helper interno sem superfície observável: o que o humano vê é o `sdd approve`, documentado na linha acima. As três suposições que ele carrega (`chmod --reference`, `mv` sobre symlink, escape de `awk -v`) estão no `TODO.md` com direção medida, e nenhum chamador de hoje as alcança |
| `bin/sdd` — `ensure_mission_branch()` (I2): o campo `branch:` vira carga | `docs/pipeline.md` § "The mission's branch" (novo) | ✅ | `3157023` — seção própria com a tabela dos quatro valores, o `die` com a mensagem do git e as duas coisas que ela deliberadamente não faz; o marcador do `--dry-run` (`1280bf7`) encurtou para rotear até ela |
| idem | `README.md` | ✅ | parágrafo "put you on the branch the plan declares", com link para a seção, `3157023` |
| idem | `templates/missao.md` | ✅ | descrição do campo reescrita no mesmo commit do incremento, `b3b8c2f` |
| idem | `agents/sdd-planner.md` § 8 + cópia em `.claude/agents/` | ✅ | §8 "Branch" com os três valores e os três comportamentos, byte-idêntica por `cmp -s`, `ece1b33` |
| `bin/sdd` — `die` do checkout recusado (I2, decisão 4 do grill) | `docs/failure-modes.md` § "The runner refused to switch to the declared branch" (novo) | ✅ | `3157023` — era a única parada nova sem remédio óbvio; as outras duas (gate recusando `auto`, e o `sdd approve` que ele nomeia) carregam o próprio remédio na mensagem |
| `bin/sdd` — `warn_if_on_base_branch` no `cmd_retry` (I3) e no `cmd_approve` (F2) | `CONTEXT.md` — verbete "Portas que commitam" (novo) | ✅ | `7f87c71` — a enumeração das cinco portas e o critério que impede a sexta de nascer sem a guarda ("o que aterrissa no histórico", não "abre sessão") |
| `bin/sdd` — `plan_approves_itself()` + ramo kaizen-born do `gate_PLAN` (I4, F1) | `docs/pipeline.md` § PLAN | ✅ | "`auto` is refused outright on a kaizen-born plan", `2510c3c` |
| idem | `agents/sdd-planner.md` § 6 + cópia em `.claude/agents/` | ✅ | a exceção ao PLAN-AUTO ("one exception, and the runner enforces it"), `2510c3c` |
| idem | `CONTEXT.md` — verbete "Plano kaizen-born" (novo) | ✅ | `7f87c71` |
| idem | `agents/sdd-kaizen.md` § 6 | n/a | o texto já dizia `aprovacao:` **"EMPTY, always. Never `auto`"** e segue verdadeiro: mudou **quem impõe** a regra (agora também o `gate_PLAN`), não o que se exige do agente. Reescrever seria reafirmar o que já está escrito |
| idem | `docs/adr/0002-kaizen-plans-headless-...md` | n/a | a decisão registrada ("o plano nasce com `aprovacao:` vazio, sempre, até o I13.4") **não mudou nem foi revertida** — ganhou um segundo ponto de imposição. Pela regra do `CLAUDE.md`, ADR aceito e ainda válido não se reescreve; o ponto novo está no `docs/pipeline.md`, que já o amarra ao `gate_KAIZEN` por escrito |
| classe SQ-97 (termo que o diff pôs na superfície do kit) | `CONTEXT.md` — verbete "Classe SQ-97" (novo) | ✅ | `7f87c71` — era folclore de handoff e agora é prosa carregada em `docs/pipeline.md`, `docs/failure-modes.md` e `agents/sdd-planner.md` §8; o verbete carrega a ressalva do `JIRA_ENABLED=true` |
| `tests/check-mutation.sh` — catálogo 44 → 55 | `CLAUDE.md` § "TDD aqui dentro" | ✅ | `66b5dd5` — a citação `44 caught of 44` virou `N caught of N`: a propriedade nunca dependeu do número, e fixá-lo era uma data de validade escrita à mão |
| idem | `KAIZEN_LOG.md` | ✅ | `614aaaa` — 44 → 55 com os onze mutantes novos atribuídos um a um ao commit que os trouxe |
| `tests/check-gates.sh` (+1072 linhas de asserção) | `CLAUDE.md` — lista de sensores da suíte | n/a | nenhum sensor **novo**: `ls tests/check-*.sh` devolve doze no HEAD e doze na `main`. Asserção dentro de sensor existente não muda a lista que o `CLAUDE.md` enumera. ⚠️ A rubrica vizinha do auto-teste diz "cinco" e `grep -l selftest tests/*.sh` devolve **seis** nos dois lados — drift **anterior** a esta missão (`52414e4`, o `jobs_selftest()` do escalonador), medido aqui e mandado para o `TODO.md` em vez de virar diff |
| passada de sabotagem: probes vazios em F1 e F2 (26 + 17 degradações) | `CLAUDE.md` § "TDD aqui dentro" | ✅ | `66b5dd5` — regra nova: o probe prova primeiro que sabotou o que dizia sabotar (âncora em código; `perl -0pe 's/…//m'` sem `/g` casa a primeira ocorrência do **arquivo**). Quatro conclusões falsas quase viraram asserção |
| métrica do `00-missao.md`: mutação "44 → 48" | `KAIZEN_LOG.md` | ✅ | `614aaaa` — corrigida para o real 44 → 55, com a tabela de origem dos sete extras. O `00-missao.md` **não** foi reescrito: é o artefato da intenção, e apagar a previsão apagaria a lição de que métrica de catálogo é previsão, não meta |
| métrica do `00-missao.md`: "a classe SQ-97 morre" | `KAIZEN_LOG.md` § "O que ficou sabido" + `CONTEXT.md` | ✅ | `614aaaa` / `7f87c71` — a ressalva cobrada pela REVIEW (morre **no caminho sem JIRA**) fica registrada em três lugares; o item vivo do TICKET segue no `TODO.md` |
| pergunta aberta da D7 ("suíte < 30 s") — o catálogo cresceu de novo | `CONTEXT.md` § 🚩 Perguntas abertas | ✅ | `614aaaa`, corrigido em `9b9175d` — terceira medição consecutiva, **1:45,74 → 2:27,10** (+39%), alvo 4,9× distante. A decisão continua do humano; a linha só deixa de estar desatualizada |
| a própria medição de tempo desta fase | `KAIZEN_LOG.md` § ⚠️ + `CONTEXT.md` | ✅ | `9b9175d` — os primeiros tempos foram medidos com outra suíte na mesma máquina e discordavam de si mesmos (o mesmo HEAD deu 2:25,87 **depois** de 4:18,70). Refeitos em sequência, quatro passadas, cada lado dentro de 2 s de si mesmo e a `main` batendo no número que a missão anterior registrou para o mesmo commit. O erro ficou escrito em vez de sumir |
| `TODO.md` — 12 entradas desta missão | `TODO.md` | ✅ | `b233a83` — oito âncoras reancoradas contra o HEAD (o diff da própria missão as deslocou); `30e6f6c` — a 12ª, achada por esta fase. Forma conferida por `tests/check-todo.sh`. Detalhe na seção abaixo |
| `docs/handoffs/20260816-portas-do-humano/*` | — | n/a | são o registro da missão, não documentação viva do repo: escritos pelas fases que os produziram e imutáveis a partir daí |
| `config/schema.md` | — | n/a | nenhuma chave de `.sdd/config.sh` entrou, saiu ou mudou de significado — a missão é comando de CLI, função de guarda e ramo de gate |
| `CHANGELOG.md` | — | n/a | o repo não tem changelog e não versiona releases (`JIRA_ENABLED=false`, sem tag). O que muda para quem usa vive no `README.md` (superfície) e no `KAIZEN_LOG.md` (antes/depois medido), os dois atualizados acima |

Nenhum `✗` nesta tabela — as sete linhas `n/a` carregam a razão medida, não a fórmula.

## As entradas do `TODO.md` desta missão

Onze entradas foram criadas ou fechadas pelas fases anteriores, e esta fase acrescentou a décima
segunda. Todas as onze já tinham **o quê + `arquivo:linha` + por que importa + direção + quem
descobriu (agente/missão/data)**, e nenhuma passava do teto de 8 linhas — a forma estava certa. O
que estava **errado era o conteúdo da âncora**: oito citavam
`arquivo:linha` que a própria missão deslocou depois, porque a rodada de REVIEW (`ad0c89d`) e o
resgate da árvore suja (`7f9e660`) mexeram no `bin/sdd` acima delas.

Âncora podre é pior que achado meio escrito: manda a próxima sessão para uma linha que hoje diz
outra coisa, e o item passa a custar leitura em vez de poupá-la. Conferidas uma a uma contra o HEAD
e reancoradas em `b233a83`:

| Entrada | Antes | Depois |
|---|---|---|
| `sdd approve` diz "next: sdd run" com o gate fechado por outro motivo | `bin/sdd:1946` | `bin/sdd:1950` |
| o `die` de artefato faltando do `sdd approve` | `bin/sdd:1818` | `bin/sdd:1842` |
| a guarda de read-back do `sdd approve` (fechada) | `bin/sdd:1766` | `bin/sdd:1933` |
| a ordem checkout-antes-do-aviso no `cmd_run` (fechada) | `bin/sdd:1865-1869` | `bin/sdd:1986-1990` |
| `sdd health` morre mudo com a suíte vermelha | `bin/sdd:1537` | `bin/sdd:1588` |
| as três suposições do `frontmatter_write` | `bin/sdd:191-215` | `bin/sdd:188-218` (limites reais da função) |
| o call site do `ensure_mission_branch` sem entrada no catálogo | `tests/check-mutation.sh:635` | `tests/check-mutation.sh:660` |
| o fixture do approve mede o `sed`, não o escopo (fechada) | `tests/check-gates.sh:708` | `tests/check-gates.sh:716` |

Quatro âncoras foram conferidas e **ficaram como estavam**, porque já apontavam para o código certo:
`bin/sdd:426` (o `gate_EXEC` rodando o `TEST_CMD` sobre o working tree), `bin/sdd:1363`
(`ensure_mission_branch` lendo só o `00-missao.md`), `bin/sdd:1405` (a releitura pós-checkout) e
`agents/sdd-publisher.md:98` (o `branch:` do `10-ticket.md`).

A décima segunda entrada é desta fase (`30e6f6c`): conferir se o diff mexeu na lista de sensores do
`CLAUDE.md` mostrou que **não mexeu** (doze na `main`, doze no HEAD), mas que a rubrica vizinha
declara `grep -l selftest tests/` devolvendo cinco enquanto ele devolve **seis** nos dois lados — o
sexto é o `jobs_selftest()` do escalonador, de `52414e4`, anterior a esta missão. Achado fora do
escopo vai para o arquivo, nunca para o diff; entrou com âncora, direção e data como os outros.

Os **quatro itens da métrica** da missão carregam `RESOLVIDO por <hash>`, e os quatro hashes foram
provados ancestrais do HEAD por `git merge-base --is-ancestor`: `96a1f68` (approve),
`b3b8c2f` (branch declarada), `3ffa586` (quarta porta), `2510c3c` (kaizen-born). Mais três fechados
pela REVIEW com `ad0c89d`. **Nenhum foi apagado**: pela regra do ciclo de vida do arquivo, o item
fechado só sai depois que o PR que cita a evidência for mergeado.

## O que esta fase deliberadamente não fez

- **Não reescreveu o `00-missao.md`.** A métrica dele diz 44 → 48 e o real foi 44 → 55; a REVIEW
  pediu a correção "para o número real". Ela foi feita no `KAIZEN_LOG.md`, que é onde o resultado
  medido mora. O `00-missao.md` é o artefato da **intenção**, escrito antes: corrigi-lo apagaria a
  única evidência de que a previsão errou, que é justamente a lição registrada.
- **Não abriu ADR.** A restrição de origem do `aprovacao:` impõe uma decisão que o ADR 0002 já
  registrou e que segue valendo. A decisão que **precisa** de ADR — o I13.4, `KAIZEN_AUTO_APPROVE`
  e o eixo do juiz — está fora de escopo por escrito no `00-missao.md` e viva no `TODO.md`.
- **Não refatorou documento alheio.** O `docs/pipeline.md` passou de 435 para 468 linhas e é o
  maior doc do kit; a seção nova entrou com profundidade num lugar só e o marcador do dry-run
  encolheu para rotear até ela, mas nenhuma seção pré-existente foi partida no meio desta missão.
- **Não inventou convenção.** As duas linhas novas do `CLAUDE.md` são uma correção de número que
  envelheceu e uma regra que custou 43 degradações de sabotagem em duas fases desta missão. Nada
  entrou por "achei que devia ser assim".
