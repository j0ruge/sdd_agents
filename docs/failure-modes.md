# Modos de falha

O que quebra, como o kit reage, e o que **você** faz. Ordenado por frequência esperada.

Regra geral antes de qualquer diagnóstico: rode `sdd status <missão>` e `sdd why <missão>`.
O runner sabe dizer em que gate parou e por quê — não adivinhe.

---

## A sessão não consegue executar comandos

**Sintoma:** a fase EXEC não commita nada; o log da sessão diz *"This command requires approval"*
ou *"comando bloqueado"*. O gate reprova com "1 de N incrementos ainda por executar" para sempre.

**Causa:** `--permission-mode acceptEdits` auto-aprova **edição de arquivo**, não `Bash`. Sem
`--allowedTools`, a sessão lê mas não roda a suíte e não faz `git add`.

**Reação do kit:** `sdd preflight` pega isso antes de qualquer missão — ele dispara uma sessão
headless real com as mesmas flags e exige que ela execute um comando.

**Você faz:** confira `ALLOWED_TOOLS` no `.sdd/config.sh` (default `Bash`). Este foi o primeiro
defeito estrutural que o kit encontrou em si mesmo, na missão-fixture `20260814-dry-run-completo`.

---

## Incremento `blocked`

**Sintoma:** `sdd run` sai com código 3 e "BLOCKED em EXEC" logo de cara, sem abrir sessão.

**Causa:** o executor encontrou a suíte vermelha por causa de um incremento **anterior** e parou.
É Jidoka funcionando: sensor vermelho para a linha.

**Você faz:** leia as "Notas de execução" do `checkpoint.md` — o motivo está escrito lá. Resolva
o impedimento, volte o incremento para `pending`, rode `sdd run` de novo.

**Não faça:** marcar `done` para destravar. O gate confere o hash no `git log` e a suíte de
verdade; você só perde a sessão seguinte.

---

## Estouro de janela de contexto no meio de um incremento

**Sintoma:** a sessão morre ou devolve resposta truncada; o checkpoint não avançou.

**Reação do kit:** o estado vive em disco. `sdd run` de novo boota uma sessão **nova** a partir
do checkpoint — não há nada a recuperar.

**Se repetir no mesmo incremento:** a fatia está grande demais. Volte ao `sdd-planner` e
re-fatie. Retentativa infinita contra uma fatia mal dimensionada é desperdício, não persistência.

---

## Teste flaky

**Sintoma:** o gate reprova, você roda o comando à mão e passa.

**Reação do kit:** os gates memoizam por processo, então uma execução do runner mede uma vez.

**Você faz:** confirme a intermitência (rode 3×). Flaky confirmado vira linha no `TODO.md` do
repo-alvo **e** nota no handoff da missão. Não "conserte" o flaky dentro da missão: é outro
escopo, e o kit tem um lugar para ele.

---

## `agent-browser` ausente ou travado

**Sintoma:** `agent-browser: command not found`, ou a fase QA fica pendurada.

**Causa conhecida:** shim em `~/.nvm/versions/node/*/bin/agent-browser` apontando para
`~/.hermes/hermes-agent/node_modules/...`, que não existe.

**Reação do kit:** `sdd preflight` checa `agent-browser --version` sempre que `E2E_CMD` ou
`APP_URL` estão definidos.

**Você faz:**
```bash
ln -sf ../lib/node_modules/agent-browser/bin/agent-browser.js \
  ~/.nvm/versions/node/<versão>/bin/agent-browser
```

---

## Loop QA⇄EXEC não converge

**Sintoma:** `BLOCKED em QA` depois de `QA_MAX_ITER` voltas; o registry de bugs não zera.

**Causa típica:** cada fix quebra outra jornada — sinal de que o defeito é mais fundo do que os
sintomas registrados.

**Você faz:** leia os `30-handoff-qa.md` das voltas. Se os bugs mudam de lugar a cada rodada, o
problema é de design e volta ao planejamento, não ao executor.

---

## Review não fecha em Grade A

**Sintoma:** `BLOCKED em REVIEW` após `REVIEW_MAX_ITER` sessões.

**Você faz:** leia o último `40-review-r<N>.md` — a grade real está lá. Se os findings forem
legítimos e grandes, a missão foi mal fatiada. Se você quer o PR mesmo assim, configure
`PUBLISH_ON_REVIEW_BLOCKED="draft"`: sai um PR **draft** com a grade atual e as pendências
visíveis, em vez de esconder o problema.

**Nunca:** editar o relatório para colocar A. Isso desliga o único sensor de qualidade da missão.

---

## `sdd install` mostra diff nos agentes

**Sintoma:** avisos "agente X difere da versão do kit" com um diff.

**Causa:** o repo-alvo tem uma versão customizada (ou antiga) do agente. É informação, não erro.

**Você faz:** `sdd install --force` adota a versão do kit. Se a customização era proposital,
mantenha — e registre no `TODO.md` do kit por que ela existe: customização recorrente é sinal de
que o agente do kit precisa mudar.

---

## Conflito com a branch base no push

**Sintoma:** `50-pr.md` com `status: blocked` e o motivo do conflito.

**Por quê:** o `sdd-publisher` **não resolve conflito**, por design. Resolver conflito é decidir
qual das duas intenções vence — julgamento humano. Rebase automático aqui é a forma mais barata
de perder trabalho alheio.

**Você faz:** resolva o conflito à mão, depois `sdd run <missão>` para a fase PR seguir.

---

## Drift de skill upstream

**Sintoma:** um gate reprova mesmo com o artefato aparentemente correto.

**Causa:** o kit ancora em **poucos** pontos de formato de skills de terceiros, e eles podem
mudar:

| Gate | Âncora | Skill |
|---|---|---|
| QA | `**Status:** closed` no relatório; linhas `Pending` na matriz; `**Status:** open` nos bugs | `qa-execution` / `qa-report` |
| REVIEW | seção `### Overall Grade` e a coluna `Grade` | `codereview` |

**Você faz:** confira o formato atual da skill e ajuste a âncora em `bin/sdd` — e atualize
`tests/check-gates.sh` no mesmo commit, para o sensor pegar o próximo drift.

---

## Custo maior que o esperado

**Você faz:** `.sdd/logs/<missão>/pipeline.log` tem uma linha por sessão com custo e duração.
`BUDGET_PER_PHASE_USD` é teto por sessão (dano máximo), não orçamento da missão. Se uma fase
está cara de forma recorrente, o problema costuma ser plano mal fatiado — sessões grandes
re-explorando o que o "Contexto verificado" deveria ter entregue pronto.
