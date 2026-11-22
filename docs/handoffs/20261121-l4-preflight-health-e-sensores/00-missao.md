---
missao: 20261121-l4-preflight-health-e-sensores
titulo: O preflight mede o que afirma, o sdd run para antes da sessão que será negada, e quatro sensores fecham o que deixavam passar
data: 2026-11-21
versao:
branch: fix/l4-preflight-health-e-sensores
aprovacao: humano-2026-11-21
adr: none
ddd: n/a
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L4
---

# Missão — L4: preflight, health e sensores

> Escrito pelo `sdd-planner`, com o grill respondido por delegação escrita do dono (veja "Decisões
> do grill"). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão
> headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` do kit tem 91 achados abertos em `a0004df` (`bash tests/check-todo.sh --count TODO.md`
→ `91`), e a campanha `20261117-zerar-as-issues` os reparte em lotes. Este é o **L4**: os 15 que
falam do `sdd preflight`, do que o `sdd run` confere antes de gastar, e de quatro sensores
(`check-health.sh`, `check-todo.sh`, `check-checkpoint.sh` e a guarda do chapéu no `sdd kaizen`).
O traço comum: um instrumento diz `ok`, ou não diz nada, sobre uma coisa que não mediu, e o alvo
descobre numa corrida já paga.

Os 15, com o título exato do item (é a chave do espelho de issues, **nunca** se muda), a linha do
`TODO.md` e a âncora medidas em `a0004df`, e o incremento que o fecha:

| # | Título do item no `TODO.md` | Linha | Âncora | Incremento |
|---|---|---|---|---|
| 1 ◆ | O `sdd preflight` não mede a forma do `TODO_FILE`, e nada avisa o alvo sem o opt-in | 40 | `bin/sdd:6926` | I4 |
| 2 | Nada avisa que o clone do kit está velho ou fora da `main` | 48 | `bin/sdd:4167` | I8 |
| 3 | O `sdd preflight` diz "preflight ok" com um `TEST_CMD` que deixa servidor vivo | 56 | `bin/sdd-coordination.py:359` | I7 |
| 4 | O `writes:` do `sdd-kaizen` não é cobrado: o `cmd_kaizen` não passa pela guarda do chapéu | 73 | `agents/sdd-kaizen.md:11` | I9 |
| 5 | O `atualizado:` do checkpoint aceita hora inventada, até no futuro | 81 | `tests/check-checkpoint.sh:1573` | I10 |
| 6 | A sonda do `Bash` do `sdd preflight` dá `ok` pela resposta, nunca pelo comando rodado | 88 | `bin/sdd:6660` | I2 |
| 7 ◆ | O `sdd run` paga a REVIEW sem avisar que o `READ_EXTRA` não cobre o `codereview` | 95 | `bin/sdd:7033` | I6 |
| 8 | A sonda de interrupção do `check-health.sh` mede o grupo antes do `setsid`, e a suíte cai sem defeito | 104 | `tests/check-health.sh:1868` | I11 |
| 9 | `PR #N` de outro repositório passa pelo `check-todo.sh` e vira link errado na issue | 121 | `tests/check-todo.sh:815` | I12 |
| 10 ◆ | O cabeçalho do `TODO.md` semeado pelo `install` não acompanha o template | 130 | `bin/sdd:6300` | I5 |
| 11 | O `sdd preflight` reprova a árvore suja sem dizer os caminhos, nem que eram só não versionados | 476 | `bin/sdd:7155` | I1 |
| 12 | O `sdd preflight` imprime "printf: erro de escrita: Pipe quebrado" com a `READ_EXTRA` preenchida | 537 | `bin/sdd:5867` | I1 |
| 13 | O lint da suíte se pula sem o `shellcheck`, e a `main` já tem 4 avisos que ele reprova | 613 | `tests/run-all.sh:294` | I7 |
| 14 | O `sdd run` num worktree do alvo manda `install --force`, e o que falta é o `link-agents` | 621 | `bin/sdd:5522` | I8 |
| 15 | O `sdd preflight` não olha os hooks que toda fase carrega, e só avisa da skill que a fase usa | 702 | `bin/sdd:6546` | I3 |

O que cada um custou está no corpo do item (`grep -n -F '<título>' TODO.md`). O item 7 voltou duas
vezes no próprio kit (linha `RECURRED 2`). Do item 13, a metade "a `main` já tem 4 avisos" já
fechou em `3f96448` (o `shellcheck -S warning` da superfície sai rc 0 em `a0004df`); sobra o aviso
do preflight sem o linter.

## Métrica

Fato binário, medido no worktree da missão com todos os incrementos `done`:

1. as 41 frases de asserção do `01-plano.md` aparecem com `  ok    ` nos seus sensores (os Checks
   I1 a I12 do `checkpoint.md`, cada um com o valor esperado);
2. os 31 mutantes novos existem no catálogo, e cada um foi pego por `--only <slug> <sensor>` antes
   do commit do seu incremento (anotado nas notas);
3. `tests/run-all.sh` → `suite green`, rc 0;
4. os 15 itens da tabela carregam `RESOLVED by <hash>` no `TODO.md` (Check I13 → `15`).

## Resultado esperado

O `sdd preflight` deixa de afirmar o que não mediu: a sonda do `Bash` dá `ok` pelo `tool_result`
do comando, lista os hooks que toda fase carrega, reprova a skill que o harness não carregou, mede
a forma e o cabeçalho do `TODO_FILE`, nomeia os caminhos da árvore suja e o processo que o
`TEST_CMD` deixou vivo, e não imprime erro de escrita num veredito verde. O `sdd run` e o
`sdd retry` param antes de qualquer sessão quando a skill de uma fase está num diretório que
nenhuma regra de leitura cobre, e avisam do clone velho do kit e do worktree sem o espelho dos
chapéus com o remédio certo. O juiz do `sdd kaizen` passa pela guarda do chapéu. O
`check-checkpoint.sh` recusa `atualizado:` no futuro, o `check-todo.sh` recusa `PR #N` sem rastro
no histórico, e a sonda de interrupção do `check-health.sh` deixa de cair por corrida.

## Fora de escopo

- O catálogo de mutação inteiro (`./bin/sdd health`) e o carimbo: o PR de missão do kit mergeia sem
  carimbo, por regra do dono.
- `tests/health-baseline.txt`: a catraca desce no chore de depois do merge, que apaga os 15 itens.
- `CLAUDE.md` e `.claude/rules/anatomia-do-agente.md`: a sessão headless não os edita; a DOCS
  propõe o texto em linhas `⛔` (pendência 3).
- A sonda dos templates do preflight, o `sdd close` e o `sdd kaizen` não ganham a parada da skill
  (decisão 3 fala de `sdd run` e `sdd retry`).
- `issue #N` de outro repositório no `TODO.md`: não deixa rastro no histórico, fica como limite
  declarado no cabeçalho do `check-todo.sh` (decisão 5).
- A duração de cada hook e os hooks que não disparam na sessão da sonda (decisão 6).
- O número de ADR que duas branches recebem iguais é item `◆` de outro lote.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 9 decisões abaixo, cada uma com a resposta entregue pelo relay; nenhuma pergunta pendente |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | lido incremento a incremento contra a lista "só se souber X" (fim do `01-plano.md`, "Teste de autocontenção") |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 13 linhas; `--check` rc 0 e `--red` rc 0 em `a0004df`, em duas corridas `--only` que cobrem as 13 (saída em `01-plano.md`, "O vermelho medido") |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`, decisão 8 |

`aprovacao:` fica vazio: quem fecha é o `sdd approve` (sob o worker, o ato `approve`).

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 15 itens lidos no código de `a0004df`; o ruído do pipe reproduzido com as funções reais; um stream real da sonda do `Bash` capturado (Claude Code 2.1.327); a marca de ambiente achada em `/proc`. Tudo em "Contexto verificado", com o comando |
| K2 | Problema declarado com métrica | ✅ | 41 frases com `ok`, 31 mutantes pegos, suíte verde, 15 `RESOLVED by` |
| K3 | Desperdícios identificados e cortados | ✅ | Sem sensor novo (as asserções entram nos sensores que existem); sem token novo de contrato no `TODO.md` (decisão 4); sem ADR e sem colisão de número com o L3 (decisão 8); a metade já fechada do item 13 não vira trabalho |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 13 incrementos, um ou dois itens cada, um commit cada, Red numa frase |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check ancora em `^  ok    ` do sensor; o `--red` mediu os 13 vermelhos no HEAD |
| K6 | Jidoka — o que para a linha está definido | ✅ | Mutante que o `--only` não pega = incremento não fecha; `CHECKOUT-BUSY` = `blocked`; suíte vermelha antes do commit = não commita |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Poka-yoke primeiro: parada no runner, asserção e mutante; prosa só no chapéu do juiz, em `docs/failure-modes.md`, `config/schema.md` e nos templates do `TODO.md` |
| K8 | Registro no KAIZEN_LOG | ✅ | A DOCS escreve a entrada com o id inteiro da missão (`kaizen_log:` vazio) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: o lote muda sondas, avisos e paradas do runner e regras de quatro sensores; nenhum agregado, evento, entidade ou contrato entre módulos nasce ou muda de forma.`

## Decisões do grill (não re-litigar)

Todas as respostas abaixo foram **delegadas por escrito** pelo dono (assinatura do `delegation.md`
da campanha, nível `full`, e a ordem de responder o grill pela opção recomendada). O relay as
entregou pelo texto da opção; **o dono não as viu na hora**. O aceite dele vem pelo corpo do PR
(pendência 2).

1. **Id `20261121-l4-preflight-health-e-sensores`, branch `fix/l4-preflight-health-e-sensores`.**
   É o título do lote na tabela da campanha, no padrão dos L2 e L3, e o `next` acha a missão pelo
   `lot:`. Uma missão só para os 15: partir o lote o daria por feito no primeiro merge.
   - answer: (recommended)
2. **(◆ item 1) O preflight roda sozinho `check-todo.sh --check "$TODO_FILE" --allow-empty`,
   sempre.** Limpo dá `ok`; com violação dá `warn` com a contagem, e nomeia a linha do opt-in com
   `--baseline` quando o `TEST_CMD` não a tem. Nunca `_fail`: `sales_quote` e `lighthouse_project`
   herdaram 209 e 127 violações, e ficariam com o preflight vermelho até uma faxina.
   - answer: (recommended)
3. **(◆ item 7) Uma função só faz a busca das skills, para o preflight e para o `sdd run`. No
   lançamento do `sdd run` e do `sdd retry`, antes de qualquer sessão, skill achada num diretório
   que nenhuma regra cobre, ou instalação de plugin quebrada, para com `die`, nomeando a entrada do
   `READ_EXTRA`.** Na `--dry-run` só avisa. Skill não achada só avisa (as raízes são convenção), e
   diretório cujo alvo a gramática recusa também (nenhuma entrada o alcança, a parada não teria
   saída). Porquê: o aviso do preflight não foi lido três vezes, e a REVIEW custou US$ 5,61 com
   3 de 5 agentes parados. O precedente é o `die` do chapéu não instalado, no mesmo lugar.
   - answer: (recommended)
4. **(◆ item 10) O preâmbulo do `TODO_FILE` (até o marcador `<!-- sdd:open -->`) é comparado com o
   de cada revisão do template do idioma no git do kit.** Igual ao de hoje: `ok`. Igual a uma
   revisão antiga: `warn` com a revisão, a data e o `diff` a rodar, sem reescrever. Igual a
   nenhuma: preâmbulo de autor, uma linha neutra. Uma função só, no `sdd preflight` e no braço
   `preserved` do `sdd install`. Porquê: comparar com o template de hoje avisaria para sempre em
   quem customizou (o `TODO.md` do próprio kit), e um carimbo de versão criaria um token de
   contrato e um número subido à mão. Limites declarados: preâmbulo antigo editado à mão fica
   calado; kit que não é checkout git não responde.
   - answer: (recommended)
5. **(item 9) Sob `--baseline`, um `PR #N` solto num item novo só passa se o histórico local tiver
   um commit cujo assunto cita `#N`.** Sem rastro, o `check-todo.sh` reprova e nomeia a saída
   `dono/repo#N`, que sempre passa. Os dois templates passam a dizer "deste repositório, já
   mergeado". Regra do dono cumprida antes de fixar a forma: a skill `todo-to-github-issues` foi
   lida, e o que ela diz está no `01-plano.md` ("O que a skill do espelho diz"). Consequência dela:
   o `PR #N` dentro de crase é isento, porque o GitHub não o liga. Limites declarados: `issue #N`
   fica fora; um `#N` de outro repo que coincide com um PR local passa.
   - answer: (recommended)
6. **(item 15) O preflight lê o stream da sonda do `Bash`, que já paga.** Uma linha por evento de
   hook (quantos, rc, bytes); `warn` pelo nome no hook com rc diferente de 0 ou `outcome` diferente
   de `success`; `_fail` na skill de uma fase que vai rodar e não está no `.skills` da linha
   `init`. A busca em diretórios fica só para a cobertura do `READ_EXTRA`. Sem `init`, nada é
   afirmado. Porquê: o dono pediu rc e bytes pela sonda, e o `.skills` é a resposta do harness, não
   a convenção de diretórios. O hook de rc diferente de 0 não reprova: rc 2 é a forma legítima de
   um hook bloquear.
   - answer: (recommended)
7. **(item 4) O `cmd_kaizen` ganha a guarda do chapéu nas duas sessões.** Arma antes, confere
   depois, e para com rc 3 (`hat-crossed`) pela `hat_crossed_escalation`, depois da linha de sessão
   do ledger. A guarda de kit fica fora: o juiz roda no próprio kit e escrever nele é o trabalho
   dele. Duas portas novas, um probe e um mutante por porta. O chapéu passa a nomear a base
   (`$TODO_FILE` e a catraca).
   - answer: (recommended)
8. **`adr: none`.** As decisões 3 e 6 mudam um `warn` para `die` e para `_fail`; reverter é uma
   linha. A DOCS acrescenta à ADR 0019 uma linha datada apontando esta missão. Não se cria colisão
   com o `0024` que o L3 reservou.
   - answer: (recommended)
9. **A suíte fixa a raiz das skills.** A parada da decisão 3 mataria todo `sdd run` de fixture numa
   máquina com o plugin `codereview` instalado, porque os sensores não isolam o `HOME` nem o
   `SDD_SKILLS_ROOT` (`grep -c 'SDD_SKILLS_ROOT' tests/*.sh` → só `check-preflight.sh`, 5). O
   arquivo que todo sensor já carrega, `tests/isolate-git.sh`, passa a exportar um
   `SDD_SKILLS_ROOT` vazio, com o cabeçalho dizendo as duas coisas que ele limpa. Um arquivo novo
   pediria editar os 17 sensores, o censo e três pisos.
   - answer: (recommended)

Decididas pelo planner como mecanismo, sem pergunta, e listadas para o aceite (pendência 2): a
marca no ambiente do `TEST_CMD` para achar o processo que sobrou (item 3); o aviso do clone velho
só no worktree principal do kit e só com `HEAD` num branch (item 2); o `atualizado:` no futuro
recusado no `--check` e na varredura da suíte (item 5).

## Pendências para o humano

1. **Antes do `sdd run`: o L3 mergeia primeiro.** O plano foi escrito sobre `a0004df`. O L3
   (`20261121-l3-gates-do-fim-da-linha`, em execução) mexe em arquivos que o L4 também mexe: o
   `bin/sdd` (a `run_check_cmd`, que o I7 daqui toca, e o laço do `cmd_run`, onde entram as paradas
   do I6 e os avisos do I8), `tests/check-mutation.sh` (a lista do catálogo), `tests/check-kaizen.sh`,
   `tests/check-autonomy.sh`, `tests/check-hat.sh`, `tests/check-todo.sh`, `tests/check-checkpoint.sh`,
   `tests/run-all.sh` e `docs/failure-modes.md`. Depois do merge do L3: `git merge origin/main`
   neste branch, `bash tests/check-todo.sh --anchors TODO.md` (`0 off target`),
   `tests/check-checkpoint.sh --check` e `--red` deste checkpoint de novo, e só então o `sdd run`,
   lançado neste worktree pelo `sdd` do PATH. As linhas da tabela acima (40 a 702) terão andado: o
   executor acha cada item pelo título.
2. **Para o corpo do PR, o aceite do dono sobre as escolhas feitas sem ele:** os três `◆`
   (decisões 2, 3 e 4) e as decisões 5, 6, 7, 8 e 9, mais os três mecanismos do planner (itens 3, 2
   e 5). A decisão 3 muda o comportamento de todo alvo (pendência 4).
3. **Texto do dono que o lote desatualiza, para as linhas `⛔` da DOCS:** no `CLAUDE.md`, o censo
   das portas (`13` → `15` na linha do `grep -cE … _escalation "\$phase"`) e a frase da
   `hat_crossed_escalation` ("QUATRO portas"); na `.claude/rules/anatomia-do-agente.md`, a §2 (a
   skill ausente deixa de ser só `warn`), a §4 (a sonda do `Bash` lê o `tool_result`; hooks; a
   forma do `TODO_FILE`), a §6 (a guarda do chapéu "em quatro sítios" passa a seis) e a §7 (a
   parada do `sdd run` sem sessão).
4. **Yokoten depois do merge:** todo alvo cujo `.sdd/config.sh` não declara a entrada do
   `codereview` no `READ_EXTRA` para no primeiro `sdd run`, com a linha a acrescentar na mensagem.
   Alvos a conferir: `sales_quote`, `lighthouse_project`, `warehouse`, `dotp-remake`, `ui24_agent`
   (o `magic_tutor` já a tem, `j0ruge/magic_tutor#104`).
5. **O carimbo:** o `sdd run` sai com rc 2 com o PR aberto e só o carimbo faltando; o PR de missão
   do kit mergeia sem ele, por regra do dono. O chore de depois do merge apaga os 15 itens e desce
   a catraca.
