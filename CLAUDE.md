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

**6. YAGNI.** Sem daemon, sem UI, sem banco, sem servidor. Um script bash, seis markdowns e
templates. Se a solução pede infraestrutura, provavelmente é a solução errada.

## Ao mexer no runner (`bin/sdd`)

- `set -euo pipefail` sempre; `bash -n bin/sdd` é o smoke test mínimo.
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

## Ao mexer nos agentes (`agents/*.md`)

- São markdown aberto com frontmatter compatível com `.claude/agents/`: portável para outros
  harnesses. Não acople a nenhuma API do Claude Code que não seja o próprio arquivo.
- Um agente = uma "troca de chapéu". Se você está adicionando uma sétima responsabilidade a um
  agente existente, provavelmente é um agente novo — ou não é responsabilidade de agente nenhum.
- O agente descreve **o que produzir e onde**, com o formato exato do artefato. Quem julga se
  ficou bom é o gate, não o texto do prompt.

## Commits

Pequenos, com o porquê no corpo. Convenção: `<tipo>(<escopo>): <o quê>` — `feat(runner)`,
`fix(qa)`, `docs(pipeline)`, `chore(config)`. Um incremento do plano = um ou poucos commits,
nunca um commit gigante no fim.

## TDD aqui dentro

O kit é bash + markdown, então o "teste" é o **Check** de cada incremento do plano: um comando
com resultado esperado. Escreva o Check antes de implementar o incremento.

A suíte é `tests/run-all.sh` — é ela o `TEST_CMD` deste repo, e é ela que os gates rodam. Sensor
novo entra lá (`check-templates.sh`, `check-gates.sh`, `check-dry-run.sh`, `check-mutation.sh` e
`check-lang.sh` são os de hoje). `sdd preflight`, `bash -n bin/sdd` e os dry-runs completam, mas
não substituem.

**Sensor que se auto-exclui carrega um auto-teste.** `check-lang.sh` não pode se escanear (o
dicionário dele É português), então quem o mede é um `selftest()` com probes e rc próprios — 90,
91, 92 — mais um piso de caminhos na superfície (93). Sem isso, regex quebrada reporta "tudo
limpo" para sempre. A regra vale para qualquer sensor futuro que precise se excluir do que mede.

**Fixture que imita saída de skill de terceiro é copiado da fonte**, com o caminho no comentário
de proveniência — nunca escrito de memória. Três bugs de gate nasceram de fixture imaginado:
gate e fixture tinham o mesmo autor e a mesma suposição, então a suíte verde *confirmava* a
suposição em vez de medi-la, e fixture errado passa verde para sempre. `sdd health` confere a
proveniência contra as skills instaladas.

**Gate novo entra com mutação** em `tests/check-mutation.sh` — `sdd health` reprova gate sem
mutação no catálogo. Sabotar o gate e exigir que a suíte morra é o que prova que a asserção
mede alguma coisa; sem isso não há como distinguir asserção viva de decoração.

⚠️ Este arquivo roda com `set -o pipefail`: `printf … | grep -q` devolve **141** quando o grep
ACHA e sai antes de o printf terminar de escrever (SIGPIPE). A lógica fica invertida em entrada
grande e correta em entrada pequena — o pior dos dois mundos. Use herestring (`<<< "$var"`).

⚠️ Mesma família: um comentário `#` **dentro** de um bloco continuado por `\` quebra o comando em
silêncio, e `bash -n` não acusa — achado escrevendo os construtores `jq -cn \` do ledger de
autonomia (I13.1). Comente antes do bloco `\`-continuado ou depois dele, nunca no meio.

## Kaizen

Melhoria com antes/depois **medido** vai para o [`KAIZEN_LOG.md`](KAIZEN_LOG.md). Sem número,
não é kaizen — é opinião.
