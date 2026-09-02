# CLAUDE.md — convenções do kit `sdd_agents`

Instruções para quem trabalha **neste repositório** (o kit). Para o que os agentes fazem nos
repos-alvo, veja [`docs/pipeline.md`](docs/pipeline.md).

## Idioma

Duas audiências, duas regras. A regra antiga ("PT-BR em tudo que é lido por humano") misturava as
duas e por isso trancava o kit num idioma só — quem não fala português não conseguia usar nada.

**A superfície do kit é inglês:** `bin/sdd`, `agents/`, `docs/`, `README.md`, `config/schema.md`,
`config/starter.conf`, `tests/`. Vale para prosa, comentários, mensagens ao usuário, nomes de
teste e identificadores locais. O sensor é `tests/check-lang.sh`, com catraca bidirecional em
`tests/lang-allowlist.txt`: arquivo sujo fora da lista reprova, arquivo já limpo dentro dela
também. Duas exceções, ambas documentadas no cabeçalho do sensor, porque nelas o português é
**dado** e não prosa — `check-templates.sh` (as regexes são os headings dos templates) e
`check-lang.sh` (o dicionário e os probes).

**O artefato de missão fala `OUTPUT_LANG`:** handoffs, checkpoint, mensagens de commit e corpo do
PR seguem a chave do `.sdd/config.sh` do repo-alvo, que o runner injeta no prompt de boot de toda
fase. Vazio ⇒ o runner não diz nada e a sessão segue o idioma dos artefatos que já existem.
Aqui a chave é `pt-BR`, e é por isso que `TODO.md`, `KAIZEN_LOG.md`, este arquivo,
`docs/handoffs/`, `templates/` e `config/examples/` continuam em português — não são exceção, são
conteúdo no idioma declarado.

**O contrato é sempre inglês:** chaves de config, tokens de status (`pending`, `doing`, `done`,
`blocked`, `auto`, `skipped`), os enums das skills de terceiro e identificadores de código.
⚠️ Três chaves de frontmatter (`aprovacao`, `versao`, `titulo`) e dois nomes de artefato
(`00-missao.md`, `01-plano.md`) ainda são PT-BR por herança — estão no `TODO.md`, e renomeá-los
quebra missão em voo.

## Princípios não-negociáveis

**1. Gate = artefato, nunca rótulo.** Nenhuma fase é "concluída" porque o modelo disse que
concluiu. O runner reavalia: roda `TEST_CMD`, faz `grep` no checkpoint, consulta `git log`,
chama `gh pr view`. Se você está escrevendo um gate novo e ele não é verificável por comando,
o gate está errado.

⚠️ **Verificável por comando é METADE da régua. A outra metade é: quem, dentro do pipeline, tem
permissão de escrever o artefato que o gate exige?** Se a resposta é "ninguém", o gate não para a
linha — ele a faz **girar**, porque o runner lê "moveu o disco" como progresso, e numa fase
insatisfazível todo achado honesto vira commit e todo commit compra a volta seguinte. A Âncora 3 do
`gate_QA` era verificável, determinística e barata, e exigia uma linha (`Status:` do registry) que
nenhum agente do kit tem permissão de escrever: 7 das 12 sessões de QA de
`20260825-frete-cif-fob`, **US$ 73,32 dos US$ 144,88** da missão. Gate novo nomeia o dono do
artefato no próprio comentário; gate que descobre não ter dono se conserta subindo o **código** até
a promessa, nunca baixando a promessa até o código — as duas alternativas que faziam o inverso
estão recusadas com argumento em
[`docs/adr/0006`](docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md). Verbete
"Gate insatisfazível" no [`CONTEXT.md`](CONTEXT.md).

**2. Sensores, não percepção.** Todo trabalho cria um instrumento automático que prova que está
correto — teste TDD (lógica), spec Playwright (jornada), gate do runner (fase), preflight
(ambiente), checklist de drift (documentação). Sensor durável > checagem manual efêmera.
Sensor novo é commitado e passa a rodar no CI. Sensor vermelho para a linha (Jidoka).

**3. Estado em disco, não em contexto.** Fase = sessão nova. Incremento = sessão nova. Tudo que
a próxima sessão precisa saber está em `docs/handoffs/<missão>/`. Um prompt de boot bem escrito
+ os artefatos bastam; nunca assuma conversa anterior.

**4. Sem arquivo de estado.** A fase corrente é **derivada** dos artefatos. Isso dá resume de
graça depois de qualquer morte de sessão e elimina a classe de bug "estado mente sobre o disco".

**5. Achado fora de escopo → `TODO.md`.** Qualquer coisa relevante que não cabe na missão atual
vira entrada no `TODO.md` do repo-alvo (ou **deste** repo, se for melhoria do kit). Nunca desviar
o escopo; nunca perder o achado. Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

⚠️ **A rota depende de quem é o repo da missão, e dizer só o DESTINO não bastou.** Missão cujo
repo é o kit escreve aqui, como sempre. Missão de repo-alvo **nunca escreve, commita ou entra** no
repositório do kit: a linha completa do achado vai na seção de achados fora de escopo do handoff,
marcada `kit:`, e quem transporta é o humano ou a triagem do `sdd kaizen`. Medido em `2d28d13` —
uma sessão de EXEC cujo alvo era outro repo commitou um achado de kit direto na `main` daqui, com
a suíte vermelha e fora de qualquer revisão, e as linhas de ledger da própria corrida passaram a
carimbar o sha do commit que a corrida acabara de fazer. O runner hoje avisa e registra
(`KIT-TOUCHED` no `pipeline.log`), mas **não para a linha** — guarda de aviso, não fronteira.
⚠️ A guarda mora nos **chamadores**, e são quatro portas: as duas do laço do `cmd_run`, o
`cmd_retry` e o `cmd_close`. É a forma que este arquivo recusa em toda outra família (o `journal`
tem UMA definição de escalada justamente por isso), e aqui ela é deliberada — o `kit_guard_check`
precisa correr **depois** de `moved2` ser amostrado, e uma guarda dentro do `run_phase` cairia
dentro da janela. O preço é que a quinta porta nasce desguardada; ele é pago com um probe por
porta (`tests/check-autonomy.sh`, regimes 1, 4, 5 e 7), então porta acrescentada sem probe é porta
cuja remoção nenhuma asserção percebe.
⚠️ **A forma tem hoje TRÊS instâncias deliberadas, e a frase acima ("este arquivo a recusa em toda
outra família") vale para as outras, não para estas.** O censo sai do comando, nunca desta linha —
é a mesma régua do `44 caught of 44`, conte a propriedade e não a palavra:

```bash
grep -cE '^[a-z_]+_escalation\(\) \{'                 bin/sdd   # definições de escalada → 2
grep -cE '^ +if [a-z_]+_escalation "\$phase"; then'   bin/sdd   # portas delas           → 4
grep -cE '^ *kit_guard_check "'                       bin/sdd   # portas da guarda de kit → 4
```

⚠️ O `-E` com âncora não é capricho: `grep -F 'escalation "$phase"'` responde **5**, porque conta a
linha de comentário que exibe a grafia. A conta é sempre a mesma, **um probe por porta**, e porta
acrescentada sem probe é porta cuja remoção nenhuma asserção percebe.

- `handoff_blocked_escalation`, desde `20260826-o-laco-da-qa`: UMA definição com DUAS portas no
  mesmo laço do `cmd_run` — a primeira passada e o retry inline. A segunda porta não é simetria:
  com só a primeira, o marcador sobrevivia à **volta** em vez de ao gate, e a escalada saía
  carimbada `{phase: EXEC}` sobre um handoff de EXEC que dizia `done`;
- `app_down_escalation`, desde `20260828-o-gate-sabe-que-o-app-caiu`: o irmão voltado ao ambiente,
  mesmas duas portas do mesmo laço, mesmo rc 3. A F2 do irmão foi **reproduzida em cópia** antes
  de a porta 2 existir — `QA|app-down` virava `EXEC|app-down` —, e é o par
  `mut_RUN_app_down_not_escalated` / `mut_RUN_app_down_retry_not_escalated` que a segura hoje.
  ⚠️ Marcador novo **re-deriva** o contrato (reset na entrada do seu único setter, não sobrevive à
  volta) em vez de herdá-lo: é o que o comentário sobre `GATE_APP_DOWN` faz, e é o que se cobra do
  quarto.

A projeção (`--dry-run`) **não arma nada** em nenhuma das duas: `sdd run --dry-run` não abre sessão
a que atribuir mudança, e armar mesmo assim fazia a projeção herdar o aviso de ledger do
`autonomy_kit_stamp` — medido, 0 avisos antes e 1 depois, com o kit instalado como cópia simples.

O item **cabe em ~6 linhas** (teto duro de 8, medido por `tests/check-todo.sh`): o quê, a âncora
em `arquivo:linha`, por que importa, a direção, quem descobriu. A análise longa mora no handoff
da missão citada — duplicá-la aqui foi o que levou este arquivo a 861 linhas.

Fechado **é apagado**, nunca arquivado: o item com `RESOLVIDO por <hash>` fica na seção Aberto só
até o PR que cita a evidência ser mergeado, e então sai do arquivo. A memória durável já existe
em três lugares (`git log -S`, `KAIZEN_LOG.md`, handoffs) e o próprio item cita o hash. Apagar
prova por artefato — `git merge-base --is-ancestor <hash> main` —, nunca pelo rótulo do PR.
⚠️ `- [x]` não existe neste arquivo: caixa marcada era uma segunda convenção de fechamento,
invisível para a triagem do kaizen, que procura `RESOLVIDO por` no corpo.

**Nem tudo que é verdade é achado — a régua de admissão (D15).** Um achado entra no `TODO.md`
quando **o sensor afirma medir o que não mede** (fail-open) ou quando **o defeito tem consumidor
fora da suíte do próprio kit**. Fora disso, a dívida vai para o **cabeçalho do sensor**, na seção
de limites declarados, e não para o backlog: uma regra sem probe próprio cuja redundância é
*declarada* — "esta regra é pega por outro caminho, e o cabeçalho diz isso" — deixa de ser defeito
no instante em que está escrita. Dívida declarada é limite; dívida calada é o fail-open que a
régua existe para separar dela.
A régua ataca a **taxa de nascimento**, não o estoque, e é por isso que ela vem antes de qualquer
faxina: 16 itens fechados contra 29 nascidos em duas missões é um arquivo que cresce por acúmulo
de verdades, não de problemas. Quem aplica é a triagem do `sdd kaizen` e quem escreve o achado.
⚠️ Ela **não** é licença para declarar tudo e esvaziar o backlog: um fail-open segue entrando
mesmo depois de escrito no cabeçalho — escrever não conserta, só deixa de mentir. Aplicada pela
primeira vez à família do `check-todo.sh` (6 itens): dois saíram para o cabeçalho do sensor,
quatro ficaram porque são fail-open, e a catraca desceu 76 → 74 num diff com autor.

**Crescer é permitido; crescer calado, não.** O `sdd health` emite a contagem de achados abertos
como o achado `todo-findings <N>`, e `tests/health-baseline.txt` a congela. A catraca morde nos
dois sentidos: número que subiu sem registro reprova, e baseline que ficou para trás depois de uma
faxina reprova junto. Missão que legitimamente descobre três coisas continua registrando as três —
só que o número passa a se mover num diff com autor, em vez de derivar. Medido: 56 → 68 itens em
duas missões, 16 fechados contra 29 nascidos, e nenhum instrumento dizia. A catraca mora no
`sdd health` e **não** no `TEST_CMD` de propósito: um teto dentro da suíte reprovaria
`gate_EXEC`/`QA`/`REVIEW` de toda missão em voo, inclusive a que acabou de registrar o achado.
⚠️ A contagem sai de `tests/check-todo.sh` e nunca de um `grep -c` novo — o `grep` responde um a
mais, porque conta a linha de exemplo do cabeçalho.

**6. YAGNI.** Sem daemon, sem UI, sem banco, sem servidor. Um script bash, seis markdowns e
templates. Se a solução pede infraestrutura, provavelmente é a solução errada.

## Ao mexer no runner (`bin/sdd`)

- `set -euo pipefail` sempre; `bash -n bin/sdd` é o smoke test mínimo.
- **A última linha é `{ main "$@"; exit $?; }`, e a forma é contrato.** Sem as chaves e sem o
  `exit`, o bash volta a ler o arquivo pelo offset salvo ao retornar de `main` — e a fase EXEC
  edita o `bin/sdd` durante o `sdd run` que a executa. Quem cobra é `tests/check-entrypoint.sh`,
  com o mutante `RUN_entrypoint_unguarded`.
- Toda função de gate se chama `gate_<FASE>` e retorna 0/1, escrevendo o motivo em `stderr`.
- Nada de `bypassPermissions` como default — `acceptEdits` é o teto. Mas `acceptEdits` **sozinho
  não basta**: ele auto-aprova edição de arquivo, não `Bash`. `run_phase()` precisa passar
  `--allowedTools "$ALLOWED_TOOLS"` junto, ou a sessão não roda `TEST_CMD`, não faz `git add`, e
  a fase EXEC fica insatisfazível por construção. Detalhe em [`config/schema.md`](config/schema.md).
- Toda invocação de `claude -p` **que roda uma fase** passa por `run_phase()`, que loga JSON em
  `.sdd/logs/`. As duas exceções são deliberadas e não rodam fase: o probe do `sdd preflight` e o
  `sdd close`. Se você está acrescentando uma terceira, provavelmente ela devia ser uma fase.
- Mudou o contrato de artefato? Atualize `templates/`, `docs/pipeline.md` e o agente afetado no
  **mesmo commit** — contrato quebrado em três lugares é o modo de falha mais caro do kit.
- **Enum lido em mais de um ponto vira UMA definição por programa.** `blocked` e `degraded` são os
  dois eventos de escalada do ledger, e o par estava escrito à mão em três lugares (admissão da
  série, mapa de escaladas, rubrica de rótulo). Dois aprenderam o evento novo, o terceiro ficou
  cego — e a única missão em que o runner baixou a própria régua passou a ler `ok` para o juiz.
  Hoje cada programa define `is_escalation` uma vez. Evento novo entra pela definição, nunca por
  um `or` acrescentado a um `select`.
  ⚠️ **Comentário que afirma paridade entre dois programas não é paridade.** Segunda instância da
  classe, medida na r1 de `20260817-catraca-do-backlog`: o `$order` do `cmd_autonomy` lia "qual é
  a versão mais recente" sobre `is_session and comparable`, o `kaizen_series` lê sobre **toda**
  linha `on_axis`, e o comentário entre os dois jurava *"same spelling on purpose, in both
  programs"*. Com uma escalada como primeira linha de uma versão, as duas janelas respondiam
  diferente sobre o MESMO arquivo. Quem prova paridade é asserção **diferencial** — as duas saídas
  comparadas entre si —, nunca a frase.
  ⚠️ **Terceira instância, e ela acrescenta uma cláusula: predicado de admissão se escreve
  POSITIVAMENTE.** Medida em `20260831-a-rodada-que-andou` (`bin/sdd:5207`), quando o ledger ganhou
  o terceiro evento (`gate_pass`). O `is_escalation` estava certo — uma definição por programa, e o
  evento novo ficou **fora** dele de propósito. Quem o admitia por **omissão** era o eixo do juiz:
  `shas_in_file_order` rodava sobre `$ok`, e o `comparable_row` deixa passar toda linha que não é
  sessão. Resultado reproduzido com UMA linha acrescentada a um ledger de fixture: a closure
  **cunhava uma versão** — `latest` numa fatia de `sessions: 0`, `previous` deslizando,
  `degenerate_axis` de `true` para `false` — e o `gate_KAIZEN` deriva o sha esperado de
  `latest.kit_sha`, então um veredito já escrito deixava de satisfazer o gate: **gate
  insatisfazível**, a classe que o princípio 1 proíbe. Uma definição (`session or escalation`)
  fechou os dois chamadores. Escrevê-la como `is_gate_pass | not` concordaria sobre a população de
  hoje e faria o **quarto** evento cunhar versão por omissão: `not <o que sai>` admite todo evento
  futuro, `<o que entra>` obriga o próximo a optar. Fail-safe é a direção que o eixo quer.
- **Captura na região do `sdd health` é guardada, ou a suíte reprova na linha que você escreveu.**
  `bin/sdd` roda sob `set -euo pipefail`, então `x="$(cmd)"` mata o processo **na atribuição** no
  instante em que `cmd` devolve não-zero — e para `grep`, `find` e pipeline com `pipefail`,
  "não-zero" é só "não achou nada". Todo `health_bad` escrito abaixo de uma linha dessas é código
  morto, e o comando que existe para responder *"o kit ainda mede o que diz medir?"* responde
  **calando**. Conserte com `|| rc=$?`, `|| true` ou `if out="$(…)"; then`. Quem cobra é a regra
  `guard:` do `tests/check-health.sh`, que **enumera a região** em vez de sondar sítio por sítio —
  e a razão é medida: `20260818-lote-facil` fechou cinco sítios um a um e declarou a família
  varrida; a r2 da mesma missão achou **onze** ainda vivos no mesmo comando, três reproduzidos
  ponta a ponta. Probe por sítio prova os sítios que têm probe e não diz nada sobre o décimo
  segundo. ⚠️ A regra de hoje conhece **uma** grafia de captura (`x="$(cmd)"`) e falha aberta nas
  outras — está no `TODO.md`, com a reprodução.

## Ao mexer nos agentes (`agents/*.md`)

- São markdown aberto com frontmatter compatível com `.claude/agents/`: portável para outros
  harnesses. Não acople a nenhuma API do Claude Code que não seja o próprio arquivo.
- Um agente = uma "troca de chapéu". Se você está adicionando uma sétima responsabilidade a um
  agente existente, provavelmente é um agente novo — ou não é responsabilidade de agente nenhum.
- O agente descreve **o que produzir e onde**, com o formato exato do artefato. Quem julga se
  ficou bom é o gate, não o texto do prompt.
- **Mexeu num `agents/*.md`? Quem sincroniza o espelho é `sdd install --force` — nunca `cp`, nunca
  Edit.** O harness carrega a **cópia** em `.claude/agents/`, jamais a fonte do kit, e trata
  `.claude/` como caminho sensível: em sessão headless as duas ferramentas levam negativa e a fase
  parece travada, com o `sdd preflight` vermelho em `agent <nome> stale` (`bin/sdd:1649`).
  `sdd install` sozinho mostra o diff antes; `--force` adota. Duas fases DOCS já queimaram sessão
  aqui porque a regra não dizia o comando.

## Commits

Pequenos, com o porquê no corpo. Convenção: `<tipo>(<escopo>): <o quê>` — `feat(runner)`,
`fix(qa)`, `docs(pipeline)`, `chore(config)`. Um incremento do plano = um ou poucos commits,
nunca um commit gigante no fim.

## TDD aqui dentro

O kit é bash + markdown, então o "teste" é o **Check** de cada incremento do plano: um comando
com resultado esperado. Escreva o Check antes de implementar o incremento.
⚠️ Check que lê a saída de um sensor ancora em `^  ok    ` e **nunca** leva `|` na célula — as duas
regras estão em `templates/checkpoint.md`, com o porquê medido, e quem as cobra é
`tests/check-checkpoint.sh`.

A suíte é `tests/run-all.sh` — é ela o `TEST_CMD` deste repo, e é ela que os gates rodam. Sensor
novo entra lá. Os treze de hoje: `check-templates.sh`, `check-gates.sh`, `check-dry-run.sh`,
`check-mutation.sh`, `check-lang.sh`, `check-autonomy.sh`, `check-kaizen.sh`, `check-preflight.sh`,
`check-todo.sh`, `check-pipefail.sh`, `check-entrypoint.sh`, `check-checkpoint.sh` e
`check-health.sh`.

⚠️ **Doze dos treze rodam no `TEST_CMD`; o `check-mutation.sh` é opt-in desde `4c86712`.** Ele
verifica CADA mutante rodando a suíte inteira numa sandbox, e isso segurava a árvore por mais de
dez minutos por gate — até tornar uma FASE insatisfazível: três sessões de REVIEW seguidas
encerraram o turno com as palavras *"waiting for the suite"*, e em `claude -p` encerrar o turno é
encerrar a sessão. Hoje o catálogo mora no `sdd health`, pelo mesmo argumento que já vale para a
catraca do backlog. **Nada foi afrouxado** — muda quem cobra e quando: os gates fazem a pergunta
rápida, `sdd health --with-mutation` faz a cara.

⚠️ **A lacuna que o opt-in abriu está fechada desde `c962e2e`, e não por CI — por artefato.** Ela
era real e cobrou: entre os PRs #12 e #13 um conserto apodreceu a âncora de um mutante, os gates de
REVIEW e de PR rodaram a suíte rápida, responderam verde, e a `main` carregou
`score: 103 caught of 104` por dias até alguém digitar o comando. Hoje o `sdd health` **carimba**
quando o catálogo volta verde, e o `gate_PR` **exige o carimbo**; o gate nunca roda o catálogo, que
é exatamente o que `4c86712` desfez. Verbete "Carimbo de mutação" no `CONTEXT.md`, desenho e
alternativas descartadas em [`docs/adr/0004`](docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md).
⚠️ **Consequência operacional que custa 20 a 50 min quando se erra a ordem:** a chave é o conteúdo
de `bin/ tests/ templates/ config/`, então `./bin/sdd health` roda **depois do último commit de
código**. `CLAUDE.md`, `CONTEXT.md`, `docs/` e `TODO.md` não invalidam — mas
`tests/health-baseline.txt` invalida, e é lá que a catraca do backlog mora, então registrar achado
(princípio 5) mata o carimbo. A colisão está no `TODO.md`; o sintoma e a saída, em
[`docs/failure-modes.md`](docs/failure-modes.md).

`sdd preflight`, `bash -n bin/sdd` e os dry-runs completam, mas não substituem. O passo de lint do
`run-all.sh` cobre `bin/sdd` **e** `tests/*.sh` — deixar a suíte fora do linter foi o que segurou
dois SC2318 reais em `check-mutation.sh` por três missões.

⚠️ **"Entra lá" são quatro lugares, não um — e o quarto arrasta um quinto.** Medido ao acrescentar
o `check-health.sh`: a linha `run` do `tests/run-all.sh`, o `LINT_FLOOR` do mesmo arquivo, o piso
de superfície do `tests/check-pipefail.sh` e o do `tests/check-lang.sh`. Os três pisos existem
contra vacuidade — glob que para de casar deixa o laço sem nada para ler e o sensor reporta "0
violações" —, então piso que ficou para trás continua **passando** enquanto descreve uma superfície
menor do que a que lê. O quinto lugar é o **fixture do selftest** do `check-pipefail.sh`, construído
exatamente no piso: deixá-lo um curto fez três probes falharem com `surface shrank` em vez de
medirem o que nomeiam.

**Sensor que o catálogo de mutação não alcança carrega um auto-teste.** São duas situações, e
hoje há **cinco** sensores nelas. `check-lang.sh` e `check-pipefail.sh` não podem se escanear (o
dicionário de um É português; as probes do outro TÊM de conter o que ele detecta). `check-todo.sh`,
`check-checkpoint.sh` e `check-templates.sh` medem markdown, não o `bin/sdd`, então nenhuma
sabotagem do runner os faria morrer — `check-pipefail.sh` está nas duas situações, porque também
mede `tests/`. Onde a regra está paga quem mede o sensor é um `selftest()` com probes e rc
próprios — 90, 91, 92 — mais um piso contra vacuidade. Sem isso, regex quebrada reporta "tudo
limpo" para sempre.
⚠️ **Os cinco pagam — o último a pagar foi o `check-templates.sh`, em `6aa2a16`.** Por duas
missões ele foi a exceção declarada: no lugar do auto-teste tinha o `REVIEW_FLOOR` mais uma passada
adversarial nomeada no cabeçalho, e a r2 de `20260818-lote-facil` mediu quanto isso valia — o piso
contava **chamadas**, então uma linha apagada o fazia certificar um `templates/review.md` de zero
byte com `23 assertion(s)` e `template contract intact`. Mover a contagem para dentro do `check()`
não bastava: move a tartaruga uma casca para fora, porque um `check()` sem o `grep` conta igual.
Quem fechou foi o **controle negativo** — rodar a primitiva de asserção contra um mundo de resposta
conhecida e exigir que ela a diga. O `REVIEW_FLOOR=23` continua lá, agora como piso e não como
álibi. Sensor sem auto-teste que declara o buraco é dívida; sensor sem auto-teste que jura estar
coberto é o fail-open que esta seção inteira existe para impedir.
⚠️ A rubrica é "a mutação não alcança", **não** "tem `selftest()`": `grep -l '^selftest()' tests/*`
hoje devolve **seis** — os cinco acima mais o `check-entrypoint.sh`, que carrega um por escolha
própria (o catálogo o alcança via `mut_RUN_entrypoint_unguarded`, mas o parser dele é fino demais
para depender só disso). Sensor a mais com auto-teste nunca é o defeito; sensor **sem** ele, estando
nas duas situações, é.
⚠️ A âncora `^selftest()` **é** o instrumento; `selftest` solto responde **sete**, somando o
`jobs_selftest()` do escalonador (`tests/check-mutation.sh:63`), que mede o pool de jobs e não
regra de sensor nenhuma. Número em rubrica sem o comando ao lado é a mesma classe do
`44 caught of 44` que já venceu neste arquivo — conte a propriedade, não a palavra.

⚠️ **O selftest tem de exercitar o CAMINHO, não só a função.** Achado consertando o
`check-todo.sh`: os probes provavam que o parser pulava blocos cercados, e mesmo assim trocar a
contagem por um `grep` no chamador passava verde — porque nenhum probe rodava o caminho de
reporte. A saída foi um modo `--check <arquivo>` que o próprio selftest invoca, sem recursão.

⚠️ **Essa regra escrita não bastou: três fail-open passaram por cima dela** — r2 da missão
`20260816-kit-como-alvo`, num sensor criado para caçar exatamente isso. Os probes mediam o
**parser**; o caminho de "existe defeito" até "a suíte fica vermelha" não tinha probe nenhum
(`probe()` gritava `SENSOR-BROKEN` cinco vezes e saía `0`; apagar as chamadas de topo deixava tudo
verde). A passada de sabotagem cobre **três** camadas — parser, contabilidade da falha e
composição —, e a composição só é sondável se as chamadas de topo forem uma **lista**, que é o que
um probe consegue contar. O que sobra é a última linha do sensor, sobre a qual ele não consegue
asseverar: essa se prova pelo **catálogo de mutação medido nos dois sentidos** (íntegro
`N caught of N` × neutralizado `N-1 caught` + rc 1), nunca por comentário. `N` era 44 quando o
sensor nasceu e cresce a cada missão — o número de hoje sai da linha `score:` do `run-all.sh`, e
fixá-lo aqui era uma data de validade escrita à mão. Detalhe no cabeçalho do
`tests/check-entrypoint.sh`.

⚠️ **Selftest verde prova as regras que têm probe, e só essas.** Sensor novo ganha uma passada de
**sabotagem adversarial** antes de ser considerado pronto: degrade cada regra para uma versão mais
frouxa (a data virando "qualquer parêntese", o título virando "`**` em qualquer lugar", a âncora
virando "crase em qualquer lugar") e exija que o selftest fique vermelho em cada uma. O que passar
é regra sem probe. No `check-todo.sh` isso achou 17 defeitos depois de a auto-revisão ter dado
Grade A, dois deles **falhando abertos** — o pior modo possível num sensor, porque ele afirma ter
medido o que não mediu. Regra que a sabotagem não consegue quebrar de forma alguma é redundante:
remova, não escreva probe para ela.

⚠️ **Esse corolário tem contra-exemplo medido, e ele custou uma regressão — escreva o probe ANTES
de apagar a regra.** Duas regras foram removidas da `kit_guard_check` com esse argumento em
`d4deb35`. Uma delas era o early-return de `DRY_RUN`, apagado com a frase *"no sabotage of a
DRY_RUN guard could have made a probe [red]"* escrita no próprio comentário que ocupou o lugar
dele. O probe existe, tem quatro linhas, e fica vermelho: armar a guarda numa projeção fazia
`sdd run --dry-run` herdar o aviso de ledger do `autonomy_kit_stamp` — 1 aviso contra 0 na versão
anterior. A revisão do mesmo PR (#22) desfez a remoção em `7cbc8e2`, agora no `kit_guard_arm`. (A
outra, a guarda de kit-não-git, resistiu a duas tentativas de quebra e continua fora — o corolário
não está errado, está **condicionado**.) *"Não consegui construir o mundo em que a regra importa"*
e *"esse mundo não existe"* são afirmações diferentes, e o comentário escreveu a segunda — a mesma
régua que este arquivo já aplica a *"comentário que afirma paridade não é paridade"*. Se o probe
não sair, diga no comentário **qual mundo você não conseguiu construir**, nunca que ele não existe;
e regra que sobrevive por ser inalcançável hoje, mas que decide **qual falha** o defeito produz,
fica com a ausência de probe declarada no cabeçalho, pela régua de admissão do D15.

⚠️ **O probe de sabotagem prova primeiro que sabotou o que dizia sabotar.** Duas rodadas desta casa
concluíram "sobrevive" sem ter testado a regra: uma ancorada em número de linha (apagou a linha
vizinha e deixou viva a que o `grep` procura), outra com `perl -0pe 's/…//m'` **sem `/g`**, que casa
a primeira ocorrência do ARQUIVO — os probes removiam a chamada de `cmd_preflight` e concluíam
sobre a de `cmd_approve`. Quatro conclusões falsas quase viraram asserção. Ancore em CÓDIGO e faça
o probe **morrer alto** quando o trecho que ele esperava mudar não mudou; conclusão de probe vazio
não vale, nem quando aponta para o lado certo por acaso. Medido na missão
`20260816-portas-do-humano` (F1 e F2) — detalhe nas notas do `checkpoint.md` dela.

⚠️ **A revisão é laço, e o critério de parada é uma rodada que não acha nada.** No `check-todo.sh`
foram cinco: 17, 9, 11 e 11 achados, e **três vezes seguidas o conserto de uma rodada criou o
defeito que a seguinte encontrou**. Quando isso acontece duas vezes na mesma vizinhança, pare de
remendar e pergunte **que estado está faltando** — ali a resposta era "o parser não sabe quando
está dentro do bloco de código de um item", e um estado novo fechou de uma vez quatro defeitos que
pareciam separados. Sintoma consertado individualmente vira o próximo sintoma.

**Fixture que imita saída de skill de terceiro é copiado da fonte**, com o caminho no comentário
de proveniência — nunca escrito de memória. Três bugs de gate nasceram de fixture imaginado:
gate e fixture tinham o mesmo autor e a mesma suposição, então a suíte verde *confirmava* a
suposição em vez de medi-la, e fixture errado passa verde para sempre. `sdd health` confere a
proveniência contra as skills instaladas.

**Gate novo entra com mutação** em `tests/check-mutation.sh` — `sdd health` reprova gate sem
mutação no catálogo. Sabotar o gate e exigir que a suíte morra é o que prova que a asserção
mede alguma coisa; sem isso não há como distinguir asserção viva de decoração.

**Red observado não basta: tem de ser vermelho pelo motivo certo.** A missão
`20260815-ledger-sem-ponto-cego` achou **cinco** asserções que passavam pelo regime do fixture e
não pela propriedade — e a quinta *afirmava a decisão errada* em vez de só deixar de medir, que é
o modo caro. Três perguntas antes de aceitar um verde:

- o `rc` (ou o prefixo da mensagem) que a asserção lê é **compartilhado** com outro ramo? Ela não
  distingue nada. Exija o texto do ramo certo **e a ausência** do marcador do outro;
- a propriedade é universal mas o fixture só anda num regime? Ponha o fixture no regime que
  **repete** e acrescente uma testemunha dele (contar quantas vezes o ramo foi entrado);
- a alegação é "X responde igual a Y"? Escreva a asserção **diferencial**: dois fixtures, saídas
  comparadas entre si. O par `degraded`/`blocked` do `tests/check-kaizen.sh` é o exemplo — nenhum
  regime de fixture a satisfaz por acidente, e ela reprova qualquer que seja o lado que mexeu.

⚠️ Este arquivo roda com `set -o pipefail`: `printf … | grep -q` devolve **141** quando o grep
ACHA e sai antes de o printf terminar de escrever (SIGPIPE). A lógica fica invertida em entrada
grande e correta em entrada pequena — o pior dos dois mundos. Use herestring (`<<< "$var"`).
⚠️ **`grep -m<N>` sem flag quiet é a MESMA família e desde `20260818-lote-facil` também é cobrada**
— RULE 3 (`rule:`) do `check-pipefail.sh`. Ele sai cedo pelo mesmo motivo, e a fronteira é de uma
tecla: `grep -m 1 -q x` já era medido pela RULE 1, `grep -m 1 x` não era. Regra que chega com
violação não convertida chega vermelha: a única instância viva foi convertida no mesmo commit.

⚠️ Mesma família: um comentário `#` **dentro** de um bloco continuado por `\` quebra o comando em
silêncio, e `bash -n` não acusa — achado escrevendo os construtores `jq -cn \` do ledger de
autonomia (I13.1). Comente antes do bloco `\`-continuado ou depois dele, nunca no meio.

⚠️ Mesma família de novo: **função lida como `x="$(f)"` roda num subshell**, então qualquer
atribuição a global que ela faça morre com a substituição de comando — e `bash -n` também não
acusa. Custou a guarda one-shot de `autonomy_kit_stamp`, que avisava a cada linha do ledger
enquanto o comentário jurava "one-shot per process". Função que tem efeito colateral em global
**publica** o resultado num global (como `run_phase` faz com `LAST_PHASE_*`) e é **chamada**, nunca
substituída. Se você precisa dos dois — valor de retorno e efeito —, é sinal de que são duas
funções.

⚠️ **O `awk` desta máquina é o `mawk`, e ele é orientado a BYTE em qualquer locale.** Uma classe
negada com caractere multibyte — `[^—]`, `[^á]` — não nega o caractere: nega os **bytes** dele.
Como toda a faixa U+2000..U+2FFF começa com `0xE2` (aspas curvas, reticências, en-dash, bullet,
setas), uma aspa curva na entrada faz a classe casar onde não devia e o `sub()` falhar em
silêncio. Custou o `head_of()` do `check-todo.sh`, que degradou para a regra frouxa e passou a
**falhar aberto** em pontuação corriqueira. Para separador literal use `index()`/`substr()`, que
também são byte-based mas consistentemente; classe negada, só com ASCII. `bash -n` não acusa, o
`shellcheck` não acusa, e o teste passa enquanto a entrada for pura ASCII — que é o pior dos
mundos, porque a entrada real vira multibyte no dia em que alguém escrever bem.

⚠️ **`cd` com operando relativo dentro de `$(...)` leva `CDPATH=''`, sempre.** O bash procura o
operando no `$CDPATH` quando ele não começa por `/`, `.` ou `..` — e, quando acha por lá, **imprime
o diretório resolvido na stdout**, direto para dentro da substituição de comando. Custou a CRITICAL
da r2 de `20260817-eixo-do-juiz`: `ledger_repo_root` resolvia `git rev-parse --git-common-dir`, que
devolve o relativo `.git` na raiz de um checkout, e com `CDPATH=$HOME` sendo o $HOME um checkout de
dotfiles **todos os repos da máquina colapsavam numa identidade só** — escritor e leitores
concordando nela, `other_repo: 0`, nada excluído, nada dito: a contaminação silenciosa que a função
existe para impedir, alcançável por variável de ambiente. `CDPATH=.` sozinho já acrescentava uma
segunda **linha** à resposta, metendo um `\n` no campo `repo` do ledger.
`bash -n` não acusa, o `shellcheck` não acusa, e o teste passa enquanto quem roda tiver `CDPATH`
vazio — que é a máquina de todo mundo até não ser.

⚠️ **Consertar a função não fecha a classe; o que fecha é o scanner.** Em `20260818-lote-facil` a
mesma grafia estava viva em **dezenove** sítios — os `ROOT=`/`SELF_PATH=` de `tests/` e dois no
`_resolve_self` do `bin/sdd`, que resolve o `SDD_HOME` de onde saem template, agente e starter
config. O item do backlog contava 14; a contagem de hoje sai de
`grep -h "CDPATH='' cd" bin/sdd tests/*.sh`, nunca daqui. Quem cobra é a **RULE 2 (`cdpath:`)
do `tests/check-pipefail.sh`**, que varre `bin/` e `tests/` linha a linha, mais os pares
diferenciais do `check-autonomy.sh` — que carregam um **piso provando que o veneno está ARMADO**
no shell antes de concluir qualquer coisa, porque regra de ambiente sem veneno armado é decoração.
Limites declarados no comentário do `CD_RE`: operando **variável** é indecidível num scanner de
linha (medido em runtime pelo par diferencial), e `pushd` tem o mesmo bug e está no `TODO.md`.

⚠️ **Recusar a forma é metade do conserto; a outra metade é RESOLVER.** Segunda parte da mesma
história, e o modo caro. `ledger_repo_root` hoje pede `git rev-parse --path-format=absolute
--git-common-dir` (2.31+) e dispensa `cd` no caminho rápido — mas `git rev-parse` **ecoa de volta**
uma opção que não conhece e ainda sai 0, então um git velho responde duas linhas. A guarda que
recusou essa forma **devolvia vazio**, e vazio é o contrato de "não é um repo": em git 2.25/2.30
toda linha viraria `repo: ""`, todo leitor a arquivaria em `no_repo` — balde que `--all-repos`
deliberadamente não admite —, e isso é **estritamente pior** que a grafia anterior, que respondia
certo nesses mesmos gits. Ramo de recusa que devolve o sentinela de outro significado é um segundo
defeito com a roupa do primeiro. A grafia antiga voltou como **fallback**, segura agora pelas
guardas de `CDPATH` acima; e a asserção mudou de "o git velho fica calado" para **acordo** — os
dois gits comparados um com o outro. Detalhe em `docs/handoffs/20260818-lote-facil/40-review-r2.md`.

## Kaizen

Melhoria com antes/depois **medido** vai para o [`KAIZEN_LOG.md`](KAIZEN_LOG.md). Sem número,
não é kaizen — é opinião.

## Graphify — grafo de conhecimento (consultas estruturais)

Para pergunta **estrutural** sobre o `bin/sdd` e os sensores — quem define X, quem chama X
**diretamente**, o raio direto de uma mudança — consulte o grafo antes do grep, **só dentro da
zona medida**. Para bash o extrator vê definições de função e chamadas escritas como statement
(`f args`, `if f; then`, `f || rc=$?`). **Não vê**: `$(f)` (substituição de comando — é como
`gate_REVIEW` lê `review_rounds_on_disk` e como `run_phase` lê `phase_model`: 0 de 4 e 0 de 1
chamadores), despacho dinâmico (`gate_"$phase"`, os 4 sítios que chamam todo gate), e colapsa N
sítios do mesmo par em **uma** aresta — logo **nunca responde censo de portas**: os `grep -cE`
deste arquivo continuam sendo o instrumento. Docs estão indexados, mas `query` é ruidoso (5 KB e
2 de 6 arquivos numa pergunta sobre `BUDGET_REVIEW_USD`); grep dirigido ganha. Medido em
2026-09-01 sobre 11 perguntas reais — zona, runbook e ledger pareado em
[`docs/graphify.md`](docs/graphify.md).

```bash
graphify explain "run_phase"                              # 1ª escolha p/ símbolo conhecido (~20 linhas; recusa ambíguo)
graphify affected "run_phase" --relation calls --depth 1  # quem chama X DIRETAMENTE (funções, não sítios)
graphify god-nodes --top 10                               # orientação; aqui os hubs são docs e sensores
graphify update .                                         # rebuild (~1 s, honra .graphifyignore, zero API)
```

- Binário isolado em `~/.local/bin/graphify` (0.9.48). `graphify-out/` é **gerado** e está no
  `.gitignore` inteiro; `.graphifyignore` é versionado e define o escopo (código + docs de
  arquitetura; handoffs, `docs/qa/`, `TODO.md` e `KAIZEN_LOG.md` ficam fora de propósito — uma
  rodada de review de 2026-08-17 passou na frente do `config/schema.md` quando entravam).
- Sem hooks de git (rebuild manual de 1 s). **Nunca** `graphify extract --mode deep` nem
  `graphify label` — consomem API. Subcomando não tem `--help` (`query --help` executa a pergunta
  literal `"--help"`).
- Lição de **uso** (grafo × grep) vira linha pareada no ledger de `docs/graphify.md`; lição sobre a
  **ferramenta** vai por retrofit lean para a skill viva `graphify` do `sales_quote`, onde ela mora.
