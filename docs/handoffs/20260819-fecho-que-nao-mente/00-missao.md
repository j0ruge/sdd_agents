---
missao: 20260819-fecho-que-nao-mente
titulo: O caminho que certifica o fecho de uma missão para de afirmar o que não mediu
data: 2026-08-19
versao: n/a — JIRA_ENABLED=false neste repo
branch: fix/fecho-que-nao-mente
aprovacao:
ddd: n/a
---

# Missão — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> Plano **kaizen-born**: escrito pela sessão `sdd kaizen` de 2026-08-19, ao lado do
> [`05-verdict.md`](05-verdict.md), **sem humano presente**. Por isso `aprovacao:` nasce vazia e
> só `sdd approve 20260819-fecho-que-nao-mente` a preenche — o laço kaizen não aprova o próprio
> dever de casa (D3/CONTEXT.md, cobrado pelo `plan_approves_itself()`).

## Problema (Gemba)

Quatro instrumentos decidem se uma missão do kit **fechou**. Os quatro foram sondados nesta sessão,
contra a `main` em `7957a85`, e **três deles falharam abertos na hora** — afirmaram ter medido o
que não mediram:

1. **`sdd health` diz `ok` sobre catálogo com sobrevivente.** `bin/sdd:1818` exige só
   `0 known gap` e **nunca** `caught == total`. Reproduzido nesta sessão:

   ```
   $ s="score: 103 caught, 0 known gap(s), of 104"
   $ grep -qE '^score: [0-9]+ caught, 0 known gap' <<< "$s" && echo ok
   REPRO: 'score: 103 caught, 0 known gap(s), of 104' -> health says ok
   ```

   É a linha que o operador lê no comando que, desde `4c86712`, é o **dono único** do catálogo.

2. **`gate_REVIEW` lê a coluna `Grade` e nunca a `Rationale`.** `bin/sdd:529` — o `awk` extrai
   `crit = f[2]; grade = f[3]` e o campo `f[4]` não é tocado. Reproduzido nesta sessão com uma
   tabela de `A` em toda linha e `PREENCHER` em toda justificativa: o extrator devolve **vazio**,
   que é o valor de "nenhum critério ofende" — o gate passa. A instância viva está no próprio
   repo: `docs/handoffs/20260818-lote-facil/40-review-r1.md:8` registra, no campo `gate:`, que a
   r1 deixou `PREENCHER` nas **sete** justificativas.

3. **`tests/run-all.sh --list` imprime linha que não é passo e sai 0 tendo rodado nada.**
   Reproduzido com um `PATH` sem `shellcheck`: a saída traz `  (linter absent — skipped)` entre os
   14 passos. Um `TEST_CMD="tests/run-all.sh --list"` faria **todo gate do runner** passar
   instantaneamente, com um log de aparência perfeitamente plausível.

4. **Nada automático roda o catálogo.** `tests/run-all.sh:23` — a mutação é opt-in desde
   `4c86712` e este repo não tem `.github/workflows/`. Não é temor: aconteceu entre os PRs #12 e
   #13. O conserto `f6ecf73` apodreceu a âncora de `mut_HEALTH_grade_table_blind`, os gates de
   REVIEW e PR rodaram a suíte rápida, responderam verde, e a `main` recebeu
   `score: 103 caught of 104`. Só o `sdd health` viu — dias depois, porque alguém digitou.

Os quatro são o mesmo mecanismo, e é o mecanismo que este repo mais paga: **rótulo aceito no lugar
de artefato**, dentro dos próprios instrumentos que existem para recusar rótulo.

## Métrica

Fato binário verificável, quatro linhas:

1. `sdd health` sobre um `score:` com sobrevivente responde `health_bad`, não `ok` — asserção
   nova em `tests/check-health.sh`, verde.
2. `gate_REVIEW` recusa uma tabela com `A` em toda linha e placeholder em toda `Rationale` —
   asserção diferencial em `tests/check-gates.sh` (tabela preenchida passa, tabela com placeholder
   reprova), verde.
3. `tests/run-all.sh --list` imprime **só** passos, e `sdd health` reprova um `TEST_CMD` que
   carregue `--list` — asserções novas, verdes.
4. `gate_PR` reprova, no repo que tem catálogo, enquanto não houver carimbo de catálogo verde
   sobre o conteúdo atual de `bin/` `tests/` `templates/` `config/` — asserção diferencial em
   `tests/check-gates.sh` (com carimbo passa, sem carimbo ou com carimbo velho reprova), verde.

E o fecho, uma vez: `./bin/sdd health` responde `kit healthy` com `score: N caught, 0 known gap(s),
of N` e `N` maior que o de hoje em pelo menos **4** (uma mutação por incremento).

## Resultado esperado

Depois desta missão, nenhum dos quatro instrumentos que certificam o fecho de uma missão consegue
dizer "verde" sem ter medido. O `sdd health` compara os dois números do próprio `score:`; o
`gate_REVIEW` recusa selo com justificativa de placeholder; o `--list` da suíte não pode mais ser
confundido com uma execução; e o catálogo de mutação ganha um dono automático — o `gate_PR` passa
a exigir **evidência em disco** de que ele rodou verde sobre este conteúdo, em vez de esperar que
alguém se lembre de digitar o comando.

Quatro achados saem do `TODO.md` com `RESOLVIDO por <hash>` no corpo, e quatro mutantes novos
entram no catálogo.

## Fora de escopo

- **Re-derivar as 33 âncoras do `TODO.md`** (item vivo, § Comentário e registro). O handoff
  humano de 2026-08-19 a chamou de bloqueadora; a triagem desta sessão **mediu o contrário** e
  registrou a medição no `01-plano.md`: as âncoras de que este lote precisou estavam certas. Além
  disso, a missão passada provou que re-derivar cedo é desperdício — a própria missão move as
  linhas depois. Fica para a missão seguinte, feita **depois** desta, não antes.
- **CI rodando `tests/run-all.sh --with-mutation`.** É a outra saída que o item nomeia, e depende
  de uma decisão de custo que é humana (repo privado, catálogo de ~17 a 21 min por rodada). O I4
  fecha o achado por dentro do kit, sem infraestrutura (YAGNI); se o humano quiser CI depois, o
  carimbo continua valendo como gate local.
- **O `check-templates.sh` sem auto-teste** e as famílias grandes do `check-todo.sh` e do
  `check-health.sh`. Permanecem no `TODO.md`, intocadas.
- **O conflito entre o ciclo de vida do `RESOLVIDO por` e a catraca do backlog** (§ Contrato e
  configuração). Esta missão segue o **cabeçalho escrito** do `TODO.md` — item fechado fica, com a
  caixa desmarcada e o hash no corpo, até o PR mergear —, e por isso `todo-findings` não desce.
  Qual das duas convenções vence continua sendo decisão do humano.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

⚠️ Aqui a tabela é **informativa, nunca liberatória**: plano kaizen-born nunca carrega
`aprovacao: auto`, mesmo com os cinco ✅. A tabela existe para o humano ler antes de decidir.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✗ | Não houve grill: sessão headless, sem humano. Duas decisões de desenho foram **fixadas por mim** e estão nomeadas em `01-plano.md` § Arquitetura (o carimbo em vez de CI; o escopo por artefato `tests/check-mutation.sh` em vez de identidade de repo). São exatamente o que o humano deve revisar antes de aprovar. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabela K1–K8 abaixo, toda ✅; DDD `n/a` com justificativa. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | `01-plano.md` § Contexto verificado traz as 4 reproduções verbatim, os `arquivo:linha` conferidos hoje contra `7957a85`, e o nome exato de cada asserção nova (contrato entre o sensor e o Check). |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 4 de 4, todos ancorados em `^  ok    ` e nenhum com `\|` na célula, como `templates/checkpoint.md` exige. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `.sdd/config.sh:28` → `JIRA_ENABLED=false`. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os quatro defeitos foram **reproduzidos nesta sessão** contra `7957a85`, não lidos do `TODO.md`. |
| K2 | Problema declarado com métrica | ✅ | Quatro fatos binários + o fecho `caught == total` com `N` maior em 4. |
| K3 | Desperdícios identificados e cortados | ✅ | Cortado: re-derivar âncoras antes da missão que move as linhas (desperdício medido em `20260818-lote-facil`); cortado: rodar o catálogo **dentro** do gate (foi o que tornou a REVIEW insatisfazível em `4c86712`) — o gate lê carimbo, não roda catálogo. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 4 incrementos, cada um com sensor próprio na suíte rápida. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check ancora em `^  ok    <asserção>` da stdout do sensor; o I4 é literalmente a troca de um rótulo ("alguém rodou") por um artefato (o carimbo). |
| K6 | Jidoka — o que para a linha está definido | ✅ | Catálogo com sobrevivente para o `sdd health` (I1); ausência de carimbo para o `gate_PR` (I4); qualquer sensor vermelho para o `TEST_CMD` de todo gate. |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Quatro asserções novas na suíte + quatro mutantes no catálogo; `CLAUDE.md` e `docs/pipeline.md` atualizados na fase DOCS. |
| K8 | Registro no KAIZEN_LOG | ✅ | Antes/depois medido: `N` do catálogo antes × depois, e as 3 reproduções que deixam de reproduzir. |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão mexe em gates de shell e sensores da suíte, não em
aggregate, bounded context, evento ou contrato entre módulos.`

## Decisões do grill (não re-litigar)

Não houve grill. As decisões abaixo foram tomadas **por esta sessão** e estão abertas à revisão do
humano na aprovação — não são consenso herdado:

1. **O I4 fecha o achado com carimbo, não com CI.** CI é a outra saída que o item nomeia, custa
   decisão de orçamento humana e infraestrutura que o kit recusa por YAGNI; o carimbo fecha o
   mesmo buraco por dentro e não impede CI depois.
2. **O gate do carimbo é escopado por artefato (`tests/check-mutation.sh` existe aqui?), nunca por
   identidade de repositório.** A porta por identidade que já existe (`cmd_kaizen`) tem bug vivo
   em worktree, registrado no `TODO.md`; herdá-lo seria comprar um defeito conhecido.
3. **O carimbo chaveia no conteúdo de `bin/ tests/ templates/ config/`, nunca no `HEAD`.** A fase
   PR commita markdown, o que moveria o `HEAD` e invalidaria um carimbo ainda perfeitamente
   válido — o catálogo não mede markdown de handoff.
4. **O I1 vem antes do I4, e a ordem é dependência real, não gosto.** Carimbar antes de consertar
   o veredito do `score:` seria gravar em disco a certificação de um catálogo com sobrevivente.
5. **A re-derivação das âncoras fica para a missão seguinte.** Medição em `01-plano.md`; contraria
   o handoff humano de hoje de propósito e com evidência.

## Pendências para o humano

1. **Aprovar ou recusar as decisões 1, 2 e 3 acima** — são de desenho e nasceram sem você.
2. **A convenção do `RESOLVIDO por` × a catraca do backlog.** Esta missão segue o cabeçalho
   escrito (o item fechado fica até o merge), enquanto a missão passada apagou na hora
   (`6136d39`). Enquanto as duas coexistirem, `todo-findings` significa coisas diferentes em
   missões diferentes. O item está no `TODO.md`, § Contrato e configuração.
3. **CI**, se você quiser a segunda metade da rede do I4 — a decisão de custo é sua.
