# O worker — roadmap do kit que pega missão aprovada e leva até o PR sozinho (2026-09-22)

> Spec de **roadmap**, escrita com o humano presente (brainstorm de 2026-09-22, logo depois de o
> PR #57 — `20260922-o-motivo-da-fase` — ser aberto). Não é spec de missão: cada linha da §4 vira
> uma missão do kit com `/sdd-plan`, spec e plano próprios. Encaixa-se no plano do Codex Astra
> ([`sdd-agents-team-harness-raft.md`](file:///home/joruge/repos/obsidian/03%20Resources/IA%20e%20Agentes/sdd-agents-team-harness-raft.md)):
> W1 **é** a fase 1 dele; W5–W6 são a fase 5 (agenda por política, `tick --once`) com escopo
> concreto. As fases 2–4 e 6 do Astra ficam depois deste roadmap.

---

## 1. A intenção

Um **worker** que, sem humano na sala, coleta o trabalho já planejado dos repos-alvo — rastreado
em cartão do Jira **ou** issue do GitHub — e conduz cada missão pelo pipeline até um PR pronto
para merge. O humano entra só no **planejamento** (PLAN, com `sdd approve`), no **merge** e nas
**escaladas** (rc 3).

Sucesso: missões aprovadas viram PR sem ninguém vigiar `tail -F`, com custo por missão não pior
que a mesma missão rodada à mão, zero colisões de checkout e toda parada chegando ao humano pelo
pager.

## 2. Decisões do humano (2026-09-22)

| # | Pergunta | Decisão | Recusadas |
|---|---|---|---|
| D1 | O que conta como "já planejado"? | **Missão aprovada em disco**: `docs/handoffs/<missão>/` com `aprovacao:` preenchida. O worker **nunca planeja**; o cartão só dá prioridade e rastreio. Gate lê artefato, não status de rastreador. | Rótulo no cartão bastar (PLAN headless quebra o princípio de PLAN com humano); classes A/B (planejamento autônomo de issue pequena). |
| D2 | Alcance e concorrência | **Vários repos-alvo, uma missão por vez na máquina.** Nunca o repo do kit — missão do kit roda interativa (o `claude -p` aninhado morre e o kit editaria o `bin/sdd` que o executa). | Uma por repo em paralelo (fica para depois, com demanda medida); um repo só. |
| D3 | Onde executa | **Clone dedicado por repo** (ex.: `~/sdd-worker/<repo>`), separado do checkout do humano. | O checkout do humano (colisão a cada esquecimento); worktree por missão (o ledger carimba caminho e um worktree já confundiu a identidade do repo). |
| D4 | QA que precisa do app no ar | **O worker sobe o stack do clone**, em portas próprias, antes da fase que precisa, e derruba depois. A sessão continua proibida de subir ambiente — o operador passa a ser o worker. | Parar na QA e avisar (toda missão com interface pararia); só missões sem interface. |
| D5 | Onde o worker para | **PR aberto + comentários dos bots tratados** numa leva, suíte re-rodada, aviso "pronto para merge". Merge e `sdd close` seguem humanos. | Só PR aberto; até o merge (quebraria "merge é humano" sem ADR). |
| D6 | Rastreador | **Jira ou issues do GitHub, por repo** (`TRACKER=jira\|github\|none`). | — |

## 3. A forma: script fino, tick curto, timer do sistema

Três abordagens foram pesadas:

- **A — escolhida.** `bin/sdd-worker tick --once`, disparado por **systemd timer**, que chama o
  `sdd` como processo. O `bin/sdd` segue executor e avaliador de **uma** missão; descoberta
  multi-repo, clones e ambiente são responsabilidade de outro programa. Cada tick é curto e sem
  estado próprio — morrer no meio custa nada, porque o próximo re-deriva dos artefatos (princípio
  4). Rodar por timer, fora de qualquer sessão do Claude Code, resolve por construção o socket
  herdado que já matou `sdd run` lançado de dentro de uma sessão.
- **B — recusada.** Subcomando `sdd worker` dentro do `bin/sdd`: o arquivo passa de 9 000 linhas,
  ganharia uma sétima responsabilidade, e uma missão do kit na fase EXEC editaria o programa que
  o worker está executando.
- **C — recusada.** Daemon de longa duração: viola YAGNI (princípio 6: sem daemon), esconde estado
  em memória e pede supervisor.

### O tick

```
systemd timer (ex.: a cada 15 min, dentro da janela permitida)
 └─ sdd-worker tick --once
     1. lock da MÁQUINA (uma missão por vez); ocupado ⇒ sai 0 sem fazer nada
     2. para cada repo do registro (~/.config/sdd-worker/repos.conf):
          git fetch no clone dedicado
          missões com aprovacao: preenchida e sem PR mergeado
     3. escolhe UMA — prioridade do cartão (Jira/GitHub), senão a aprovada mais antiga
     4. no clone: checkout da branch da missão; ENV_UP_CMD quando a fase derivada vai precisar
     5. sdd run <missão>   (setsid, env -u CLAUDE*, sob o lock do checkout)
          rc 0 ⇒ PR aberto ⇒ etapa dos bots (W7)
          rc 3 ⇒ o pager (ON_ESCALATION_CMD) já avisou; a missão fica PARADA
          rc 2 ⇒ incompleta ⇒ o próximo tick continua
     6. ENV_DOWN_CMD (sempre, inclusive depois de rc 3), solta os locks
```

**Missão parada** volta à fila só quando o humano mexe nela — o sinal é um commit novo na branch
da missão depois da escalada. O worker **nunca** faz retry sozinho: `sdd retry` é a porta do
humano, e a nota `intervention:` que ela escreve pressupõe isso.

**Prioridade ordena, nunca admite.** Um cartão `priority:high` sem missão aprovada em disco não é
trabalho; uma missão aprovada sem cartão é trabalho com a prioridade mais baixa.

## 4. As missões, em ordem de dependência

Nada executa sozinho antes de o degrau anterior ter sensor. Cada Check abaixo é o critério de
aceite da missão, a refinar no `/sdd-plan` dela.

### W1 — um checkout, um dono

É a fase 1 do plano Astra e o conserto do incidente de 2026-09-03 18:45 (uma segunda sessão entrou
pela CLI, trocou a branch debaixo de um `sdd health` em curso e commitou numa branch mergeada —
seção 6 da rule `anatomia-do-agente.md`).

- Lock por checkout nas portas que mudam estado: `run`, `retry`, `close`, `health`, `approve`.
- Dono identificável (PID, host, comando, missão, início) e recuperação de lock órfão (processo
  morto ⇒ o lock é retomado, com linha no journal).
- **Check:** duas invocações simultâneas — só uma abre sessão; a recusada não troca branch nem
  toca artefato; lock de processo morto é recuperado; porta nova sem lock é pega por sensor (um
  probe por porta, a régua das escaladas).

### W2 — o clone é o mesmo repo

- A identidade do repo no ledger (`ledger_repo_root`) passa a sair do **remote** normalizado, não
  do caminho — senão a série do juiz racha entre o checkout do humano e o clone do worker, e o
  veredito do kit perde metade das missões.
- `sdd install` e `sdd preflight` num clone novo funcionam sem passo manual escondido.
- Segredos (`.env.idp` e afins) vêm de um lugar declarado por repo, **nunca** do git.
- **Check:** ledger escrito pelo checkout e pelo clone → mesmo `repo` (asserção **diferencial**);
  repo sem remote cai no comportamento de hoje, com o limite declarado.

### W3 — a missão chega ao clone, e o cartão é adotado

- **Contrato de entrega:** missão aprovada = branch da missão **empurrada** com `aprovacao:`
  preenchida. Conserta o `sdd approve` que hoje commita na branch padrão e só o `00-missao.md`
  (achado registrado no `TODO.md` por `b5e4ba8`, que chega à `main` com o PR #57).
- **`TRACKER=jira|github|none`** no `.sdd/config.sh` do alvo. `JIRA_ENABLED=true` sem `TRACKER`
  continua valendo `jira` (compatibilidade; missão em voo não quebra).
- O `00-missao.md` declara o cartão num campo só — `SQ-123` (Jira) ou `#54` (GitHub); a forma diz
  o rastreador, e a divergência com `TRACKER` reprova no gate de PLAN.
- A fase TICKET **adota** o cartão declarado nos dois rastreadores em vez de criar outro; com
  `github` ela usa `gh issue`, não a skill `ticket`. Cria a branch como hoje.
- O PR leva `Closes #N` (GitHub) ou a chave no título e no corpo (Jira) — o fechamento acontece
  no merge, como no PR #57.
- **Check:** fixture de cada rastreador com cartão declarado — nenhum cria cartão novo, os dois
  nomeiam o cartão no PR; missão aprovada e empurrada aparece no clone depois de um `fetch`.

### W4 — o operador do ambiente

- `ENV_UP_CMD` / `ENV_DOWN_CMD` por repo, portas e `APP_URL` próprias do clone.
- Quem executa é o **runner**, antes da fase que precisa; a sessão segue proibida de subir
  ambiente (o chapéu não ganha permissão nova).
- **Check:** com o stack do humano no ar, o do clone sobe em outra porta e `app-down` não dispara;
  `ENV_DOWN_CMD` roda também depois de rc 3; up que falha escala com kind próprio, nunca vira
  `app-down` de sessão.

### W5 — o worker que só olha

- `sdd-worker tick --once --dry-run`: registro de repos, descoberta de missões aprovadas,
  prioridade de Jira (prioridade, sprint ativo) e GitHub (rótulo `priority:*`, milestone), e a
  saída *"rodaria X no repo Y porque Z"*. Não executa nada, não escreve nada.
- É o primeiro estágio que o plano Astra pede para a agenda: listar candidatos antes de agir.
- **Check:** fixture de 3 repos com missões em estados diferentes — escolhe a certa e diz o
  motivo; missão parada (rc 3 sem commit novo) não é escolhida; rastreador fora do ar degrada
  para "sem prioridade", nunca para "sem trabalho".

### W6 — o worker que executa

- Tick real com systemd timer e janela de horário; lock da máquina; `sdd run` isolado (`setsid`,
  `env -u CLAUDE*`); tratamento de rc 0/2/3; missão parada fora da fila até commit novo.
- **Teto diário** do worker, acima do `BUDGET_MISSION_USD` de cada missão — o que para o worker
  inteiro quando a soma do dia estoura.
- Registro próprio (uma linha por tick, com o que escolheu e por quê) — observabilidade, não
  estado: nada no tick seguinte depende dele.
- **Check:** dois ticks sobrepostos — um sai 0 sem fazer nada; tick depois de rc 3 não re-tenta;
  o teto diário para o worker; morte no meio do tick é retomada pelo próximo sem efeito duplicado.

### W7 — os bots do PR

- Depois do rc 0: espera Codex/CodeRabbit (com timeout), trata os comentários numa leva (o fluxo
  do `codereview:coderabbit_pr`), re-roda a suíte, empurra, avisa "pronto para merge".
- Teto de **uma** leva: se os bots voltam com achado novo, escala — nunca laço.
- **Check:** PR de fixture com comentário conhecido é resolvido e o aviso sai; segunda rodada de
  achados vira escalada, não volta.

### Depois do roadmap

Paralelismo (uma missão por repo, depois worktree), claims no rastreador, e as fases 2–4 e 6 do
plano Astra (identidade e tarefa, handoff com aceite, memória e revisão rastreáveis, canal
externo) — só com demanda medida.

## 5. Métricas

Medidas pelo que o kit já tem (ledger de autonomia, `pipeline.log`), mais o registro do W6:

- custo por missão feita pelo worker × a mesma classe de missão rodada à mão;
- escaladas por missão, por `kind`;
- tempo entre "aprovada e empurrada" e "pronto para merge";
- **zero** colisões de checkout e **zero** execuções fora da janela ou acima do teto diário.

## 6. Riscos e limites declarados

- **O worker compra sessões sem ninguém olhando.** É por isso que ele só existe depois do
  `no-work` (PR #57) e só executa depois de W5 mostrar o que faria. Tetos: por fase, por missão
  (`BUDGET_MISSION_USD`) e por dia (W6).
- **Segredos num segundo checkout.** O clone precisa de `.env.idp` e credenciais de `gh`/Jira; W2
  declara de onde vêm, e nada disso entra no git.
- **Ambiente compartilhado.** Banco e serviços externos do stack do clone podem ser os mesmos do
  humano; W4 isola portas, não dados — se o repo precisar de dados isolados, é decisão daquele repo.
- **O kit fica de fora.** Missão do kit segue interativa; o registro de repos recusa o repo do kit.
- **Hooks não entram.** Seguem posteriores e complementares (plano Astra); nenhum gate, lock ou
  permissão do worker depende deles.
- **Rastreador é prioridade, não verdade.** Status de cartão nunca admite nem conclui nada.
