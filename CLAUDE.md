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
- **Enum lido em mais de um ponto vira UMA definição por programa.** `blocked` e `degraded` são os
  dois eventos de escalada do ledger, e o par estava escrito à mão em três lugares (admissão da
  série, mapa de escaladas, rubrica de rótulo). Dois aprenderam o evento novo, o terceiro ficou
  cego — e a única missão em que o runner baixou a própria régua passou a ler `ok` para o juiz.
  Hoje cada programa define `is_escalation` uma vez. Evento novo entra pela definição, nunca por
  um `or` acrescentado a um `select`.

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

## Kaizen

Melhoria com antes/depois **medido** vai para o [`KAIZEN_LOG.md`](KAIZEN_LOG.md). Sem número,
não é kaizen — é opinião.
