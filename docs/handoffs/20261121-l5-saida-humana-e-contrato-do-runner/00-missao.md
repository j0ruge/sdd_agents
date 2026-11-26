---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
titulo: O runner diz ao humano o passo seguinte que vale, o sdd close lista o que o merge fechou, e o sdd adr new, o link-agents e o install deixam de depender de alguém lembrar
data: 2026-11-21
versao:
branch: fix/l5-saida-humana-e-contrato-do-runner
aprovacao: humano-2026-11-21
adr: docs/adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md
ddd: n/a
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L5
---

# Missão — L5: saída humana e contrato do runner

> Escrito pelo `sdd-planner`, com o grill respondido por delegação escrita do dono (veja "Decisões
> do grill"). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão
> headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` do kit tem 91 achados abertos em `86e16c0` (`bash tests/check-todo.sh --count TODO.md`
→ `91`), e a campanha `20261117-zerar-as-issues` os reparte em lotes. Este é o **L5**: os 17 que
tratam do que o runner **diz ao humano** (a ajuda, o fim da corrida, o `sdd status`, o `sdd close`,
os avisos) e de quatro contratos que hoje dependem de alguém lembrar (o número do ADR, o link do
`/sdd-plan`, o idioma da semente do `TODO.md`, a prova de que um `RESOLVED by` já pode sair). Seis
levam `◆` na campanha: deixavam uma escolha em aberto, e ela foi feita no grill (decisões 2 a 7).

Os 17, na ordem da campanha. A linha é a do `TODO.md` em `86e16c0`
(`grep -nF -- '**<título>' TODO.md`); as âncoras estão todas no alvo
(`bash tests/check-todo.sh --anchors TODO.md` → `ok    anchors: 91 measured, 0 off target`).

| # | Item (título no `TODO.md`) | Linha | ◆ | `RECURRED` | Incremento |
|---|---|---|---|---|---|
| 1 | O ciclo de vida do `RESOLVED by` não sobrevive a squash merge | 229 | ◆ | | I10 |
| 2 | A prosa congelada diz a regra 2 e o teto de largura mais estritos que os sensores | 236 | | | I16 |
| 3 | O remédio do `sdd kaizen` recusado ensina a mesma receita sem `--no-track` | 274 | | | I6 |
| 4 | A primeira instalação semeia o `TODO.md` em inglês, qualquer que seja o idioma | 281 | ◆ | | I15 |
| 5 | Nada instala nem confere o `/sdd-plan` que o `link-agents` manda rodar | 288 | ◆ | 1 | I2 |
| 6 | Num subcomando, `-l` escolhe a missão que tem `-l` no nome, e `--help` vira "mission not found" | 304 | | | I5 |
| 7 | A citação "ADR 0018" do kit colide com o ADR 0018 do alvo | 378 | | | I17 |
| 8 | O `PR #N aberto` que a fase PR escreve no roadmap e no `KAIZEN_LOG.md` envelhece no merge | 386 | | | I12 |
| 9 | O `sdd status --no-gates` roda o `git status` sem `GIT_OPTIONAL_LOCKS=0` sobre a run em voo | 394 | | 1 | I4 |
| 10 | O `sdd status` manda `sdd run` com o app fora do ar, e a fase fechada volta a pendente | 493 | | | I8 |
| 11 | O fim da corrida diz que só falta o merge, e o `sdd close` some | 501 | | | I9 |
| 12 | O pós-merge não lista o `RESOLVED by` que já pode sair | 508 | ◆ | | I11 |
| 13 | O `sdd run` diz que commita na base quando a TICKET vai cortar o branch antes | 525 | | | I13 |
| 14 | A ajuda do `sdd run` não diz como soltá-lo da sessão que o dispara | 549 | ◆ | 1 | I3 |
| 15 | O lembrete do `sdd kaizen` não vê o backlog nem diz o custo | 558 | | | I14 |
| 16 | O `CHECKOUT-BUSY` do `sdd status` não aponta o `--no-gates`, que lê o disco com a run em voo | 567 | | | I7 |
| 17 | O `sdd adr new` dá a uma branch o número que outra branch sem merge já usa | 634 | ◆ | 2 | I1 |

O que o gemba mediu além do que os itens já dizem (o comando de cada fato está no `01-plano.md`):

- **Metade do item 6 já está consertada.** `sdd close --help` imprime a ajuda desde o PR #391
  (o `main` lê `-h`/`--help` antes do despacho). Sobra o casamento por substring: num repo de
  rascunho com as pastas `20261020-lote-de-consertos` e `20261020-narracao`, `sdd why -l` casou a
  primeira e `sdd phase -n` a segunda; `sdd run -l` e `sdd status -l` já recusam.
- **A semente em inglês se reproduz** (item 4): `sdd install` num repo novo gera `OUTPUT_LANG=""` e
  um `TODO.md` em inglês; com a chave trocada para `pt-BR`, o segundo `sdd install` responde
  `TODO.md already exists (preserved)`.
- **A reescrita do índice se reproduz** (item 9), no git 2.43.0: depois de um `touch` num arquivo do
  índice, `git status --porcelain` troca o inode do `.git/index`; com `GIT_OPTIONAL_LOCKS=0`, não.
- **O branch do juiz nasce rastreando a base** (item 3): `git worktree add ../x -b kaizen/a
  origin/main` deixa `kaizen/a@{u}` igual a `origin/main`; com `--no-track`, sem upstream.
- **Ler o `docs/adr/` de todo ref é barato** (item 17): 0,44 s sobre os 158 refs deste clone.
- **O `gh` acha o PR pelo hash** (itens 1 e 12): `gh pr list --search 3000409 --state merged`
  respondeu `458 86e16c0`.
- **O `sdd close` serve também sem JIRA** (item 11): os dois braços do `cmd_close` terminam no
  `close_return_home`, que volta à base e faz o fast-forward. Com o I11 e o I12 ele passa a listar o
  que o merge fechou. Por isso o fim da corrida nomeia o `sdd close` nos dois braços.

## Métrica

1. Os 17 itens ganham `RESOLVED by <hash>` no `TODO.md` (Check I18 → `17`).
2. As 46 frases de asserção dos incrementos I1 a I17 imprimem `  ok    ` no seu sensor (os Checks
   do `checkpoint.md`, todos com o valor esperado), e a suíte fica verde (`tests/run-all.sh`, rc 0).
3. Os 28 mutantes novos entram no catálogo, cada um pego pelo seu sensor
   (`bash tests/check-mutation.sh --only <slug> tests/<sensor>.sh` → rc 0), e
   `bash tests/check-mutation.sh --anchors` → rc 0.
4. Custo e tempo da missão, para a tabela da campanha no `KAIZEN_LOG.md` (decisão 9): sessões de
   EXEC, segundos, dólares, por sessão e por item, ao lado dos L1 a L4.

## Resultado esperado

Quem roda o kit lê o passo seguinte que vale: a ajuda mostra como soltar o `sdd run` da sessão; o
`CHECKOUT-BUSY` aponta o `--no-gates`; o `sdd status` com o app fora do ar manda subir o app, e não
`sdd run`; o fim da corrida nomeia o `sdd close`, e o `sdd close` lista os `RESOLVED by` que já
podem sair e as linhas que ainda dão o PR como aberto. O `sdd adr new` não repete o número de uma
branch sem merge; o `sdd-link-agents` liga o `/sdd-plan` que ele manda rodar; o `sdd install` troca
a semente intocada de outro idioma; o ciclo de vida do `RESOLVED by` fecha também em repo que faz
squash. Nenhum token, chave de config ou gramática do `TODO.md` muda.

## Fora de escopo

- O catálogo de mutação inteiro (`./bin/sdd health`) e o carimbo: o PR de missão do kit mergeia sem
  carimbo, por regra do dono.
- `tests/health-baseline.txt`: a catraca desce no chore de depois do merge, que apaga os 17 itens.
- `CLAUDE.md` e `.claude/rules/anatomia-do-agente.md`: a sessão headless não os edita; a DOCS
  propõe o texto em linhas `⛔` (pendência 4).
- Um `sdd run --detach` (decisão 4) e um `--after <n>` no `sdd adr new` (decisão 2): descartados.
- Apagar os itens resolvidos pelo `sdd close` (decisão 6): ele só lista.
- A skill `todo-to-github-issues`, que é de outro repositório: a segunda prova do `RESOLVED by` fica
  para um retrofit à parte (pendência 3).
- A outra metade do item 10: o `sdd run` com o app fora do ar ainda compra uma sessão `QA:close`
  antes de escalar `app-down`, e cada leitura do `gate_QA` roda a e2e. É o desenho de hoje,
  coberto por asserção (`tests/check-autonomy.sh`, "a dead app escalates on the first session");
  mudar isso é uma porta nova antes da sessão, com desenho próprio (pendência 5).
- As citações de ADR dentro do `boot_prompt` do `bin/sdd` e no `agents/sdd-kaizen.md`, que só roda
  no kit: o item 7 fala dos templates, dos chapéus de alvo e dos comandos.
- A semente de uma revisão **antiga** do template em outro idioma: o I15 reconhece as sementes de
  hoje; a de ontem é o mecanismo do I5 do L4 (o preâmbulo contra as revisões do template).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | As nove perguntas do grill têm resposta (dez linhas `- answer:`, a decisão 5 perguntada duas vezes); nenhuma 🚩; o que pede o dono está nas pendências 2 a 6, cada uma com dono |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | As duas seções abaixo: K1 a K8 ✅, DDD `n/a` com a justificativa |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Seção "Teste de autocontenção" do `01-plano.md`: lido incremento a incremento, com cada "só se souber X" escrito no plano |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 18 linhas; `tests/check-checkpoint.sh --check` → `18 row(s), 17 under the anchor rule, none blind`; `--red` → rc 0, `18 pending Check(s), every one red at HEAD` (seção "O vermelho medido" do plano) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` do worktree; `versao:` fica vazio |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md`, alocado por `./bin/sdd adr new` e escrito pelo planner (decisão 8); `./bin/sdd adr check --mission … --phase plan` → rc 0 |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 17 sítios lidos em `86e16c0`; cinco comportamentos reproduzidos em repos de rascunho (itens 3, 4, 6, 9 e a busca do `gh`); o custo de ler os refs medido (item 17); os dez sensores que o lote toca rodados sozinhos, com o tempo de cada um |
| K2 | Problema declarado com métrica | ✅ | Seção Métrica: 17 `RESOLVED by`, 46 frases, 28 mutantes, e a linha de custo da campanha |
| K3 | Desperdícios identificados e cortados | ✅ | A metade do item 6 que o PR #391 já fechou não é refeita; `--detach`, `--after` e a troca de token saíram (superprodução); os itens 1 e 12 dividem uma leitura (`check-todo.sh --resolved`) em vez de dois parsers; três consertos trocam "alguém lembra" por mecanismo (decisões 2, 3 e 7) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 18 incrementos, cada um com um Red de uma frase e um commit; os quatro reincidentes abrem a ordem (I1 a I4) |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída do sensor ancorada em `^  ok    `, um arquivo, ou o `TODO.md`; nenhum lê a palavra do modelo. O `--red` mediu o antes de cada um |
| K6 | Jidoka — o que para a linha está definido | ✅ | Suíte vermelha, mutante não pego pelo `--only`, `shellcheck` com aviso, âncora do `TODO.md` fora do alvo ou `CHECKOUT-BUSY` no `./bin/sdd install --force`: o incremento não fecha (`blocked`, com a nota) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | 46 asserções e 28 mutantes na suíte; duas regras novas de sensor (`check-todo.sh --resolved`, a citação de ADR no `check-hat.sh`); o ADR da missão; os dois templates do `TODO.md` |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio (decisão 9): a fase DOCS deve a entrada, com o antes e o depois de cada item e a linha do L5 na tabela de custo |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: o kit é um runner em bash sem modelo de domínio; o lote muda mensagens, um alocador e dois listadores, e as duas mudanças de contrato (de onde o alocador lê, e a segunda prova do RESOLVED by) estão no ADR da missão.`

## Decisões do grill (não re-litigar)

> O dono estava fora da sala. A ordem escrita dele (a assinatura do `delegation.md` da campanha,
> nível `full` até 2026-11-26 18:00, e "continuar na missão do /sdd-worker full até zerar a
> catraca") manda o relay responder o grill pela opção recomendada. Toda resposta abaixo foi
> **delegada por escrito e não foi vista pelo dono na hora**; o aceite dele vem pelo corpo do PR
> (pendência 2).

1. **Id `20261121-l5-saida-humana-e-contrato-do-runner`, branch
   `fix/l5-saida-humana-e-contrato-do-runner`.** É o título do lote na campanha, no molde dos L3 e
   L4, e passa na regex do runner. Resposta delegada por escrito, não vista pelo dono na hora.
   - answer: (recommended)
2. **◆ O `sdd adr new` lê três lugares (item 17):** o disco do checkout, o `ADR_DIR` de todo ref em
   `refs/heads` e `refs/remotes`, e o disco dos outros worktrees; quando o máximo vem de fora do
   checkout, a saída nomeia o ref ou o worktree. Porque o `--after <n>` só funciona se o planner já
   souber da outra branch, que é o que falhou três vezes no `dotp-remake`. Limite declarado: branch
   nunca empurrada em outra máquina continua invisível. Delegada por escrito, não vista na hora.
   - answer: (recommended)
3. **◆ O `sdd-link-agents` liga também `commands/sdd-*.md` no `.claude/commands/` do repo-alvo
   (item 5),** idempotente e com a regra no `.gitignore`, como os agentes; o `sdd preflight` avisa
   quando o `/sdd-plan` não está nem ali nem em `~/.claude/commands/`. Porque o passo manual foi o
   que falhou na máquina nova, e assim nada é escrito fora do repo-alvo. Delegada por escrito, não
   vista na hora.
   - answer: (recommended)
4. **◆ A ajuda do `sdd run` mostra a forma destacada (item 14)**
   (`setsid nohup sdd run <m> > <log> 2>&1 < /dev/null &`) e onde ler o progresso
   (`.sdd/logs/pipeline.log`, `sdd status <m> --no-gates`), com o `README` apontando para o mesmo
   trecho. Porque é só texto e não toca a trava do checkout; um `--detach` poria um fork entre quem
   chama e o dono que a trava registra, e pede desenho próprio. Delegada por escrito, não vista na
   hora.
   - answer: (recommended)
5. **◆ Duas provas valem para um `RESOLVED by` sair (item 1):** o hash ancestral da base, ou o hash
   ancestral do head de um PR que o `gh` dá como `MERGED`. A segunda se escreve como dois comandos,
   nunca como rótulo: `git merge-base --is-ancestor <hash> <head do PR>` e o estado lido do `gh` na
   hora. O token e a gramática do `TODO.md` não mudam. Porque sob squash nenhuma prova só de git
   existe, e o ciclo ficava preso. **Perguntada duas vezes:** a primeira resposta veio sem o fato de
   que o `CLAUDE.md:152` diz "provado por `git merge-base --is-ancestor`, nunca pelo rótulo do PR";
   a pergunta voltou com ele, e a resposta manteve as duas provas. O texto do `CLAUDE.md` só muda
   pelo dono, por linha `⛔` da DOCS (pendência 4); o ADR da missão registra a mudança, e o
   `agents/sdd-kaizen.md` passa a dizer as duas provas. As duas respostas foram delegadas por
   escrito e não vistas pelo dono na hora.
   - answer: (recommended)
   - answer: (recommended)
6. **◆ O `sdd close` lista os `RESOLVED by` que já podem sair (item 12), e só lista:** depois do
   fast-forward, nos dois braços do JIRA, com arquivo, linha, título e a prova que valeu
   (ancestral da base, ou ancestral do head do PR da missão que o próprio close viu `MERGED`).
   Porque apagar seria o runner commitando direto na base, e uma prova errada apagaria um achado
   sem revisão. Limite declarado: sob squash, o hash de outra missão não entra. Delegada por
   escrito, não vista na hora.
   - answer: (recommended)
7. **◆ O `sdd install` rodado de novo troca a semente intocada de outro idioma (item 4):** o
   `TODO_FILE` que ainda é byte a byte a semente de outro idioma vira a semente do `OUTPUT_LANG`
   atual; com um byte diferente, é preservado. A primeira instalação diz que semeou em inglês
   porque a chave está vazia, e o `sdd preflight` avisa a semente intocada de outro idioma,
   nomeando o `sdd install`. Porque conserta também quem já instalou, sem flag nova. Delegada por
   escrito, não vista na hora.
   - answer: (recommended)
8. **Um ADR, que emenda a 0008 e registra as duas mudanças de contrato:** de onde o alocador lê
   (decisão 2, com o `--after` descartado) e a segunda prova do `RESOLVED by` (decisão 5, com a
   troca de token descartada). Porque são as duas mudanças do lote sobre as quais um leitor futuro
   perguntaria o porquê. Delegada por escrito, não vista na hora.
   - answer: (recommended)
9. **`kaizen_log:` fica vazio: a fase DOCS deve a entrada no `KAIZEN_LOG.md`,** com o antes e o
   depois de cada item medido pelos Checks e a linha do L5 na tabela de custo e tempo, ao lado dos
   L1 a L4. Porque mantém comparável a série que o dono usa para decidir o effort. Delegada por
   escrito, não vista na hora.
   - answer: (recommended)

Mecanismos do planner, sem pergunta (seguem a direção escrita em cada item; vão ao corpo do PR com
as decisões acima):

10. `aprovacao:` fica vazio: ninguém pediu `auto`, e a aprovação é do ato `approve` do worker.
11. `qa:` fica vazio: o kit não tem interface (`E2E_CMD=""`), e a QA é a sessão do `sdd-qa` que
    anda a jornada pela CLI (o passo 7 da verificação end-to-end do plano).
12. Item 6: a metade do `--help` já foi fechada pelo PR #391 e não se refaz; o I5 fecha o
    casamento por substring, recusando no `resolve_mission` todo argumento que começa com `-`.
13. Item 11: o fim da corrida nomeia o `sdd close` **nos dois braços do JIRA**, e não só com
    `JIRA_ENABLED=true` como a direção do item dizia, porque sem JIRA ele também volta à base,
    avança a base e, com a decisão 6, lista o que o merge fechou.
14. Item 9: a variável entra também nos dois `git status` do `autonomy_kit_stamp`, que leem o
    índice do kit durante a corrida de um alvo. É a mesma família, sem probe próprio, declarada no
    comentário como o `kit_guard_tree` já declara.
15. Item 10: só o `sdd status` muda. O `sdd run` continua comprando uma sessão antes de escalar
    `app-down` (pendência 5).
16. Item 7: as citações ganham o nome do kit, sem link; o `agents/sdd-kaizen.md` fica de fora,
    porque só roda no kit; uma varredura no `tests/check-hat.sh` segura a regra.
17. Itens 8 e 12: as duas listas do `sdd close` só aparecem com a árvore limpa e na base, e a das
    linhas `PR #N aberto` só com o merge verificado.
18. Item 13: o aviso cala no `sdd run` e no `sdd retry`; no `sdd approve` e no `sdd kaizen` ele
    continua, porque lá é verdadeiro.

## Pendências para o humano

1. **Antes do `sdd run`: o L4 e o PR #460 mergeiam primeiro.** O plano foi escrito sobre
   `86e16c0`. O L4 (`20261121-l4-preflight-health-e-sensores`, em execução) e o chore do L3 (PR
   #460, em revisão) mexem em arquivos que o L5 também mexe: o `bin/sdd` (o braço do `TODO.md` do
   `cmd_install` e o `cmd_preflight`, onde entra o I15 daqui; o lançamento do `cmd_run`, perto do
   aviso do I13), `tests/check-todo.sh` (uma regra nova e o `RULES_FLOOR`, como o I10 daqui),
   `tests/check-mutation.sh` (a lista do catálogo), `tests/check-preflight.sh`,
   `tests/check-gates.sh`, `commands/sdd-plan.md`, `docs/failure-modes.md` e o `TODO.md` (o #460
   apaga 13 itens e acrescenta três). Depois dos dois merges: `git merge origin/main` neste branch,
   `bash tests/check-todo.sh --anchors TODO.md` (`0 off target`), `tests/check-checkpoint.sh
   --check` e `--red` deste checkpoint de novo, e só então o `sdd run`, lançado neste worktree pelo
   `sdd` do PATH. As linhas da tabela do Gemba (229 a 634) terão andado: o executor acha cada item
   pelo título. A seção "Onde o L5 toca os mesmos arquivos que o L4 e o PR #460" do plano diz o que
   reler.
2. **Para o corpo do PR, o aceite do dono sobre as escolhas feitas sem ele:** os seis `◆`
   (decisões 2, 3, 4, 5, 6 e 7), as decisões 1, 8 e 9, e os mecanismos do planner (10 a 18). Todas
   foram respondidas pela opção recomendada, por delegação escrita.
3. **A skill `todo-to-github-issues` fica mais estrita que o template, até um retrofit dela.** A
   skill (`~/.claude/skills/todo-to-github-issues/SKILL.md`, linhas 78 e 121 a 123; repo
   `~/repos/skills`) só apaga o item cujo hash é ancestral da branch padrão. O L5 muda os dois
   templates do kit e o que o `sdd close` lista; não toca a skill. Enquanto o retrofit não vem, o
   `--fix` dela deixa de apagar o item que só a segunda prova libera (repo com squash): nunca apaga
   a mais. O retrofit é do dono, no repo da skill.
4. **⚠️ Destacada, separada dos `◆`: a decisão 5 contradiz uma frase escrita do dono.** O
   `CLAUDE.md:152` diz que o item "é apagado depois do merge, provado por
   `git merge-base --is-ancestor`, nunca pelo rótulo do PR". Com a decisão 5 valem duas provas, a
   segunda como dois comandos (`git merge-base --is-ancestor <hash> <head do PR>` e o estado
   `MERGED` lido do `gh` na hora). **O texto do `CLAUDE.md` só muda pelo dono**: a DOCS propõe a
   frase nova numa linha `⛔`, e o PR a leva. Se o dono recusar a segunda prova, revertem-se o I10
   (os templates e o `sdd-kaizen.md`) e o braço do head do PR no I11; o resto do lote não depende
   dela. Outros textos do dono que o lote desatualiza, para as linhas `⛔` da mesma DOCS: na
   `.claude/rules/anatomia-do-agente.md`, a §5 (o `sdd adr new` passa a ler refs e worktrees) e a
   §7 (a saída do `sdd status` com o app fora do ar, a linha do `sdd close` no fim da corrida e as
   duas listas do `sdd close`).
5. **A outra metade do item 10 fica sem dono neste lote.** Com o app fora do ar, o `sdd run` ainda
   compra uma sessão `QA:close` antes de escalar `app-down`, e cada leitura do `gate_QA` roda a
   e2e (que no `lighthouse_project` grava uma demanda). É o desenho de hoje, coberto por asserção.
   O I18 marca o item 10 como resolvido pelo que a direção dele pedia (o `sdd status`). O dono
   decide se a metade que sobra vira um item novo no `TODO.md`.
6. **Yokoten depois do merge:** em cada alvo, `sdd preflight` passa a avisar a falta do
   `/sdd-plan` onde ele não está nem no `.claude/commands/` do repo nem em `~/.claude/commands/`;
   onde o alvo usa `sdd-link-agents`, rodá-lo de novo liga os comandos.
7. **O carimbo:** o `sdd run` sai com rc 2 com o PR aberto e só o carimbo faltando; o PR de missão
   do kit mergeia sem ele, por regra do dono, e por merge commit, nunca squash. O chore de depois
   do merge apaga os 17 itens e desce a catraca.
