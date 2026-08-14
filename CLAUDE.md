# CLAUDE.md — convenções do kit `sdd_agents`

Instruções para quem trabalha **neste repositório** (o kit). Para o que os agentes fazem nos
repos-alvo, veja [`docs/pipeline.md`](docs/pipeline.md).

## Idioma

PT-BR em tudo que é lido por humano: README, docs, mensagens de commit, prompts dos agentes,
saída do runner. Identificadores de código (funções, variáveis, chaves de config) em inglês.

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
novo entra lá (`check-templates.sh`, `check-gates.sh`, `check-dry-run.sh` são os de hoje).
`sdd preflight`, `bash -n bin/sdd` e os dry-runs completam, mas não substituem.

## Kaizen

Melhoria com antes/depois **medido** vai para o [`KAIZEN_LOG.md`](KAIZEN_LOG.md). Sem número,
não é kaizen — é opinião.
