---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
titulo: toda fase headless lê, só para leitura, os templates do kit que o boot manda ler; a leitura que o harness negou aparece no journal e reprova o preflight; e o projeto declara onde moram as skills de que as fases dependem
data: 2026-10-20
versao:
branch: kaizen/20261020-a-sessao-le-o-que-o-boot-manda
aprovacao: humano-2026-10-20
adr: docs/adr/0019-the-session-reads-what-the-boot-names.md
ddd: n/a
qa:
kaizen_log:
---

# Missão — a sessão lê o que o boot manda ler

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.
>
> ⚠️ **Plano nascido do `sdd kaizen`, replanejado com o humano.** Nasceu do laço `sdd kaizen` em
> 2026-10-20, do veredito `melhorou` sobre `bad6168` que está em `05-verdict.md`, ao lado, e passou
> pelo grill do `/sdd-plan` no mesmo dia, com o humano presente por relay (sete decisões, abaixo).
> `aprovacao:` fica vazio por regra: plano ao lado de um `05-verdict.md` nunca é `auto`
> (`plan_approves_itself`, `gate_PLAN`). O humano aprova com `sdd approve`.
>
> ⚠️ **Missão do kit.** Ela se executa de forma interativa no worktree ligado
> `/home/joruge/repos/sdd_agents-f9`, cortado da `origin/main` depois do merge do PR #302 (ADR 0016
> §2), na branch `kaizen/20261020-a-sessao-le-o-que-o-boot-manda`. Nunca por `sdd run` a partir do
> checkout principal, que é o `sdd` do PATH de todo alvo; dentro do worktree, `health`, `preflight`
> e `install` são `./bin/sdd`.

## Problema (Gemba)

**1. O boot manda ler um caminho que o runner não deixa abrir.** O item 6 do `boot_prompt` manda
toda fase partir do template em `$SDD_HOME/templates/` e "NEVER from memory" (`bin/sdd:3321`, a lista
sai de `phase_templates`, `bin/sdd:3181`). O `run_phase` lança a sessão com
`--permission-mode acceptEdits --allowedTools "$ALLOWED_TOOLS"` (`bin/sdd:5302-5310`), e o padrão é
`ALLOWED_TOOLS="Bash"` (`config/starter.conf:94`). Sob essas flags o `Read` fora do diretório do alvo
é **negado**. Reproduzido em 2026-10-20 às 11:41, num repo de rascunho, sem as settings do usuário,
em Claude Code 2.1.296: `Read /home/joruge/repos/sdd_agents/templates/handoff.md` respondeu `DENIED`,
com `permission_denials` nomeando o arquivo. Remedido no grill, em 2.1.304, com o mesmo resultado
(sonda p1 do `01-plano.md`).

**2. Três saídas, e nenhuma é a certa.** Lido no `permission_denials` dos logs de sessão da janela do
lote 7:
- **contornar pelo Bash**: no lighthouse, a sessão de TICKET leu os mesmos arquivos com `cat`. É a
  classe que a fronteira do chapéu pune quando o caminho é de escrita (ADR 0013);
- **trabalhar sem a referência**: a r1 da REVIEW do lighthouse teve 30 `Read` negados nas
  referências da skill `codereview` (das 40 da missão inteira). A do jrc-libs teve 14, em 2026-10-17;
- **parar**: o TICKET do jrc-libs (2026-10-16 20:17) se recusou a contornar e escreveu
  `status: blocked`. Foi a escalada `handoff-blocked` da fatia, 1 `refez`, 2 sessões fora de
  `advanced` e 1 intervenção. O operador destravou acrescentando `additionalDirectories` ao
  `~/.claude/settings.json` às 20:19:38.

No total, 13 dos 47 logs do lighthouse e 4 dos 23 do jrc-libs têm `Read` negado fora do repo,
sem contar os rascunhos sob `/tmp`. O `sales_quote` tem 0 de 33 só porque o
`.claude/settings.local.json` dele carrega `"Read(*)"`, posto à mão. Não é o harness novo: o
lighthouse já tinha essas negativas em 2.1.278 (7 sessões, 38 na `codereview`) e em 2.1.283 (3
sessões, 26). A REVIEW dele roda sem as referências da skill desde a primeira missão com log de
sessão, a `20260921-amep-backend-0-1-0`.

**3. A contagem existe e ninguém a lê.** O `hat_init_facts` publica `LAST_PHASE_DENIALS`
(`bin/sdd:5164`) e a linha de sessão do ledger carrega `denials`. Nenhum journal, nenhum `status` e
nenhum `preflight` diz **o que** foi negado. O `sdd preflight` responde "ok" nos três casos acima.
E uma sonda que só somasse a regra continuaria verde nesta máquina sem regra nenhuma: com as
settings do ambiente carregadas, o template é lido mesmo assim (sonda p4; o P2 do Codex no PR #302).

**4. As referências das skills moram fora do repo e do kit.** O `sdd-ticket` depende da `ticket`
(`~/.claude/skills/ticket/references/`), o `sdd-reviewer` da `codereview`
(`~/.claude/plugins/cache/<marketplace>/codereview/<versão>/skills/codereview/references/`) e as
sessões de QA das `qa-*`. O kit não sabe esses caminhos, que são do humano. O caminho do plugin muda
a cada versão: foi de `2.15.3` em 2026-10-15 para `2.17.0` em 2026-10-17.

## Métrica

- **Sonda de rascunho** (o comando exato está no `01-plano.md`, § Verificação end-to-end): com as
  flags que o `run_phase` passa e sem as settings do usuário, o `Read` de
  `$SDD_HOME/templates/handoff.md` vai de `DENIED` (hoje) a **lido**. A escrita no mesmo diretório
  continua **`DENIED`**.
- **Preflight desta máquina**: hoje ele responde verde sem regra nenhuma, porque o
  `additionalDirectories` do operador lista os templates (sonda p4 do `01-plano.md`). Depois da
  missão, a sessão isolada (decisão 3) fica **vermelha** com o `kit_read_rules` sabotado e verde com
  ele, nesta mesma máquina.
- **Suíte**: as linhas `ok` novas dos Checks I1–I6, cada uma com mutante no catálogo.
- **Próxima janela do juiz, no uso real**:
  - **0** `Read` negados em `$SDD_HOME/templates/` nos logs de sessão dos alvos (nesta janela foram
    6 no lighthouse e 2 no jrc-libs);
  - **0** TICKET `handoff-blocked` por leitura negada;
  - toda negativa restante **nomeada** no `pipeline.log` da missão.

## Resultado esperado

Toda sessão que o runner abre (fase, `sdd close` e a sonda do `sdd preflight`) recebe permissão de
**ler** o diretório de templates do kit, por uma regra só de leitura. Escrever lá continua negado,
e a guarda de kit continua parando a linha se alguém escrever. Cada `Read`, `Edit` ou `Write`
negado vira uma linha `DENIED` no journal da missão, que é o que o humano lê no `tail -F`. O
`sdd preflight` lê um template numa sessão própria, sem settings nenhuma, e fica vermelho quando a
regra do kit sozinha não basta. O projeto declara, na chave `READ_EXTRA` validada no `load_config`,
os diretórios de skill que as fases leem; cada um vira a mesma regra só de leitura, e um diretório
que é symlink ganha também a regra do alvo resolvido. O porquê de cada forma está na ADR 0019.

## Fora de escopo

- **A guarda de kit que para a corrida do alvo por um merge só de docs**, e **a REVIEW aprovada que
  não vê o código que entrou depois dela**. Os dois foram medidos nesta janela e entraram no
  `TODO.md` por um chore do relay, fora desta missão (decisão 4; PR #309, `b96f3d3`). O primeiro pede ADR própria (afrouxa uma
  parada); o segundo é o espelho do D21.
- **O `writes:` do `sdd-kaizen`**, que nenhuma guarda cobra e que o boot do juiz contradiz. Vai ao
  `TODO.md` pelo mesmo chore.
- Negativas sob `/tmp`, em rascunhos que a própria sessão criou pelo Bash: no jrc-libs, 3 leituras e
  4 escritas; no lighthouse, 1 leitura e 2 escritas. São da sessão, não do boot.
- Os 26 itens abertos do `TODO.md`: nenhum é o defeito desta missão, e o humano decidiu que zerar a
  catraca é um lote próprio, com `/sdd-plan` próprio, depois do merge da F9. A triagem está no
  `01-plano.md`.
- Um symlink **abaixo** de um diretório declarado no `READ_EXTRA` (e não o próprio diretório): o
  runner resolve só a entrada declarada. Limite escrito na ADR 0019.
- Desfazer o `additionalDirectories` posto à mão em 2026-10-16 e o `"Read(*)"` do `sales_quote`. É
  decisão do humano (Pendências).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | Grill de 2026-10-20 com o humano por relay, sete perguntas e sete decisões, todas respondidas (abaixo, sete linhas `- answer:`). Nenhuma pergunta aberta; o que fica depois do merge (as settings postas à mão, o yokoten, o carimbo) está em Pendências, com dono |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Testado de verdade em 2026-10-20 ~17:45, por uma sessão nova sem memória, só leitura, sobre os três arquivos: ela acharia o caminho do I1, e apontou o que faltava (a grafia das barras, como se escreve um mutante e o `CATALOG=(`, o `SDD_HOME` físico contra o `$ROOT` lógico do sensor, o rc do fixture que não distingue stubs, o `SDD_HOME` da sonda de captura, o `HARNESS_ENV_UNSET` da sessão nova, o `## Permissions` do `docs/pipeline.md`). Tudo foi escrito no `01-plano.md`; uma segunda passada (~17:55–18:01) respondeu "nothing blocking" e apontou miudezas (as flags `stream-json` da sessão nova, o caminho físico no `check-preflight.sh`, a negativa casada pelo caminho, o chore já mergeado), também escritas |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 6 de 6. `--check`: `6 row(s), 6 under the anchor rule, none blind`, rc 0. `--red` no HEAD `45a16a6`: rc 0, `6 pending Check(s), every one red at HEAD`, 10 min 45 s; o I6, reescrito pela decisão 7, remedido sozinho às 18:10: `I6 is red at HEAD (prints '0 0', wants '1 1')`, rc 0. Os valores de antes estão no `01-plano.md`, § O estado no HEAD |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh:49`); `versao:` vazio |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0019-the-session-reads-what-the-boot-names.md`, alocada por `./bin/sdd adr new` no worktree (decisão 5) e escrita no PLAN; `./bin/sdd adr check --mission 20261020-a-sessao-le-o-que-o-boot-manda --phase plan` → `that ADR points back`; `tests/check-lang.sh` rc 0 com ela no glob |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `permission_denials` de 70 logs de sessão em duas missões, os 33 do `sales_quote`, o reflog do kit, as sondas `claude -p` reais do kaizen em 2.1.296 (o veredito conta sete, a tabela do plano registra cinco) e mais 13 em 2.1.304 no grill (`01-plano.md`, § Contexto verificado) |
| K2 | Problema declarado com métrica | ✅ | Sonda de rascunho `DENIED` → lido; 6 + 2 negativas em templates → 0 |
| K3 | Desperdícios identificados e cortados | ✅ | Leitura contornada pelo Bash, 30 + 14 referências da REVIEW negadas, um TICKET parado e uma intervenção |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 6 incrementos, cada um com uma linha `ok` própria de um sensor (I3 e I5 com duas, juntadas por `echo`); a ADR saiu para o PLAN e os achados para um chore (decisões 4 e 5), e o `READ_EXTRA` se partiu em I5 (chave) e I6 (o aviso do preflight) pelo tamanho de sessão |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem a linha `ok` do sensor ancorada em `^  ok    `, nunca o texto solto |
| K6 | Jidoka — o que para a linha está definido | ✅ | O `sdd preflight` fica vermelho quando a regra do kit, sem settings, não lê o template (I3), e o `load_config` morre com `READ_EXTRA` inválido (I5) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | A anatomia §2 e §6, o `config/schema.md` e o `docs/failure-modes.md` mudam no mesmo commit do código |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio, decidido com o humano (decisão 6): a DOCS escreve a entrada com o antes e depois medidos, e o `gate_DOCS` a cobra |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio: a mudança são flags de permissão do harness, uma linha de journal, uma sonda de preflight e uma chave de config no runner bash.`

## Decisões do grill (não re-litigar)

O plano nasceu do `sdd kaizen` sem humano; o grill foi feito em 2026-10-20 pelo `/sdd-plan`, com
o humano presente por relay, e revisou os artefatos no lugar.

1. **A leitura dos templates é uma regra só de leitura, `Read(/$SDD_HOME/templates/**)`, somada
   pelo runner ao `--allowedTools`**, com uma definição (`kit_read_rules`) chamada nas três portas
   que montam um `claude -p`: `run_phase`, a sonda do `cmd_preflight` e o `cmd_close`. Na grafia
   literal o `$SDD_HOME` já começa por `/`: a regra é `Read(/` + o caminho + `/**)`, com duas barras
   (`Read(//home/…/templates/**)`), a forma medida; três barras nunca foram medidas. Porquê: é a
   única forma medida que libera ler sem liberar escrever; o `--add-dir` deixa a sessão escrever no
   kit sob `acceptEdits`, e a guarda de kit só age depois do fato.
   - answer: (recommended)
2. **Os diretórios das skills são do projeto, por uma chave `READ_EXTRA` de default vazio,
   validada no `load_config`, e é o runner que monta as regras.** Diretórios absolutos depois da
   expansão, escritos como `$HOME/…` no `.sdd/config.sh` do alvo (ou exportados no ambiente, como
   toda chave); o `load_config` morre com motivo diante de glob, `..`, quebra de linha ou caminho
   relativo. O `kit_read_rules` emite `Read(/<dir>/**)`, `<dir>` absoluto, e, quando `readlink -f <dir>` difere, a
   regra do alvo resolvido também. Diretório inexistente é `warn` do `sdd preflight`, nunca `die`.
   O kit não concede nada além dos próprios templates, e cada alvo declara as suas skills (yokoten
   no lighthouse e no jrc-libs). Porquê: o `.sdd/config.sh` é rastreado nos alvos, então `$HOME`
   mantém o arquivo neutro quanto ao usuário; o harness confere o caminho pedido **e** o resolvido
   (p7, p10, p12), e só quem constrói a regra resolve o symlink; um plugin ausente noutra máquina
   não pode parar a linha.
   - answer: (recommended)
3. **A sonda do `sdd preflight` ganha uma segunda sessão, isolada, e a suíte ganha uma asserção de
   argv** (o P2 do Codex no PR #302). A sessão nova roda com `--setting-sources ""`, cwd num
   `mktemp -d`, `--permission-mode "$PERMISSION_MODE"`, `--allowedTools "$ALLOWED_TOOLS"` mais as
   linhas do `kit_read_rules` e `--strict-mcp-config`; pede o `Read` de
   `$SDD_HOME/templates/handoff.md` e lê o artefato: negativa no `permission_denials` → `_fail` com
   o remédio, `tool_use` + `tool_result` sem erro → `ok`, nenhuma tentativa → `warn` (e um stream
   sem init nem `result` não diz nada novo: a sonda do `Bash` já disse "did not answer"). A sonda do
   Bash fica intacta. O `check-preflight.sh` cobra o veredito (par de stubs A/B) **e** que o argv
   dessa sessão leva `--setting-sources` vazio e a regra. Porquê: com as settings do ambiente o
   template é lido sem regra nenhuma (p4), e nesta máquina o `additionalDirectories` do operador
   deixaria a sonda sempre verde; `--setting-sources ""` isola (p5, p6); e sem a asserção de argv o
   mutante que tira a regra do preflight sobreviveria, porque o stub responde o que o fixture manda.
   - answer: (recommended)
4. **Os três achados da janela saem da missão** e entram no `TODO.md` por um chore próprio de
   `TODO.md` + catraca (26 → 29), pela rota do #293 e do #303, feito pelo relay antes do EXEC da
   F9. Feito no mesmo dia: PR #309, merge `b96f3d3` (`01-plano.md`, § Os três achados da janela). Porquê: esta missão é só a
   F9, e o lote de zerar a catraca, depois do merge dela, os encontra contados na triagem.
   - answer: (recommended)
5. **A ADR é escrita agora, no PLAN**, alocada por `./bin/sdd adr new --slug
   the-session-reads-what-the-boot-names --spec <este arquivo>` rodado do worktree, com o corpo em
   inglês no molde da 0018 (contexto com as 13 sondas, as decisões 1 a 3, as alternativas
   descartadas). O antigo I1 sai do checkpoint. Na reescrita do plano, o incremento do
   `READ_EXTRA` se partiu em dois (a chave; o aviso do preflight), pelo tamanho de sessão, e a missão
   ficou com seis incrementos. Porquê: são
   trade-offs de permissão caros de reverter e surpreendentes sem contexto, o kit roda sob
   `ADR_CHECK="block"`, e nenhuma fase depois do PLAN decide trade-off pelo humano (§6.1 do
   planner); o Check do I1 nasceria verde e o `--red` o recusaria.
   - answer: (recommended)
6. **`kaizen_log:` fica vazio: a DOCS escreve a entrada do `KAIZEN_LOG.md`**, com o antes e depois
   medidos (a sonda de rascunho `DENIED` → lido; o preflight desta máquina verde sem a regra →
   vermelho sem ela), e o `gate_DOCS` a cobra. Porquê: a melhoria tem número, e o log é onde o kit
   o guarda.
   - answer: (recommended)
7. **O I6 avisa também a skill que o preflight acha e o `READ_EXTRA` não declara.** Para cada skill
   que o preflight pede e acha (`skill_findable`), se o diretório achado não cai sob nenhuma entrada
   do `READ_EXTRA`, um `warn` com a entrada exata a declarar: `$HOME/.claude/skills/<nome>`, ou,
   para plugin, o pai sem versão (`$HOME/.claude/plugins/cache/<marketplace>/<plugin>`). Nunca
   `_fail`, e zero sessão. O `skill_findable` passa a publicar o diretório achado num global,
   chamado e nunca `$( )`. O Check do I6 ganha uma segunda asserção. Porquê: com o `READ_EXTRA`
   vazio por default, o alvo novo só descobriria a negativa na corrida (o `DENIED` do I4), com a
   fase já paga; o aviso a nomeia antes, e não concede nada, porque a permissão continua vindo só da
   chave.
   - answer: (recommended)

## Pendências para o humano

1. **Feito: o chore dos três achados (decisão 4).** O relay o fez num worktree próprio: PR #309,
   merge `b96f3d3` na `origin/main`, catraca `todo-findings 29`. O worktree desta missão foi
   cortado antes dele, e o recebe pelo `git merge origin/main` do passo "Antes do I1" do
   `01-plano.md`.
2. **Depois do merge:** o `additionalDirectories` acrescentado à mão ao `~/.claude/settings.json` em
   2026-10-16 20:19 (ele lista `~/.claude/skills/ticket` e os templates do kit, e libera também a
   escrita, como o `--add-dir`), e o `"Read(*)"` do `.claude/settings.local.json` do `sales_quote`,
   que é mais largo que o necessário. Manter, ou trocar pelo `READ_EXTRA` de cada alvo.
3. **Yokoten, depois do merge:** o lighthouse e o jrc-libs declaram no `.sdd/config.sh`, escrito com
   `$HOME`, os diretórios das skills de que as fases dependem: `$HOME/.claude/skills/ticket` (um
   symlink nesta máquina, que o runner resolve), `$HOME/.claude/skills/qa-report`,
   `$HOME/.claude/skills/qa-execution` e o pai sem versão do plugin,
   `$HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`.
4. **O carimbo de mutação:** `./bin/sdd health` depois do último commit de código, com a revisão do
   PR fechada (CLAUDE.md, § TDD aqui dentro).
