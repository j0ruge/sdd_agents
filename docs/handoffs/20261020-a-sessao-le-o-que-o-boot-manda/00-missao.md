---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
titulo: toda fase headless lê, só para leitura, os templates do kit que o boot manda ler; a leitura que o harness negou aparece no journal e reprova o preflight; e o projeto declara onde moram as skills de que as fases dependem
data: 2026-10-20
versao:
branch: kaizen/20261020-a-sessao-le-o-que-o-boot-manda
aprovacao:
adr: none
ddd: n/a
qa:
kaizen_log:
---

# Missão — a sessão lê o que o boot manda ler

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.
>
> ⚠️ **Este plano não teve humano na sala.** Nasceu do laço `sdd kaizen` em 2026-10-20, do
> veredito `melhorou` sobre `bad6168` que está em `05-verdict.md`, ao lado. `aprovacao:` fica vazio
> por regra: plano nascido do kaizen nunca é `auto` (`plan_approves_itself`, `gate_PLAN`). O humano
> lê, decide o I1 e aprova com `sdd approve`.
>
> ⚠️ **Missão do kit.** Ela se executa de forma interativa, num worktree ligado cortado da
> `origin/main` **depois** do merge da branch deste veredito (ADR 0016 §2). Nunca por `sdd run` a
> partir do checkout principal, que é o `sdd` do PATH de todo alvo. O kit descongela com esse merge.

## Problema (Gemba)

**1. O boot manda ler um caminho que o runner não deixa abrir.** O item 6 do `boot_prompt` manda
toda fase partir do template em `$SDD_HOME/templates/` e "NEVER from memory" (`bin/sdd:3321`, a lista
sai de `phase_templates`, `bin/sdd:3181`). O `run_phase` lança a sessão com
`--permission-mode acceptEdits --allowedTools "$ALLOWED_TOOLS"` (`bin/sdd:5302-5310`), e o padrão é
`ALLOWED_TOOLS="Bash"` (`config/starter.conf:94`). Sob essas flags o `Read` fora do diretório do alvo
é **negado**. Reproduzido em 2026-10-20 às 11:41, num repo de rascunho, sem as settings do usuário,
em Claude Code 2.1.296: `Read /home/joruge/repos/sdd_agents/templates/handoff.md` respondeu `DENIED`,
com `permission_denials` nomeando o arquivo.

**2. Três saídas, e nenhuma é a certa.** Lido no `permission_denials` dos logs de sessão da janela do
lote 7:
- **contornar pelo Bash**: no lighthouse, a sessão de TICKET leu os mesmos arquivos com `cat`. É a
  classe que a fronteira do chapéu pune quando o caminho é de escrita (ADR 0013);
- **trabalhar sem a referência**: a r1 da REVIEW do lighthouse teve 30 `Read` negados nas
  referências da skill `codereview`. A do jrc-libs teve 14, em 2026-10-17;
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
- **Suíte**: as linhas `ok` novas dos Checks I3–I7, cada uma com mutante no catálogo.
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
`sdd preflight` lê um template com as flags da fase e fica vermelho quando não consegue. O projeto
declara, numa chave validada no `load_config`, os diretórios de skill que as fases leem, e cada um
vira a mesma regra só de leitura. A forma exata desse último passo é a do I1.

## Fora de escopo

- **A guarda de kit que para a corrida do alvo por um merge só de docs**, e **a REVIEW aprovada que
  não vê o código que entrou depois dela**. Os dois foram medidos nesta janela e vão ao `TODO.md`
  pelo I2. O primeiro pede ADR própria (afrouxa uma parada); o segundo é o espelho do D21.
- **O `writes:` do `sdd-kaizen`**, que nenhuma guarda cobra e que o boot do juiz contradiz. Vai ao
  `TODO.md` pelo I2.
- Negativas sob `/tmp`, em rascunhos que a própria sessão criou pelo Bash: no jrc-libs, 3 leituras e
  4 escritas; no lighthouse, 1 leitura e 2 escritas. São da sessão, não do boot.
- Os 26 itens abertos do `TODO.md`: nenhum cabe neste tema. A triagem está no `01-plano.md`.
- Desfazer o `additionalDirectories` posto à mão em 2026-10-16 e o `"Read(*)"` do `sales_quote`. É
  decisão do humano (Pendências).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✗ | Sem grill: o plano nasceu do `sdd kaizen`. A pergunta aberta (a forma da permissão de leitura e quem é dono dos diretórios de skill) tem dono, o humano, no I1 e em Pendências |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✗ | Não testado por sessão nova. O `01-plano.md` cita `arquivo:linha` de cada sítio e o comando de cada sonda, mas o I7 depende da escolha do I1 |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 7 de 7. `--check`: 7 linhas, 0 sob a regra da âncora, nenhuma cega. `--red`: rc 0, sete Checks vermelhos no HEAD `4068f7e` (`01-plano.md`, § Contexto verificado) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh:49`); `versao:` vazio |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none` até o I1. A missão carrega um trade-off de permissão, e o I1 é o humano alocando a ADR com `sdd adr new` |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `permission_denials` de 70 logs de sessão em duas missões, os 33 do `sales_quote`, o reflog do kit e sete sondas `claude -p` reais |
| K2 | Problema declarado com métrica | ✅ | Sonda de rascunho `DENIED` → lido; 6 + 2 negativas em templates → 0 |
| K3 | Desperdícios identificados e cortados | ✅ | Leitura contornada pelo Bash, 30 + 14 referências da REVIEW negadas, um TICKET parado e uma intervenção |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 7 incrementos, cada um com uma linha `ok` própria ou um `grep` |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem a linha `ok` do sensor ancorada em `^  ok    `, nunca o texto solto |
| K6 | Jidoka — o que para a linha está definido | ✅ | O `sdd preflight` fica vermelho com a leitura negada (I5), e o `load_config` morre com chave inválida (I7) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | A anatomia §2 e §6, o `config/schema.md` e o `docs/failure-modes.md` mudam no mesmo commit do código |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio: a DOCS escreve a entrada, e o `gate_DOCS` a cobra |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio: a mudança são flags de permissão do harness, uma linha de journal, uma sonda de preflight e uma chave de config no runner bash.`

## Decisões do grill (não re-litigar)

Nenhuma. Este plano nasceu do `sdd kaizen`, sem grill e sem humano. O que pede julgamento humano
está no I1 e em Pendências, e o leitor da D22 conta `0 (recommended) of 0` até o humano replanejar.

## Pendências para o humano

1. **A decisão do I1, antes do I3.** Duas perguntas, cada uma com a recomendação desta sessão:
   - **Como a sessão ganha a leitura?** Recomendado: uma regra `Read(//<dir>/**)` como argumento a
     mais do `--allowedTools`. Ela libera só a leitura, medido às 11:42: a escrita no mesmo
     diretório continua negada. A alternativa é o `--add-dir`, que também libera a leitura, mas deixa
     a sessão **escrever** no diretório do kit sob `acceptEdits`, o que foi medido no mesmo minuto.
   - **Quem é dono dos diretórios das skills?** Recomendado: uma chave de projeto, `READ_EXTRA`,
     com diretórios absolutos validados no `load_config`, no molde do `HAT_WRITES_EXTRA`, cada um
     virando a mesma regra só de leitura. As alternativas são uma chave `reads:` no frontmatter do
     chapéu, com o runner resolvendo o caminho da skill, ou deixar com as settings do humano e só
     medir (`DENIED` e o preflight). O caminho do plugin traz a versão, então a chave aceita um
     diretório-pai (`…/codereview`) e não o da versão.
2. **Depois do merge:** o `additionalDirectories` acrescentado à mão ao `~/.claude/settings.json` em
   2026-10-16 20:19, e o `"Read(*)"` do `.claude/settings.local.json` do `sales_quote`, que é mais
   largo que o necessário. Manter, ou trocar pelo `READ_EXTRA` de cada alvo.
3. **Yokoten:** o lighthouse e o jrc-libs declaram o `READ_EXTRA` com os diretórios das três skills.
4. **O carimbo de mutação:** `./bin/sdd health` depois do último commit de código, com a revisão do
   PR fechada (CLAUDE.md, § TDD aqui dentro).
