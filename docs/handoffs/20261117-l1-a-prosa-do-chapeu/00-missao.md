---
missao: 20261117-l1-a-prosa-do-chapeu
titulo: Quatorze achados de prosa de chapéu e de docs do kit ganham conserto e uma asserção cada, no primeiro lote que o worker roda sozinho
data: 2026-11-17
versao:
branch: fix/l1-a-prosa-do-chapeu
aprovacao: humano-2026-11-17
adr: none
ddd: n/a
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L1
---

# Missão — L1: a prosa do chapéu e dos docs

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` do kit tem 83 achados abertos em `7ea43e3` (`tests/check-todo.sh` responde
`ok    83 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`), e a
campanha `20261117-zerar-as-issues` os reparte em seis lotes. Este é o **L1**: os 14 cujo conserto
é uma frase num chapéu (`agents/*.md`), num doc do operador, nas duas sementes do `TODO.md` ou no
texto de ajuda do `sdd why`. Todos nasceram em repo-alvo (`dotp-remake`, `magic_tutor`,
`sales_quote`, `lighthouse_project`) ou no merge de uma missão do kit, e nenhum tem sensor: o
catálogo de mutação sabota `bin/sdd` e não alcança prosa.

Os 14, com o título exato do item (é a chave do espelho de issues, **nunca** se muda) e a âncora
medida em `7ea43e3`:

| # | Título do item no `TODO.md` | Âncora | Incremento |
|---|---|---|---|
| A | O planner chama a base de `main`, e o alvo pode ter outra | `agents/sdd-planner.md:273` | I1 |
| B | A devolução do planner ao relay não tem regra de idioma | `agents/sdd-planner.md:285` | I1 |
| C | A Check de um item novo no `TODO_FILE` fixa o título e obriga a duplicar | `agents/sdd-planner.md:100` | I1 |
| D | O `sdd-executor` lançado como subagente fecha o último incremento e volta sem o `20-handoff-exec.md` | `agents/sdd-executor.md:214` | I2 |
| E | A sabotagem devolve o mutante com `mv`, e o build incremental mede o binário do mutante | `agents/sdd-executor.md:75` | I2 |
| F | O revisor tem de esperar o comando no mesmo turno, sem o `Monitor`, e o harness barra o `sleep` | `agents/sdd-reviewer.md:144` | I3 |
| G | A sonda do revisor fora do repo vai por `Write`, que o `acceptEdits` nega, e filtro sem teste sai rc 0 | `agents/sdd-reviewer.md:87` | I3 |
| H | A DOCS deixa a lição reincidente só no `KAIZEN_LOG.md` | `agents/sdd-docs.md:53` | I4 |
| I | O 3º caso do §0 do QA está só no caminho com interface, e o sem interface chega a ele igual | `agents/sdd-qa.md:41` | I5 |
| J | O README chama o repositório de privado, e ele é público | `README.md:45` | I6 |
| K | O vigia do `sdd run` destacado casa com a própria shell, e o kit não diz como esperar o fim | `docs/failure-modes.md:796` | I6 |
| L | A receita de merge dos PRs de achado não conta os threads de revisão abertos no head | `docs/finding-prs.md:45` | I6 |
| M | Uma medida no título de um item troca a chave do espelho a cada medição | `templates/todo.pt-BR.md:17` | I7 |
| N | A ajuda do `sdd why` não diz que a fase EXEC roda a suíte inteira | `bin/sdd:12361` | I8 |

O que cada um custou está no corpo do item (`grep -n -F '<título>' TODO.md`). Três exemplos, para
quem não vai abrir os 14: uma REVIEW do `dotp-remake` leu um `dotnet test --filter` que não achou
teste como verde (G); o `sdd why … EXEC` do `magic_tutor` foi cortado aos 2 min do Bash e pôde ser
lido como gate reprovado (N); o PR 391 do kit quase foi mergeado com um Major do CodeRabbit ainda
aberto no head (L).

Há um segundo fato, que não é defeito e pesa no plano: este lote é o **piloto do worker** (ADR
0022, decisão 8 de `20261117-o-worker-orquestrador`). Ele roda por `sdd run` num worktree ligado
do kit, lançado pela sessão orquestradora, depois do merge daquela missão e da assinatura da
delegação.

## Métrica

Binária, lida de comando, no head da branch `fix/l1-a-prosa-do-chapeu`:

1. As **15 asserções** novas saem verdes, cada uma com o prefixo `  ok    ` na stdout do seu
   sensor: 13 em `tests/check-hat.sh` e 2 em `tests/check-templates.sh`. É uma por item, e o item M
   tem uma por semente (as frases estão, uma a uma, no `01-plano.md`).
2. `tests/run-all.sh` verde.
3. Os 14 itens da tabela acima carregam `RESOLVED by <hash>`, com o hash do incremento que
   consertou cada um, e os títulos seguem byte a byte iguais.
4. Os cinco chapéus editados estão iguais ao espelho: `cmp -s agents/<chapéu>.md
   .claude/agents/<chapéu>.md` responde rc 0 para `sdd-planner`, `sdd-executor`, `sdd-reviewer`,
   `sdd-docs` e `sdd-qa`.

A catraca **não** desce nesta missão: `todo-findings` em `tests/health-baseline.txt` fica como a
base a trouxer. Quem apaga os 14 itens e desce o número é o chore de depois do merge
(`docs/finding-prs.md`, seção "The post-merge chore of a mission").

Há uma segunda medida, que não é critério de aceite: o que a corrida do piloto custou (dólares,
voltas, paradas) vai para a entrada do `KAIZEN_LOG.md` e para o diário da campanha.

## Resultado esperado

Os oito chapéus continuam dizendo o que diziam, e cinco deles ganham as frases que faltavam: o
planner nomeia a base pelo `DEFAULT_BRANCH` do alvo, devolve ao relay no idioma do alvo e escreve
Check de item novo que aceita uma `RECURRED`; o executor escreve o `20-handoff-exec.md` no mesmo
incremento que zera os `pending` e restaura o mutante com `cp`; o revisor sabe esperar um comando
sem `Monitor` e gravar uma sonda fora do repo; a DOCS dá destino à lição reincidente; a QA confirma
o `qa: skipped` nos dois caminhos. O operador lê no README que o repo é clonável, no
`failure-modes.md` como achar e esperar um `sdd run` destacado, e no `finding-prs.md` que o merge
espera zero threads abertos. As duas sementes do `TODO.md` dizem que número que muda não vai no
título, e o `sdd help` avisa que o `sdd why` roda a suíte. Cada frase tem uma asserção que fica
vermelha se ela sumir.

## Fora de escopo

- **Os outros 69 itens** do `TODO.md` (L2 a L6 da campanha) e os dois que o PR 412 acrescentou.
- **Apagar os 14 itens e descer a catraca.** É o chore de depois do merge, em PR próprio.
- **Sincronizar o espelho de issues.** Passo de depois do merge, pela skill `todo-to-github-issues`.
- **Qualquer mudança em `bin/sdd` além do texto de ajuda do `sdd why`** (decisão 1). Nenhum gate,
  nenhuma função, nenhum mutante novo.
- **O frontmatter dos chapéus** (`disallowedTools:`, `permissionsDeny:`, `writes:`, `mcp:`). O item
  F não devolve o `Monitor` ao revisor: dá a ele o laço em primeiro plano.
- **`.claude/rules/`.** Regra que mudar vira linha `⛔` com texto proposto na fase DOCS.
- **`./bin/sdd health`.** O carimbo de mutação não roda nesta missão (regra do dono: só com a
  catraca zerada).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 7 perguntas, 7 respostas marcadas nas Decisões, todas na recomendada; nenhuma aberta. Seis pendências, todas com dono, em "Pendências para o humano" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1 a K8 ✅ na seção abaixo; DDD `n/a` com a justificativa de uma linha |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Uma sessão nova (subagente sem contexto, somente leitura), só com os três arquivos e o repo, conferiu os fatos de I1, I2, I5, I6, I7 e I8 e o mapa do I9: 1 fato errado (a contagem de asserções, 13 + 2 e não 12 + 2), 1 contradição ("quatro" trocas de símbolo onde são três) e 1 lacuna (literais com apóstrofo), os três corrigidos no plano. Foi leitura com verificação, não execução; I3 e I4 ficaram fora da amostra, e o `./bin/sdd install --force` dentro de uma corrida nunca foi medido (está nos riscos) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 9 incrementos; `tests/check-checkpoint.sh --check` → `9 row(s), 8 under the anchor rule, none blind`, rc 0; `--red` → `9 pending Check(s), every one red at HEAD`, rc 0, em 2026-11-17 18:38, sobre `7ea43e3` |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` em `.sdd/config.sh` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: none`: frases em chapéus e docs e duas linhas de ajuda, nenhum trade-off arquitetural; `sdd adr check --mission 20261117-l1-a-prosa-do-chapeu --phase plan` → `adr: none — the mission declares no architectural decision`, rc 0 |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 14 itens lidos no `TODO.md`; cada trecho a editar aberto no arquivo; as duas asserções que já leem frases que este lote muda achadas em `tests/check-hat.sh` (`:343` e `:383`); a consulta de threads do item L rodada contra o PR 391; a skill `todo-to-github-issues` consultada sobre a chave do espelho |
| K2 | Problema declarado com métrica | ✅ | Quatro fatos binários na seção Métrica, cada um com comando |
| K3 | Desperdícios identificados e cortados | ✅ | Cortados: um mutante para a linha de ajuda (não é gate; a asserção lê a saída do `sdd help`); um incremento por item (seriam 6 suítes a mais); um incremento para trazer a base (merge por sessão headless); o `touch` depois do `mv` (dois comandos onde cabe um); data no README |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | Nove incrementos por arquivo, cada um com Check vermelho no HEAD (critério d). O que não tem remédio: são 9 voltas da suíte inteira pelo `gate_EXEC`, e não há fatia que entregue "metade de uma frase" |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída de um sensor ancorada em `^  ok    `, o `cmp` do espelho, ou a contagem de `RESOLVED by` no arquivo |
| K6 | Jidoka — o que para a linha está definido | ✅ | Suíte vermelha de incremento anterior = `blocked`; `./bin/sdd install --force` que responder outra coisa que não `updated`/`identical` = `blocked` com a saída nas notas; âncora do `TODO.md` fora do alvo = conserta no mesmo commit, nunca segue |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | O degrau mais alto que cabe em prosa de chapéu é a asserção por seção: 15 asserções na suíte. Poka-yoke de verdade (o runner recusar o `mv`, o gate ler os threads) é desenho de outros lotes, e está dito no Fora de escopo |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio (decisão 6): a fase DOCS deve a entrada, com o antes e o depois medidos e o custo da corrida do piloto |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio: o lote acrescenta frases a chapéus e docs e duas linhas a um texto de ajuda; nenhum conceito, contrato de artefato ou fronteira entre programas muda.`

## Decisões do grill (não re-litigar)

1. **O item N (ajuda do `sdd why`) fica no L1, como exceção nomeada à regra "sem tocar `bin/sdd`".**
   Um incremento próprio (I8), restrito ao texto de ajuda dentro de `cmd_help`, com asserção que lê
   a saída do `sdd help`. Porquê: mantém os 14 da fila aprovada na missão do worker sem reabrir o
   plano dela, e o piloto passa a medir também um diff em `bin/` num worktree.
   - answer: (recommended)
2. **Missão `20261117-l1-a-prosa-do-chapeu`, branch `fix/l1-a-prosa-do-chapeu`.** Porquê: o `l1`
   no id deixa a fila legível num `ls docs/handoffs`, e `fix/` segue o precedente das missões de
   conserto do kit.
   - answer: (recommended)
3. **O frontmatter declara já `campaign: 20261117-zerar-as-issues` e `lot: L1`, logo abaixo de
   `kaizen_log:`.** As duas chaves vêm da ADR 0022 e entram no `templates/missao.md` pelo I1 de
   `20261117-o-worker-orquestrador`; na base em que este plano foi escrito (`7ea43e3`) o template
   ainda não as tem, e nada no runner lê ou recusa chave desconhecida
   (`grep -n 'campaign' bin/sdd tests/check-templates.sh` vazio). Porquê: é o que os verbos `next` e
   `budget` do worker leem para achar a missão do lote, e o plano nasce visível sem edição depois
   de aprovado.
   - answer: (recommended)
4. **Nove incrementos, por arquivo, com uma asserção por item (o item M leva duas, uma por semente).** Planner (A, B, C), executor
   (D, E), revisor (F, G), DOCS (H), QA (I), docs do operador (J, K, L), sementes do `TODO.md` (M),
   ajuda do `sdd why` (N) e o fecho com os 14 `RESOLVED by`. Porquê: cada chapéu é editado e
   espelhado uma vez, o Red de cada fatia cabe numa frase, e são 9 suítes em vez de 15.
   - answer: (recommended)
5. **Os quatro itens com "ou" na direção seguem a leitura mais estreita, e saem listados no corpo
   do PR para o aceite do dono.** J: o comentário `# PRIVATE repository` sai, sem substituto. K: o
   doc dá o `pgrep -af '[b]in/sdd run'` para achar a corrida, a espera pelo PID e a linha
   `✓ pipeline complete` como fim. E: `cp <file>.bak <file> && rm <file>.bak`, nunca `touch` depois
   do `mv`. H: a DOCS escreve a linha `⛔` com texto proposto **ou** o motivo de a lição não virar
   regra. Porquê: nenhuma cria mecanismo novo.
   - answer: (recommended)
6. **`kaizen_log:` fica vazio: a fase DOCS deve a entrada no `KAIZEN_LOG.md`.** Porquê: há antes e
   depois medidos (14 itens sem sensor → 15 asserções), e a corrida é o piloto do worker sobre o
   kit, que a campanha vai querer comparar com o L2 em diante.
   - answer: (recommended)
7. **O plano é ancorado em símbolo e seção, nunca em número de linha, e trazer a base é ato de quem
   lança a corrida.** Cada incremento acha o trecho por `grep` de uma frase escrita no plano. Antes
   do `sdd run`, o worker (ou o dono) faz `git merge origin/main` na branch e confere as âncoras;
   está em "Pendências para o humano" e nos riscos. Porquê: a base anda antes da execução (a missão
   do worker e o PR 412 já a moveram ou vão mover), e um merge feito por sessão headless não deve
   resolver conflito de `TODO.md` sozinho.
   - answer: (recommended)

Consequências das sete, sem pergunta própria: `adr: none` (nenhum trade-off arquitetural), `ddd:
n/a`, `qa:` vazio (o kit não tem interface: o `sdd-qa` é a única sessão da fase e percorre a
jornada no terminal, descrita em "Verificação end-to-end" do plano), `aprovacao:` vazio (o dono não
pediu `auto`).

## Pendências para o humano

1. **Trazer a base antes do `sdd run`** (decisão 7). Este plano foi escrito sobre `7ea43e3`. A
   `main` já está em `380ffb0` (PR 412: dois achados novos, catraca 83 → 85, uma `RECURRED`) e vai
   receber a missão do worker. Quem lança a corrida, no worktree da missão:
   `git fetch origin && git merge origin/main`, depois `bash tests/check-todo.sh --anchors TODO.md`
   (`0 off target`) e `bash tests/check-hat.sh` (rc 0). Conflito fora de `TODO.md` e de
   `tests/health-baseline.txt` volta ao dono.
2. **O `sdd run` só depois do merge de `20261117-o-worker-orquestrador` e da assinatura da
   delegação.** Sem a campanha em disco, `campaign:` e `lot:` não apontam para nada.
3. **Aceitar as quatro escolhas da decisão 5**, que o corpo do PR lista.
4. **O chore de depois do merge:** apagar os 14 itens provados por
   `git merge-base --is-ancestor <hash> origin/main`, descer `todo-findings` e sincronizar o espelho
   de issues (`docs/finding-prs.md`; skill `todo-to-github-issues`). O PR desta missão mergeia por
   **merge commit**, nunca squash, ou os 14 hashes não chegam à `main`.
5. **O carimbo de mutação não roda.** Com o PR aberto e só o carimbo faltando, o `sdd run` sai com
   rc 2 e pede `./bin/sdd health`: lê-se como "PR pronto para revisão".
6. **`sdd preflight` pelo `sdd` do PATH, neste worktree, responde `agent … stale` depois do I1.**
   Ele compara o espelho do worktree com os chapéus do checkout principal, que ainda são os de
   antes. É esperado até o merge; neste worktree o preflight que vale é `./bin/sdd preflight`.
