---
missao: 20260826-o-laco-da-qa
fase: DOCS
status: done
sessao: 6ab24bc8-62c3-4b09-be1e-90a972977295
data: 2026-08-26 19:05
gate: "Checklist de drift com 26 linhas, uma por área que o diff tocou: **16 ✅** com hash e **10 n/a** justificados por artefato, nenhum `✗` — contagem tirada do PRÓPRIO `awk` do `gate_DOCS` rodado sobre este arquivo (localizando a coluna pelo cabeçalho, como o gate faz), que não encontra célula pendente nenhuma. A primeira grafia deste campo dizia `24 linhas / 14 ✅` e foi corrigida por essa medição: número de checklist conferido por `grep` meu é rótulo, e é a classe que o princípio 1 recusa. Quatro commits desta fase (`a5d19a3`, `601d717`, `4ec3850`, `5eb3412`), mais este. `./tests/run-all.sh` → `suite green`, rc 0, **592** asserções `ok`, 0 FAIL. `bash tests/check-lang.sh` → `0 of 40 surface path(s) still in the allowlist, 0 new` — a superfície inglesa cresceu de 39 para 40 com o `docs/adr/0006`, e o sensor a lê limpa, sem tocar o piso (`>= 37`). `bash tests/check-todo.sh` → `74 finding(s), all within 8 lines and carrying anchor + date`, batendo com `tests/health-baseline.txt`. **Carimbo do `gate_PR` PRESERVADO**: `git diff --name-only 319239b..HEAD -- bin tests templates config` devolve vazio, `.sdd/logs/mutation-stamp` segue `3437945b9b8c910e5789bc8e0066cccf`, e nenhuma rodada de catálogo foi cobrada por esta fase. Catraca `todo-findings` **não movida** (74), porque esta fase não abriu achado novo — a decisão está em Pendências, com o preço medido. Nenhum arquivo de `agents/` tocado nesta fase, então o espelho `.claude/agents/` não precisou de `sdd install --force`; a sincronia foi conferida por `./bin/sdd preflight` → `ok 7 kit agent(s) checked`, com a árvore já limpa depois do commit deste artefato."
---

# Documentação — 20260826-o-laco-da-qa

> Escrito depois do código final e antes do PR. A pergunta não é "o que seria bom escrever",
> é **"que documento passou a descrever um mundo que não existe mais?"**. Documentação que mente
> custa confiança toda vez que alguém a segue e se queima.

## TL;DR

A rodada de REVIEW já tinha fechado **quatro** dos seis drifts que a EXEC listou — os três
documentos que a missão tornou literalmente **falsos** (`docs/pipeline.md` em duas frentes,
`docs/qa/README.md`, `agents/sdd-qa.md:92`) foram corrigidos no mesmo diff do código, como o
`CLAUDE.md` exige. Sobraram os dois aditivos que o checklist kaizen previu (K7 e K8), e esta fase
achou **mais três** que ninguém tinha listado.

O que esta fase escreveu, em quatro commits:

- **`docs/adr/0006`** (novo) — a decisão arquitetural com as alternativas recusadas. Sem ele, *"por
  que o `sdd-qa` simplesmente não fecha o bug?"* volta à mesa na próxima missão, e a resposta cara
  (dos quatro `wont-fix` que desbloquearam a missão 1, **dois eram P1**) mora hoje só num artefato
  de missão que ninguém relê;
- **`CLAUDE.md`** — a régua do **gate insatisfazível**: verificável por comando é metade do
  princípio 1, e a outra metade é quem tem permissão de escrever o artefato exigido;
- **`CONTEXT.md`** — os dois verbetes novos e a linha `D17`, que roteiam para o ADR;
- **`docs/failure-modes.md`** — o drift que ninguém tinha listado: a seção *"The QA⇄EXEC loop does
  not converge"* dava o sintoma como *"the bug registry does not empty"*, que o I2 tornou falso, e
  o **conselho** ficou errado junto. Mais uma seção nova para a mensagem que a terceira Jidoka faz
  o operador ler;
- **`docs/qa/README.md`** — o campo **não** viaja para repo-alvo nenhum, e ninguém documentava isso;
- **`KAIZEN_LOG.md`** — o antes/depois, com a base **medida em worktree** e não citada dos handoffs.

**Nenhum achado novo foi aberto por esta fase**, e isso é decisão medida, não omissão — ver
"Pendências". Por consequência a catraca não se moveu, e por consequência disso **o carimbo do
`gate_PR` sobreviveu à fase DOCS inteira**: a fase PR não precisa de outra rodada de catálogo.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — Âncora 3 do `gate_QA` passa a contar só o bug `open` que um AGENTE pode fechar | `docs/pipeline.md` § QA "Passes when" e o parágrafo do `wont-fix` | ✅ | `7201632` — a frase dava "no file … has `**Status:** open`" como a condição, e o I2 a tornou falsa; corrigida nas três frases em que ela aparecia |
| `bin/sdd` — o campo `Closable by:` como segunda leitura do mesmo arquivo de bug | `docs/qa/README.md` fato 2, mais `agents/sdd-qa.md` § 5.1 | ✅ | `7201632` e `cf43bb3` — a âncora foi re-ancorada no NOME do bloco, porque o número de linha que ela citava já apontava para prosa do `gate_TICKET` |
| `bin/sdd` — ausente barra: o fail-safe que decide o destino de todo registry legado | `docs/pipeline.md`, `docs/qa/README.md`, `agents/sdd-qa.md` § 5.1, e o ADR | ✅ | `7201632`, `50752a9`, `a5d19a3` — dito nos quatro como **decisão**, nunca como detalhe, porque o default permissivo desligaria a âncora inteira num passo |
| `bin/sdd` — `GATE_WHY` da Âncora 3 passa a nomear a saída pela outra porta | `docs/failure-modes.md` § "The QA⇄EXEC loop does not converge" | ✅ | `4ec3850` — o conselho antigo mandava o operador de volta ao planejamento, que é a resposta errada justamente no caso pelo qual a âncora foi reescrita |
| `bin/sdd` — as três grafias que leem como AUSENTE e barram caladas (valor depois da legenda, `humano`, `Human`) | `docs/failure-modes.md` (mesma seção) e `agents/sdd-qa.md` § 5.1 | ✅ | `4ec3850` e `50752a9` — a direção é segura mas o silêncio não: o gate diz que o bug está aberto, não que o gênero está malescrito |
| `bin/sdd` — `handoff_blocked_escalation`: UMA definição, DUAS portas no laço do `cmd_run` | `CLAUDE.md` § "Ao mexer no runner", parágrafo do `kit_guard_check` | ✅ | `601d717` — a frase afirmava que este arquivo recusa a forma em toda OUTRA família; desde `26b74a0` são duas, e a conta de um probe por porta vale igual |
| `bin/sdd` — a escalada escreve `kind: handoff-blocked` no ledger | `docs/pipeline.md`, tabela de esquema do ledger | ✅ | `7201632` — o enum estava documentado como FECHADO de quatro valores; ganhou o quinto mais a ressalva medida de que nenhum leitor em runtime valida `kind` |
| `bin/sdd` — DOOR 1 sobe para ACIMA do `--max-phases` | `docs/failure-modes.md` seção nova, e o ADR § Consequences | ✅ | `4ec3850` e `a5d19a3` — abaixo do teto, `sdd run --max-phases 1` pagava a sessão e devolvia rc 0 calado: o laço da missão vestindo um rc verde |
| `bin/sdd` — as cinco linhas que o humano lê quando a terceira Jidoka dispara | `docs/failure-modes.md`, seção nova ao lado das duas Jidokas irmãs | ✅ | `4ec3850` — sintoma, causa, o que você faz, e o "não faça" que importa: outra sessão relê o mesmo handoff e recusa igual |
| `bin/sdd` — `GATE_HANDOFF_BLOCKED`, o marcador global | — | n/a | variável interna do runner. Nenhum documento descreve globais um a um, e o CONTRATO que ela serve — resetar na entrada do gate que a seta, nunca no chamador — mora no comentário dela, que é onde quem ensina o token a um segundo gate está olhando. O que tem consumidor externo é o EFEITO, e ele tem quatro linhas acima |
| `bin/sdd` — a Âncora 3 trocou um `grep -rl` por um `awk` por bug aberto | — | n/a | é mudança de LEITURA dentro do contrato já documentado nas linhas acima: a promessa ao autor do bug não mudou, mudou a fidelidade com que o gate a lê. O porquê (a cerca é ESTADO, e um matcher linha a linha não a segura) mora no comentário do bloco |
| `docs/qa/templates/bug.md` — o campo `- **Closable by:**` | `docs/qa/README.md`, `agents/sdd-qa.md` § 5.1 e o verbete do `CONTEXT.md` | ✅ | `7201632`, `cf43bb3`, `a5d19a3` — e o parágrafo de semeadura em `4ec3850`, que é o que faltava: o campo NÃO chega a repo-alvo nenhum sozinho |
| `docs/qa/templates/bug.md` — a cópia deste repo passou a divergir do asset da skill | `docs/qa/README.md`, mesmo parágrafo | ✅ | `4ec3850` — a linha do I1 é hoje a única diferença entre os dois, e **nenhum sensor** cobre `docs/qa/templates/`. Limite declarado no parágrafo em vez de calado |
| `agents/sdd-qa.md` mais o espelho `.claude/agents/` | o próprio agente, sincronizado por `sdd install --force` | ✅ | `cf43bb3`, `21c2532`, `50752a9` — § 4, § 5, o § 5.1 novo, a linha de idioma e as regras não-negociáveis. Conferido nesta sessão por `sdd preflight` → `7 kit agent(s) checked` |
| A decisão arquitetural da missão, e as duas alternativas recusadas | `docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md` (novo) | ✅ | `a5d19a3` — inclui a recusa de (A) contar só a missão e de (B) dar `wont-fix` ao agente, mais as três recusas menores (default permissivo, mover a amostragem de `moved2`, grepar `GATE_WHY`) |
| O vocabulário que a missão criou, e a decisão na tabela resolvida | `CONTEXT.md` — verbetes "Gênero do bug" e "Gate insatisfazível", linha `D17` | ✅ | `a5d19a3` — índice roteia, profundidade no ADR; os dois verbetes carregam o resíduo declarado em vez de fingir a classe fechada |
| A lição de processo: gate verificável que ninguém pode satisfazer | `CLAUDE.md` princípio 1 | ✅ | `601d717` — a régua e a rota; as alternativas ficam no ADR. K7 do checklist kaizen |
| A missão como um todo — antes/depois medido | `KAIZEN_LOG.md` | ✅ | `5eb3412` — tabela de 11 linhas, os três defeitos que as próprias fases pegaram, e a correção do número que dois handoffs registraram errado. K8 do checklist kaizen |
| `tests/check-gates.sh` — 10 asserções novas, 129 → 139 | — | n/a | asserção interna de sensor. A CLASSE já está no `CLAUDE.md` (regime diferencial, red pelo motivo certo) e não mudou. Documentar mundo a mundo seria o inverso da disclosure progressiva: a profundidade de um mundo mora no comentário dele |
| `tests/check-autonomy.sh` — 5 asserções novas, 184 → 189 | — | n/a | idem. As duas escaladas novas são medidas por par diferencial, que é a forma que o `CLAUDE.md` já manda usar quando a alegação é "X responde diferente de Y" |
| `tests/check-mutation.sh` — 6 mutantes novos, 148 → 154 | `CLAUDE.md` § "TDD aqui dentro" — "gate novo entra com mutação" | n/a | a regra não mudou e continua paga: `sdd health` reprova gate sem mutação, e os 8 de 8 seguem cobertos. O número nunca é escrito em prosa lá de propósito — sai da linha `score:`, e fixá-lo seria uma data de validade escrita à mão |
| `tests/health-baseline.txt` — `todo-findings` 72 → 74 | `CLAUDE.md` princípio 5 e `docs/failure-modes.md` § "the backlog count moved" | n/a | mecanismo da catraca inalterado, e a colisão com o carimbo já está documentada nos dois lugares desde `20260819-fecho-que-nao-mente`. Esta fase a **pagou na prática** — ver Pendências |
| `TODO.md` — 2 achados novos, os dois da rodada de REVIEW | `CLAUDE.md` princípio 5 e o cabeçalho do próprio `TODO.md` | n/a | formato e ciclo de vida inalterados. As 2 entradas foram lidas uma a uma nesta sessão — seção abaixo |
| `README.md` — como instalar, rodar ou usar | — | n/a | nada disso mudou: a mudança é em condição de gate e em contrato de agente, e nenhum comando ganhou, perdeu ou trocou de bandeira. Conferido também o roteamento: a tabela "Documentation" já cita `docs/adr/` e `CONTEXT.md`, então o ADR novo nasce alcançável pelo índice |
| `config/schema.md` — nenhuma chave nova nem semântica mudada | — | n/a | `QA_DOCS_PATH` segue apontando para a mesma árvore e `QA_MAX_ITER:77` segue descrevendo rodadas do laço QA⇄EXEC, que continua existindo — o que mudou foi QUAIS bugs o mantêm girando, e isso é condição de gate, documentada no `docs/pipeline.md`. Tocar `config/` aqui também mataria o carimbo por uma frase que não mudou |
| `docs/handoffs/20260826-o-laco-da-qa/*` | — | n/a | artefato de missão, não documentação viva do repo. É o registro que os documentos acima citam quando precisam de profundidade — e o `20-handoff-exec.md` § "Drift para a fase DOCS" foi a lista de partida desta tabela |

## Entradas do `TODO.md` conferidas nesta missão

`tests/check-todo.sh` cobra forma — âncora, data, teto de 8 linhas — e responde
`74 finding(s)` verde, batendo com `tests/health-baseline.txt`. O que ele **não** cobra é se o item
diz por que importa e para onde ir: essa parte foi lida à mão.

**2 entradas carregam o slug desta missão**, as duas da rodada de REVIEW, e as duas são bem
formadas: o quê em negrito, âncora `arquivo:linha`, o mecanismo, o que foi **reproduzido**, uma
direção, e o rodapé `descoberto por <agente> na missão <slug> (data)`.

| Autor | Entradas | Observação |
|---|---|---|
| `sdd-reviewer` | 2 | `sdd retry` que devolve 3 sem escrever linha de escalada no ledger, e a citação NÃO-cercada acima do cabeçalho que ainda vira o gênero |
| `sdd-qa` | 0 | os 2 achados da QA moram em linhas que esta missão escreveu, então viraram `F1`/`F2` em vez de backlog |
| `sdd-executor` | 0 | ver o `20-handoff-exec.md` § "Achados fora de escopo": o que ele viu ou estava no escopo, ou foi resolvido no commit que o criou (três comentários citando `agents/sdd-qa.md:142`, re-ancorados no heading em `cf43bb3`) |
| `sdd-docs` | 0 | esta sessão não abriu nenhum — ver "Pendências" |

**Nenhuma precisou ser completada.** As duas âncoras foram conferidas contra o código de hoje, que
é o que envelhece primeiro: `bin/sdd:3653` ainda é o `cmd_retry` que sai 3 sem chamar
`autonomy_blocked_row`, e `bin/sdd:686` ainda é o `awk` do extrator de gênero que o segundo item
descreve. As duas apontam para o que o corpo diz.

⚠️ A segunda entrada é o caso que a régua D15 decide, e ela decidiu **entrar**: o resíduo já está
declarado no comentário do `bin/sdd`, e declarar não conserta um fail-open — só o deixa de esconder.
O ADR 0006 repete a mesma leitura na seção de consequências, para que ninguém a leia como
duplicidade.

## O que foi deliberadamente NÃO escrito

- **Nada sobre asserção individual de sensor.** São quinze nesta missão. O índice roteia; a
  profundidade mora no cabeçalho de cada `tests/check-*.sh` e no comentário de cada mundo, que é
  onde quem edita o sensor está olhando. `CLAUDE.md` que cresce toda missão vira documento que
  ninguém lê e que estoura a janela da próxima sessão — e doc que estoura a janela é doc quebrado.
- **Nenhuma regra nova de QA no `CLAUDE.md`.** O dever de marcar o gênero é contrato de agente e já
  está escrito em **três** lugares que a sessão de QA lê (`agents/sdd-qa.md` § 5.1, `docs/qa/README.md`
  e `docs/pipeline.md` § QA), todos atualizados no mesmo commit da mudança. Uma quarta cópia no
  `CLAUDE.md` seria a que envelheceria primeiro. O que entrou lá é a régua de **desenho de gate**,
  que não tem outro dono.
- **Nenhuma regra inventada.** Duas afirmações do `CLAUDE.md` mudaram, e as duas porque o mundo que
  descreviam acabou num commit com hash — o princípio 1 (incompleto, medido a US$ 73,32) e a frase
  sobre a forma "uma definição, N portas" ser recusada em toda outra família (desde `26b74a0` são
  duas). Regra escrita por agente sem mudança correspondente é dívida que o próximo obedece sem
  questionar.
- **Nenhuma reforma do `docs/pipeline.md`.** Ele passa de 40 KB e o item "merece a sua missão" já
  está no `TODO.md`; refatorar documento de outra pessoa no meio desta missão é desvio de escopo. O
  que entrou nele entrou na rodada de REVIEW, no mesmo commit da mudança que o tornou falso.
- **Nenhum conserto de código, e nenhuma correção de âncora em `bin/` ou `tests/`.** Consertar
  qualquer coisa ali mataria o carimbo por uma linha de comentário — 20 a 50 min antes do `gate_PR`.
- **Nenhuma reescrita dos handoffs das fases anteriores.** O `40-review-r1.md` registra 581
  asserções como a base da missão, e a base real é 577 (medida nesta fase em worktree de `main`). O
  handoff é registro imutável do que aquela sessão mediu; a correção mora no `KAIZEN_LOG.md`, que é
  o documento vivo, e está lá para que o corpo do PR não repita o número errado.

## Pendências para o humano

1. **Um achado que esta sessão VIU e não registrou, e o motivo — que é ele mesmo o item já aberto.**
   O `20-handoff-exec.md` registra como não-feito que o campo `Closable by:` **não chega a repo-alvo
   nenhum**: a skill `qa-report` semeia o template do projeto a partir do asset dela, `sdd install`
   não distribui árvore `docs/qa/`, e nenhum sensor cobre `docs/qa/templates/`. Tem consumidor fora
   da suíte do kit (o adotante), então pela régua D15 é admissível. **Não foi registrado**, e o
   preço da alternativa é a razão: `TODO.md` novo obriga mover `tests/health-baseline.txt` no mesmo
   commit (princípio 5 + catraca), esse arquivo mora dentro da chave do carimbo, e cada achado novo
   custa uma rodada de 20 a 50 min de catálogo antes do `gate_PR`. A colisão já é item do backlog
   desde `20260819-fecho-que-nao-mente`. O que esta fase acrescenta é a **segunda medição do mesmo
   incentivo**: pela segunda missão seguida, a fase mais barata do pipeline é a primeira a ter
   motivo econômico para não anotar o que viu. A metade documental foi paga de graça em `4ec3850`,
   que é o parágrafo novo do `docs/qa/README.md`. Quem discordar do corte: o item cabe num commit e
   a catraca aceita o número — só custa a rodada de catálogo.
2. **O ADR 0006 nasceu numa sessão sem humano.** Ele registra a decisão **como tomada** no grill de
   2026-08-26, e o grill teve humano presente — mas quem a escreveu como registro arquitetural fui
   eu, sozinho. Ler o 0006 e discordar dele é trabalho legítimo, e é mais barato agora do que na
   próxima missão que o citar. Vale sobretudo para a recusa de (B): ela é a que impede um agente de
   fechar bug P1 por conta própria, e é a que mais parece burocracia até o dia em que não é.
   — `docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md`.
3. **O efeito que a missão promete não é medível aqui, e não será nesta missão.** O antes/depois do
   `KAIZEN_LOG.md` mede a **condição** que produzia o laço, regime por regime. O número que motivou
   a missão — 12 sessões de QA numa missão de repo-alvo — só reaparece na próxima missão de
   repo-alvo, e o registry do próprio kit está limpo (6 arquivos, 0 `open`), então o regime
   consertado nem sequer é reproduzível fora de fixture. Se a próxima missão de alvo não medir a
   fase QA, esta missão não terá Check. — `00-missao.md` § Métrica, `KAIZEN_LOG.md`.
4. **A ADR 0005 continua com `Implementation: NOT YET IN THE RUNNER` no cabeçalho**, e esta fase não
   a tocou. Ela é a missão seguinte, por decisão registrada do grill (decisão 5), e o argumento era
   que o preço desta missão é o que torna aquela pagável. Se o pipeline rodar de novo antes dela, o
   juiz do kaizen segue lendo só o repo do kit — o eixo que o ADR 0003 declarou inutilizável.
   — `docs/adr/0005-judge-reads-every-repo-with-visible-composition.md`.

## Boot da próxima fase

**A próxima fase é PR** (`sdd-publisher`).

⚠️ **O carimbo do `gate_PR` está VIVO e é o mesmo que a REVIEW ganhou**:
`3437945b9b8c910e5789bc8e0066cccf`, sobre o conteúdo de `319239b`. Esta fase commitou cinco vezes e
não tocou `bin/ tests/ templates/ config/` — conferido com
`git diff --name-only 319239b..HEAD -- bin tests templates config`, saída vazia. **Não rode
`./bin/sdd health` de novo**: a fase PR não precisa dele, e ele custa 20 a 50 min.

Se o `gate_PR` mesmo assim recusar com `no green mutation catalogue for this content`, alguma coisa
tocou os quatro diretórios depois deste handoff: rode `./bin/sdd health`, deixe terminar, e **nunca
encerre o turno esperando** — sessão headless que encerra o turno é sessão que acabou. A seção
"The `PR` gate refuses" do `docs/failure-modes.md` tem os três estados e a saída de cada um.

O corpo do PR tem material medido em quatro handoffs, e três coisas que valem a pena citar
nominalmente:

- **a métrica do `00-missao.md` fechou nos cinco fatos binários**, com o quinto em
  `score: 154 caught, 0 known gap(s), of 154` e `all 8 gates have a mutation in the catalogue`;
- **os três defeitos que a própria missão criou e as próprias fases pegaram** estão com reprodução
  literal no `30-handoff-qa.md` e no `40-review-r1.md` — é a evidência mais forte do PR, porque
  mostra o pipeline mordendo o próprio trabalho;
- **o número da base é 577, não 581.** O `40-review-r1.md` traz 581 como "quando a missão começou",
  e 581 é a medição da QA, tirada depois do I1–I4. A base foi remedida nesta fase num worktree de
  `main` (rc 0, 577 asserções `ok`) e corrigida no `KAIZEN_LOG.md`. O ganho da missão é **+15**
  asserções, não +11 — cite o número certo.

A seção "Decisions for a Human" do PR sai das quatro Pendências acima. Nenhuma delas bloqueia o
merge; a primeira é a que tem custo em dinheiro, e ela é uma **escolha**, não um esquecimento.
