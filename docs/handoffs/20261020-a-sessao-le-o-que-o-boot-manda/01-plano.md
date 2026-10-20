---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
data: 2026-10-20
---

# Plano — a sessão lê o que o boot manda ler

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

> Plano nascido do `sdd kaizen` em 2026-10-20 12:00, sem humano na sala, com o veredito
> `05-verdict.md` ao lado. Tudo abaixo de "Contexto verificado" foi medido nesta sessão, no HEAD
> `4068f7e` do kit. O que não foi medido está em "Riscos e não-feitos", marcado como risco.

## Contexto verificado (não re-descobrir)

**O defeito, reproduzido.** Sondas `claude -p` reais em Claude Code 2.1.296, num repo de rascunho
sob `mktemp -d`, com `--setting-sources "project,local"` para tirar do caminho o
`additionalDirectories` posto à mão no `~/.claude/settings.json`. O ambiente foi limpo como o
`HARNESS_ENV_UNSET` limpa. Todas em haiku, menos de US$ 0,02 somadas:

| Hora | Flags além de `-p --permission-mode acceptEdits --model haiku` | Pedido | Resultado |
|---|---|---|---|
| 11:41 | `--allowedTools "Bash"` | `Read` de `$SDD_HOME/templates/handoff.md` | `DENIED`, e `permission_denials` nomeia o arquivo |
| 11:41 | `--allowedTools "Bash" --add-dir $SDD_HOME/templates` | o mesmo `Read` | lido (`---`) |
| 11:42 | `--allowedTools "Bash" "Read(//<dir>/**)"` | `Read` de `<dir>/f.md` | lido |
| 11:42 | `--allowedTools "Bash" "Read(//<dir>/**)"` | `Write` de `<dir>/c.md` | `DENIED` |
| 11:42 | `--allowedTools "Bash" --add-dir <dir>` | `Write` de `<dir>/b.md` | **escrito** |

O `<dir>` foi um `mktemp -d` sob `/tmp`, nunca o kit. A regra absoluta leva **duas** barras:
`Read(/` seguido do caminho absoluto. O `--allowedTools` aceita a regra como **segundo argumento**
depois do `"$ALLOWED_TOOLS"`; a forma de um argumento só, separada por espaço, não foi medida.

**Onde o boot manda ler.**
- `bin/sdd:3181`: `phase_templates`, a lista de templates por fase.
- `bin/sdd:3319-3326`: o item 6 do `boot_prompt` — "the artifact templates this phase writes from,
  in $SDD_HOME/templates/ … NEVER from memory".
- Toda fase recebe esse item, e o KAIZEN também.

**Os três `claude -p` do runner, e as flags de cada um.**
- `run_phase`: o array `cmd` em `bin/sdd:5302-5310`; o `--allowedTools "$ALLOWED_TOOLS"` está em
  `bin/sdd:5307`.
- A sonda do `sdd preflight`: `bin/sdd:6212-6217`; o `--allowedTools "$ALLOWED_TOOLS"` está em
  `bin/sdd:6214`. O veredito dela (`_fail` sem Bash, `ok` com o marcador) vem em seguida.
- O `cmd_close`: `bin/sdd:11957-11962`; o `--allowedTools` está em `bin/sdd:11960`.
- Fora dos três: o `HARNESS_ENV_UNSET` (`bin/sdd:5224`) e o `hat_init_facts` (`bin/sdd:5140`),
  chamado em `bin/sdd:5379` (`run_phase`) e em `bin/sdd:11965` (`cmd_close`). Ele publica
  `LAST_PHASE_DENIALS` como contagem (`bin/sdd:5164`), que a linha de sessão grava como `denials`
  (`bin/sdd:5072`).
- O journal da missão se escreve com `pipeline_log_line`. Exemplo de linha:
  `KIT-TOUCHED`, em `bin/sdd:4373`.

**Config.**
- `ALLOWED_TOOLS="Bash"` em `config/starter.conf:94`, documentado em `config/schema.md:261`.
- `HAT_WRITES_EXTRA` é o molde de chave validada no `load_config` (`bin/sdd:241-266`), com o `die`
  no `load_config` e **nunca** no ponto de uso, porque lá o `die` cairia num subshell (anatomia §6).
- O `config_reload` relê as chaves de `health_default_keys` (`bin/sdd:6600`) a cada volta do
  `cmd_run`. Chave nova entra nessa lista.
- `.sdd/config.sh` do kit: `JIRA_ENABLED=false` (linha 49), `ADR_CHECK="block"` (linha 32) e
  `OUTPUT_LANG="pt-BR"` (linha 55).

**Os sensores que os Checks leem.** Todos imprimem `  ok    <asserção>` na stdout e
`  FAIL  …` na stderr (`pass()` e `fail()` em `tests/check-dry-run.sh:41-45`,
`tests/check-autonomy.sh:42-46` e `tests/check-preflight.sh:41-45`).
- `tests/check-dry-run.sh` lê o argv **real** de cada fase no bloco `--- DRY RUN: phase X ---` (o
  parser `effort_of` está em `tests/check-dry-run.sh:349`). ⚠️ O runner imprime esse argv com
  `printf '  %q'` (`bin/sdd:5331`), então a regra sai escapada (`Read\(//…/templates/\*\*\)`), e a
  asserção tem de ler o escape ou desfazê-lo.
- `tests/check-gates.sh` grava o argv do `sdd close` com um argumento por linha (`$CLOSE_ARGV`,
  `tests/check-gates.sh:5845-5860`).
- `tests/check-preflight.sh` tem o par de stubs da sonda (`tests/check-preflight.sh:268-300`). O init
  e o resultado são uma sessão **real** de 2026-09-06, e o resto é derivado com `jq`, nunca digitado.
- `tests/check-autonomy.sh` tem o `STREAM_SAMPLE`, com a proveniência em
  `tests/check-autonomy.sh:150-160`.
- Fixture com negativa **real**, para os stubs do I5 e do I6:
  `/home/joruge/repos/jrc-libs/.sdd/logs/20261016-object-storage-distribuivel/TICKET-20261016-201644-1924a656.json`.
  O `permission_denials` dele tem três `Read` (dois em `~/.claude/skills/ticket/references/`, um em
  `/home/joruge/repos/sdd_agents/templates/handoff.md`). Foi capturado em Claude Code 2.1.296 e é
  colado verbatim, com a proveniência no comentário (CLAUDE.md, § fixture de skill de terceiro).

**O estado no HEAD `4068f7e`.**
- `bash tests/check-todo.sh` → `26 finding(s), all within 8 lines, carrying anchor + date, every
  anchor on target`. A catraca é `todo-findings 26` (`tests/health-baseline.txt:26`).
- `tests/check-checkpoint.sh --check` sobre o `checkpoint.md` desta missão → `7 row(s), 5 under the
  anchor rule, none blind`, rc 0.
- `tests/check-checkpoint.sh --red` → `7 pending Check(s), every one red at HEAD`, rc 0, em 453 s
  com `SDD_STATE_DIR` num diretório temporário. Cada Check imprimiu `0`, e o I2 queria `3`.
- Os três textos de achado do I2 (abaixo) passaram em `tests/check-todo.sh --check` → `3 finding(s),
  all within 8 lines, carrying anchor + date, every anchor on target`. Foram medidos num arquivo
  temporário dentro da pasta da missão, já apagado.

**Pitfalls desta casa que esta missão vai pisar.**
- Toda mudança em `bin/sdd` desloca as âncoras `bin/sdd:N` do `TODO.md`, e o `check-todo.sh` da
  suíte reprova âncora fora do alvo. Rode `bash tests/check-todo.sh` antes de cada commit em `bin/`
  e reancore pelo símbolo, que fica, trocando só o número.
- `shellcheck -S warning bin/sdd tests/<tocado>.sh` antes de cada commit em `bin/` ou `tests/`. O lint
  só roda na suíte inteira.
- Mutante novo se prova com `tests/check-mutation.sh --only <slug> <sensor.sh>`, que é dica e não
  veredito. O carimbo é do `./bin/sdd health`, rodado pelo operador depois do último commit de código
  e da revisão do PR.
- `Edit` sem `Read` prévio é recusado em `claude -p`; na sessão interativa, não.

## Arquitetura da mudança

**Uma definição, três portas.** Uma função nova, `kit_read_rules`, imprime as regras de leitura que
toda sessão do runner recebe: `Read(/$SDD_HOME/templates/**)`, e depois do I7 uma regra por diretório
do `READ_EXTRA`. Ela é **chamada** por cada porta que monta um `claude -p` e nunca copiada. As portas
são `run_phase`, a sonda do `cmd_preflight` e o `cmd_close`. Cada uma acrescenta as regras como
argumentos a mais do `--allowedTools`, depois do `"$ALLOWED_TOOLS"`. É a mesma régua do `CLAUDE.md`
para enum lido em mais de um ponto: porta nova chama a definição, e cada porta tem o seu probe (I3,
I4, I5).

**Por que regra e não `--add-dir`.** Medido às 11:42: o `--add-dir` libera a leitura **e** a escrita
sob `acceptEdits`, e a regra libera só a leitura. A guarda de kit pararia a escrita no `$SDD_HOME`
depois da sessão, mas parar depois é pior que não permitir. A decisão é do humano no I1, e esta é a
recomendação.

**O sensor de quem ficou de fora.** O `hat_init_facts` já lê o resultado da sessão. O I6 acrescenta,
no mesmo ponto e com a mesma regra de "não medido não é zero", uma linha
`DENIED  <fase>  <ferramenta>  <caminho>` no journal por negativa distinta. Assim o humano no
`tail -F` vê o que a fase não conseguiu ler sem abrir o `.json`. A contagem no ledger não muda.

**A sonda que fica vermelha.** A sonda do `sdd preflight` já roda sob as flags do executor. O I5
acrescenta ao prompt um `Read` de `$SDD_HOME/templates/handoff.md` e lê o **artefato**, nunca a
resposta do modelo:
- negativa no `permission_denials` do resultado nomeando o template → `_fail`, com o remédio;
- um `tool_use` de `Read` com aquele caminho e o `tool_result` sem erro no stream → `ok`;
- a sessão nunca tentou o `Read` → `warn`, porque não medido não é zero.

**A chave do projeto (I7, se o I1 confirmar).** `READ_EXTRA` é uma lista de diretórios absolutos,
literais, separados por `:` ou por espaço, validada no `load_config` no molde do `HAT_WRITES_EXTRA`.
Cada diretório vira `Read(/<dir>/**)` dentro do `kit_read_rules`. É documentada no
`config/schema.md`, no `config/starter.conf` (comentada, com o exemplo das três skills) e no
`health_default_keys`.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — A ADR da leitura, alocada e decidida pelo humano

**O quê:** alocar a ADR com
`./bin/sdd adr new --slug a-sessao-le-o-que-o-boot-manda --spec docs/handoffs/20261020-a-sessao-le-o-que-o-boot-manda/00-missao.md`,
que escreve os dois lados do vínculo, e o humano escreve a decisão. São as duas perguntas das
Pendências do `00-missao.md`: regra × `--add-dir`, e `READ_EXTRA` × `reads:` no chapéu × só
settings. As medições da tabela acima vão como contexto da ADR.
**Onde:** `docs/adr/NNNN-<slug>.md` e o `adr:` do `00-missao.md`.
**Como (TDD):** não há código. O Check é vermelho no HEAD porque o `adr:` diz `none`.
**Check:** `grep -cE '^adr: docs/adr/[0-9]{4}-[a-z0-9-]+\.md$' docs/handoffs/20261020-a-sessao-le-o-que-o-boot-manda/00-missao.md` → `1`
**Sensor durável:** o `sdd adr check` e o `tests/check-adr.sh`, que já existem e leem os dois lados.
**Reversível por:** apagar o arquivo da ADR e voltar o `adr:` a `none`, antes de qualquer código.
⚠️ **O dono deste incremento é o humano.** Se a ADR escolher outra coisa que não a regra e o
`READ_EXTRA`, o I3 e o I7 se reescrevem antes de começar, e os Checks com eles.

### I2 — Os três achados da janela entram no TODO.md, com a catraca

**O quê:** acrescentar à seção aberta do `TODO.md` os três itens abaixo, verbatim, e mover
`todo-findings 26` → `29` no `tests/health-baseline.txt` **no mesmo commit** (princípio 5). Os dois
primeiros vão para `### Contrato e configuração` e o terceiro para `### Sensores que faltam`. Se
outro merge mexeu na catraca antes, a conta é a de então + 3.
**Onde:** `TODO.md` e `tests/health-baseline.txt`.
**Como (TDD):** o Check vem antes; depois `bash tests/check-todo.sh` → `29 finding(s) … every anchor
on target`. As âncoras são as do `4068f7e`: este incremento vem antes de qualquer mudança em
`bin/`, de propósito.
**Check:** `grep -c -e '^- \[ \] \*\*A guarda do kit para a corrida do alvo' -e '^- \[ \] \*\*A REVIEW aprovada não vê' -e '^- \[ \] \*\*O .writes:. do .sdd-kaizen. não é cobrado' TODO.md` → `3`
**Sensor durável:** o `tests/check-todo.sh` (forma e âncora) e a catraca do `sdd health`.
**Reversível por:** `git revert` do commit.

Os três itens, medidos pelo `check-todo.sh` no `4068f7e`:

```md
- [ ] **A guarda do kit para a corrida do alvo por um merge só de docs no checkout do kit** — `bin/sdd:4331`
  (`kit_guard_check`) — compara o par cru (HEAD e sujeira) e não lê o rótulo `sdd:` do reflog (anatomia §6). No
  lighthouse o operador puxou o #246 e o #254 (só `docs/`, `TODO.md` e catraca) para o checkout principal do kit
  com a corrida viva: `kit-touched` 2×, 2 células `refez` e 2 das 6 intervenções da missão; o reflog dizia
  `merge origin/main: Fast-forward`, sem rótulo. Direção: com ADR, o movimento sem o rótulo da sessão que não
  toca `bin agents templates config` vira aviso no journal, e o resto continua parando a linha.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)
- [ ] **A REVIEW aprovada não vê o código que entrou depois dela** — `bin/sdd:1907` (`gate_REVIEW`) — o gate lê
  a nota da última rodada e não compara o commit que ela revisou com o HEAD. No lighthouse o F5–F8 (emenda E1–E6)
  e o R3 (P2 do Codex no PR #29) entraram depois da r2 em A, e o humano forçou a r3 e a r4 com `--phase REVIEW`:
  2 das 6 intervenções da missão. É o espelho do D21, em que só `F<n>` reabre a QA. Direção: a rodada grava o
  commit revisado, e código commitado depois dele reabre a REVIEW ou é nomeado no motivo do gate.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)
- [ ] **O `writes:` do `sdd-kaizen` não é cobrado, e o boot manda escrever fora dele** — `agents/sdd-kaizen.md:11`
  (`writes:`) — o chapéu declara `$HANDOFF_DIR/**, KAIZEN_LOG.md`, o boot do `sdd kaizen` manda o achado ao
  `TODO.md` e o `cmd_kaizen` não chama o `hat_guard_check`. O juiz de 2026-10-12 commitou `TODO.md` e a catraca
  sem parada; o de 2026-10-20 seguiu o `writes:` e levou os achados ao plano nascido. Direção: o `writes:`
  ganha `$TODO_FILE` e a catraca e o `cmd_kaizen` passa pela guarda, ou o boot deixa de mandar ao `TODO.md`.
  — descoberto por `sdd-kaizen` na missão `20261020-a-sessao-le-o-que-o-boot-manda` (2026-10-20)
```

### I3 — Uma definição da regra de leitura dos templates, e toda fase a recebe

**O quê:** criar `kit_read_rules` (uma regra por linha; hoje só `Read(/$SDD_HOME/templates/**)`) e
fazer o `run_phase` acrescentar cada linha como argumento do `--allowedTools`, depois do
`"$ALLOWED_TOOLS"`. Acrescentar às seções §2 (Ferramentas) e §6 (Sandboxes) da
`.claude/rules/anatomia-do-agente.md` no mesmo commit. Acrescentar a linha `ALLOWED_TOOLS` do
`config/schema.md:261`, que passa a dizer que o runner soma a regra de leitura.
**Onde:** `bin/sdd` (perto do `HARNESS_ENV_UNSET` e do array `cmd`), `tests/check-dry-run.sh`,
`tests/check-mutation.sh`, `config/schema.md` e a anatomia.
**Como (TDD):** a asserção primeiro, no `check-dry-run.sh`. Em **cada** bloco `--- DRY RUN: phase`
projetado (EXEC, QA:close, REVIEW, DOCS, PR), a linha `claude -p` carrega a regra de leitura dos
templates logo depois do `--allowedTools`, e **nenhuma** carrega `--add-dir`. Uma asserção só,
sobre os cinco blocos, como o `effort_of` faz. Vermelha no HEAD, pela falta da regra.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every phase may read the kit templates, and only read them' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante proposto `mut_RUN_templates_read_rule_dropped`, que tira o
acréscimo do `run_phase` e tem de ser pego pelo `check-dry-run.sh`.
**Reversível por:** `git revert`. A fase volta a depender das settings do alvo.

### I4 — O sdd close recebe a mesma regra

**O quê:** o `cmd_close` chama o `kit_read_rules` e acrescenta as regras ao seu `--allowedTools`
(`bin/sdd:11960`). O fechamento lê a skill `ticket`, e o `CLOSE` do lighthouse teve 3 negativas nas
referências dela.
**Onde:** `bin/sdd` (`cmd_close`), `tests/check-gates.sh` e `tests/check-mutation.sh`.
**Como (TDD):** no `check-gates.sh`, perto da asserção do `EFFORT_TICKET`
(`tests/check-gates.sh:5858`), o `$CLOSE_ARGV` (um argumento por linha) tem a regra de leitura dos
templates e não tem `--add-dir`. Vermelha no HEAD.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    close: the session may read the kit templates, and only read them' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante proposto `mut_RUN_close_templates_read_rule_dropped`.
**Reversível por:** `git revert`.

### I5 — O preflight lê um template com as flags da fase, e reprova quando não consegue

**O quê:** a sonda do `cmd_preflight` (`bin/sdd:6212`) passa a receber o `kit_read_rules`, como as
outras duas portas. O prompt dela ganha um `Read` de `$SDD_HOME/templates/handoff.md`. O veredito
lê o artefato da sessão:
- negativa do template no `permission_denials` do resultado → `_fail`, nomeando o caminho e o
  remédio (a regra do runner, ou a sintaxe que o harness mudou);
- `tool_use` de `Read` daquele caminho com `tool_result` sem erro → `ok`;
- nenhuma tentativa → `warn`.

O texto do `ok` e o do `_fail` ficam em inglês (superfície do kit).
**Onde:** `bin/sdd` (`cmd_preflight`), `tests/check-preflight.sh` e `tests/check-mutation.sh`.
**Como (TDD):** dois stubs, uma diferença só, e as duas saídas comparadas entre si, como o par
"the executor hat sees Bash" (`tests/check-preflight.sh:268-300`):
- **stub A**: o resultado carrega no `permission_denials` a entrada do template, copiada do `.json`
  real do jrc-libs (§ Contexto verificado) com o caminho trocado por `jq` para o `$SDD_HOME` do
  fixture. Esperado: `_fail`, e o preflight sai com rc ≠ 0;
- **stub B**: `permission_denials: []` e o par `tool_use`/`tool_result` do `Read`. Esperado: `ok`.

A asserção nomeada exige o vermelho do A **e** o verde do B.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    preflight fails when the phase flags cannot read the kit templates' <<< "$o"` → `1`
**Sensor durável:** a asserção diferencial e o mutante proposto `mut_PRE_template_read_unchecked`,
que troca o `_fail` por `ok`. É também o sensor do dia em que o harness mudar a sintaxe da regra,
como já mudou o `disallowedTools:` em 2.1.263.
**Reversível por:** `git revert`.

### I6 — Toda negativa do harness é nomeada no journal

**O quê:** depois do `hat_init_facts`, nas duas chamadas (`bin/sdd:5379` e `bin/sdd:11965`), cada par
`(ferramenta, caminho)` distinto do `permission_denials` do resultado vira uma linha
`pipeline_log_line "<data>  DENIED  <fase>  <ferramenta>  <caminho>"`. O caminho é o
`tool_input.file_path`, ou o `tool_input.path`; quando não há caminho, como no `Bash`, a linha leva
só a ferramenta. Resultado sem `permission_denials` não escreve nada, e não medido não é zero. O
`docs/failure-modes.md` ganha o verbete "the phase cannot read what the boot names", com o sintoma
(`DENIED` no journal, `handoff-blocked` no TICKET) e a saída (a regra do I3, ou o `READ_EXTRA`).
**Onde:** `bin/sdd` (uma função chamada nos dois sítios), `tests/check-autonomy.sh`,
`tests/check-mutation.sh` e `docs/failure-modes.md`.
**Como (TDD):** um stub de sessão cujo resultado carrega duas negativas reais (copiadas do `.json` do
jrc-libs, com proveniência). A asserção exige as duas linhas `DENIED` no `pipeline.log`, com os
caminhos, e **zero** linhas `DENIED` na corrida de controle com o `STREAM_SAMPLE`, que tem
`permission_denials: []`. Vermelha no HEAD.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every tool call the harness denied is named in the journal' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante proposto `mut_RUN_denials_not_journaled`.
**Reversível por:** `git revert`. A contagem `denials` do ledger não muda em nenhum dos dois sentidos.

### I7 — READ_EXTRA: o projeto declara os diretórios das skills, só para leitura

**O quê** (na forma que o I1 decidir; esta é a recomendada): a chave `READ_EXTRA` traz diretórios
absolutos e literais, sem glob, sem `..` e sem quebra de linha, e o `load_config` morre com motivo
nomeado para cada violação. O `kit_read_rules` acrescenta `Read(/<dir>/**)` por diretório, e as três
portas a recebem de graça. Documentada no `config/schema.md`, no `config/starter.conf` (comentada,
com o exemplo das três skills: `~/.claude/skills/ticket`, `~/.claude/skills/qa-report`,
`~/.claude/skills/qa-execution` e `~/.claude/plugins/cache/<marketplace>/codereview`) e no
`health_default_keys`.
**Onde:** `bin/sdd` (`load_config`, `kit_read_rules`, `health_default_keys`), `config/schema.md`,
`config/starter.conf`, `tests/check-dry-run.sh`, `tests/check-gates.sh` (a recusa do
`load_config`) e `tests/check-mutation.sh`.
**Como (TDD):** no `check-dry-run.sh`, um `READ_EXTRA` com dois diretórios aparece como duas regras
`Read(…/**)` em cada bloco de fase, e sem a chave nenhuma regra extra aparece. Uma asserção
diferencial. A recusa (caminho relativo, com `*`, com `..`) ganha uma asserção de rc e de motivo no
`tests/check-gates.sh`, ao lado da do `HAT_WRITES_EXTRA` (`tests/check-gates.sh:6270`, "HAT_WRITES_EXTRA
with ../ is refused, and the reason names it").
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    READ_EXTRA reaches every phase as a read-only rule' <<< "$o"` → `1`
**Sensor durável:** as asserções e os mutantes propostos `mut_RUN_read_extra_ignored` e
`mut_RUN_read_extra_relative_accepted`. A chave **alarga** permissão (só de leitura), e por isso a
passada de sabotagem é obrigatória antes do merge, como foi a do `HAT_WRITES_EXTRA`.
**Reversível por:** `git revert`. Sem a chave, o comportamento é o do I3.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A sintaxe `Read(//abs/**)` mudar num bump do harness, como o `disallowedTools:` mudou em 2.1.263 | média | O I5 deixa o `sdd preflight` vermelho no dia do bump, e o `harness:` da linha de sessão o mostra |
| `$SDD_HOME` com espaço ou caractere de glob quebrar a regra | baixa | Não medido. O `kit_read_rules` recusa (rc e motivo) o `$SDD_HOME` que não for caminho literal, e o limite vai ao comentário |
| A forma de um argumento só (`--allowedTools "Bash Read(…)"`) ser a única que outro harness aceita | baixa | Medida só a de dois argumentos. O comentário do `kit_read_rules` diz qual forma foi medida, quando e em que versão |
| Regra de leitura em `~/.claude/plugins/cache/…` expor à sessão mais do que a skill | média | Só leitura, só o que o projeto declarar (I7); o kit não acrescenta nada além dos próprios templates |
| `additionalDirectories` e `"Read(*)"` postos à mão mascararem o I3 numa medição local | alta | A verificação end-to-end roda com `--setting-sources "project,local"` num repo de rascunho, como as sondas deste plano |
| O I1 escolher `--add-dir` | — | O I3 e o I7 se reescrevem antes de começar, e a guarda de kit fica sendo a única barreira à escrita no `$SDD_HOME`, dito na ADR |

**Não-feitos, por escolha:**
- as leituras e escritas negadas sob `/tmp`, que são rascunho da sessão;
- os três achados do I2, que entram no backlog e não aqui;
- a regra `Read(*)` larga, que é o que o `sales_quote` tem e é exatamente o que o kit não deve
  impor a ninguém.

## Verificação end-to-end

Com os sete incrementos `done`:

1. `bash tests/run-all.sh` verde, e cada linha `ok` dos Checks presente.
2. A sonda de rascunho, que é a métrica da missão. Rodá-la depois do merge, com o kit da missão:

```bash
S=$(mktemp -d) && cd "$S" && git init -q && echo s > README.md && git add . \
  && git -c user.email=k@k -c user.name=k commit -qm i
# os argumentos do `--allowedTools` saem do dry-run do runner, nunca da memória:
# `sdd run <missão> --dry-run` imprime a linha `claude -p` de cada fase
env -u CLAUDECODE claude -p "Use the Read tool (never Bash) to read $SDD_HOME/templates/handoff.md and reply with ONLY its first line. If refused, reply DENIED." \
  --model haiku --permission-mode acceptEdits --setting-sources "project,local" \
  --allowedTools "Bash" "Read(/$SDD_HOME/templates/**)" --output-format json | jq -c '{result, permission_denials}'
# esperado: result "---", permission_denials []
# e o par de controle de escrita no mesmo diretório: DENIED
```

3. `./bin/sdd preflight` num alvo **sem** `"Read(*)"` e sem `additionalDirectories`: a linha nova
   em `ok`. O mesmo preflight com o `kit_read_rules` sabotado: vermelho.
4. Na próxima janela do juiz: 0 `Read` negados em `$SDD_HOME/templates/` nos logs de sessão dos
   alvos, e toda negativa restante nomeada como `DENIED` no `pipeline.log`.

## Triagem do TODO.md

Lidos os 26 itens abertos corpo a corpo, no HEAD `4068f7e`.

**O lote desta missão não vem do `TODO.md`.** A janela mediu um defeito maior que qualquer item
aberto, e que ainda não estava lá. Ele custou a escalada do jrc-libs, 2 sessões fora de `advanced` e
54 leituras negadas nas referências da `codereview` (40 no lighthouse, 14 no jrc-libs), e vai custar
a todo alvo novo (o `dotp-remake` e o
`ui24_agent` estão na fila). Nenhum dos 26 é do mesmo tema. Os mais próximos são os de instalação e
de preflight do `dotp-remake`:
- o `sdd preflight` não mede a forma do `TODO_FILE`;
- o `sdd install` adota a branch atual como base;
- a primeira instalação semeia o `TODO.md` em inglês;
- nada instala o `/sdd-plan`;
- o preflight diz "ok" com um `TEST_CMD` que deixa servidor vivo.

Juntos com estes sete, dariam duas missões numa. Ficam onde estão, intocados, como o candidato
natural ao lote seguinte, "o alvo novo".

### Resolvidos a apagar

Nenhum. Nenhum corpo da seção aberta traz `RESOLVED by <hash>`. As duas ocorrências do token no
arquivo são o **tema** de um item aberto (`TODO.md:69`) e um registro decidido (`TODO.md:244`).

### Saem para o cabeçalho do sensor (régua D15)

Nenhum. Os 26 têm consumidor fora da suíte do kit, e cada um nomeia o alvo em que foi medido:
`sales_quote`, `lighthouse_project`, `ui24_agent`, `dotp-remake` ou o yokoten
`JRC-Brasil/sales_quote#484`. Os dois mais próximos da fronteira continuam abertos:
- **"a prosa congelada diz a regra 2 mais estrita que os sensores"** falha fechado, mas os templates
  e os chapéus são semeados nos alvos;
- **"o remédio do `sdd kaizen` sem `--no-track`"** ensina, por enquanto, uma receita que este próprio
  juiz usaria.

### Achados desta janela

São os três do I2: a guarda de kit e o merge só de docs, a REVIEW que não vê o código posterior e o
`writes:` do juiz. Este juiz não os escreveu no `TODO.md`. O `writes:` do `sdd-kaizen` é
`$HANDOFF_DIR/**, KAIZEN_LOG.md` (`agents/sdd-kaizen.md:11`), e o terceiro achado é justamente essa
contradição. Até o I2, eles moram aqui e no `05-verdict.md`, em disco e com texto pronto.
