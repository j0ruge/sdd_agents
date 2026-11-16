# O worker — o merge delegado, como rodou na noite de 2026-11-16 (caderno)

> Companheiro do [roadmap do worker](2026-09-22-o-worker-roadmap-design.md) e do
> [caderno de campo](2026-10-09-o-worker-caderno-de-campo.md). Registra, a pedido do dono, o fluxo
> que rodou com ele ausente, no `dotp-remake` e no kit, do plano aprovado até o merge. O registro
> serve para o fluxo virar **opção** do kit quando o worker noturno sair do estacionamento. Hoje o
> D5 do roadmap para o worker no "pronto para merge" e recusa "até o merge" sem ADR. Este caderno é
> o insumo dessa ADR, não a decisão.
>
> Horários em BRT (UTC−3), lidos dos timestamps do GitHub.

## 1. A delegação

- **A palavra do dono**, em 2026-11-16 por volta de 01:45, antes de sair: *"depois de tudo ok, pode
  dar merge no meu lugar"*. Antes, na mesma noite, ele deu outra: *"quando fechar a parte um, já
  pode … planejar a entrega dois … pode usar no sdd-plan o Fable pra planejar e aceitar as opções
  recomendadas"*.
- **Alcance:** os PRs abertos naquela noite. Eram o da missão 5a (`dotp-remake` #32) e os dois PRs
  de achado do kit (#408 e #409). Entrava também o PR de docs do pós-merge da 5a (#33), se passasse
  pelo mesmo fluxo.
- **O que ficou fora:** `sdd approve`, `sdd run`, push direto na `main`, apagar branch ou worktree e
  o fast-forward do checkout principal. Nada disso foi proibido por escrito; a sessão leu a
  delegação pelo que ela dizia, e não por tudo o que ela não vetava. O pós-merge, que o dono
  costumava empurrar direto na `main`, virou o PR #33.
- **Registro:** a sessão gravou a delegação numa memória do agente, com o que conta como "tudo ok"
  em cada PR e a regra de parada. Depois do último merge, marcou-a **usada e esgotada**: ela não
  vale para PR novo. Sem essa marca, a sessão seguinte herdaria uma autorização vencida.

## 2. O fluxo, passo a passo (a 5a)

| # | Passo | Quem | Evidência |
|---|---|---|---|
| 1 | PLAN: o planner roda no Fable, e o grill aceita a opção recomendada em toda pergunta, pela autorização prévia do dono | sessão (o relay do `/sdd-plan`) | `8 (recommended) of 8` na 5b; `6 (recommended) of 6` na 6a |
| 2 | Aprovação: remedir `--check` e `--red`, mostrar o plano e a contagem do grill, e só então `sdd approve`, com a palavra do dono | dono | o `y` do `sdd approve` não diz quem o digitou; quem decide é a palavra do dono na sessão |
| 3 | `sdd run` no worktree da missão: EXEC → QA → REVIEW r1 → DOCS → PR | runner | a run começou às 21:51 de 11-15, e o PR #32 abriu às 02:56 (US$ 81,03 em 17 sessões) |
| 4 | Merge da `main` na branch da missão, que tinha andado durante a run. O conflito ficou só nas âncoras do `TODO.md`, resolvido à mão, e a suíte rodou de novo no tree mesclado | sessão | `41de7ef` |
| 5 | Consertar o que a r1 deixou abaixo da régua do dono: Documentation em B, e o dono exige A | sessão | `6457ffd`, `1441968` |
| 6 | `/codereview` só sobre o delta desde o último head revisado, sem o que veio da `main`, até nota A em todo critério | sessão | r2: 1 MEDIUM de prosa, consertado remedindo os números (§4, M6); r3: 2 LOW; r4: 0 achado, A no `df202f2` |
| 7 | Atualizar o corpo do PR com as rodadas | sessão | pelo `gh api -X PATCH`, porque o `gh pr edit` quebra com Projects classic |
| 8 | Bots no head final: `@codex review`, mais CodeRabbit e Copilot | sessão | ver a §4, M1 e M2 |
| 9 | Merge: `gh pr merge 32 --merge --match-head-commit <sha completo>` | sessão, pela delegação | `7724b3f`, às 04:14 |
| 10 | Pós-merge (roadmap, `TODO.md`, `KAIZEN_LOG.md`) num PR próprio, com rodada de `/codereview` (2 LOW consertados, verificação limpa) e Codex | sessão | #33, `fb68631`, às 04:21 |

**Os PRs do kit (#409 e #408)** seguiram a receita do `docs/finding-prs.md`: merge da `origin/main`,
recontar a catraca, as três medidas do `check-todo.sh`, push e bots. O merge foi o mesmo
`--merge --match-head-commit`, sem carimbo do `sdd health`, porque eram achados de missão de outro
repo. O #409 entrou às 03:26. O #408 precisou de outro merge da `main` depois disso (catraca
78 + 2 → 80) e entrou às 03:30.

## 3. "Tudo ok": o checklist que decidiu cada merge

Cada item foi lido de um artefato, nunca de memória:

1. O `/codereview` dá nota A em todo critério, Documentation inclusive, no head que vai ser
   mergeado. O piso B do `REVIEW_PROSE_CRITERIA` não basta para este dono.
2. O Codex deixa o resumo `Completed` ("Didn't find any major issues") com o sha curto do head
   atual (C11 do caderno de campo), e não há P1 nem P2 aberto.
3. O CodeRabbit não deixa thread aberto.
4. O `mergeable` está limpo e o head do PR é o sha revisado. O `--match-head-commit` fecha a janela
   entre conferir e mergear.
5. O merge é por merge commit, nunca squash (C7).
6. **Regra de parada:** com nota abaixo de A depois de 3 rodadas, ou um P1 do Codex sem conserto,
   aquele PR não é mergeado e o caso vai ao relatório. Nesta noite nenhum PR parou nela.

As pendências do corpo do PR ("Decisions for a Human") que o próprio PR declara não bloqueantes
ficaram abertas e não seguraram o merge. O aceite visual da 5a (a Métrica 5) o dono fechou antes de
sair, ao ver as capturas.

## 4. Fatos medidos na noite

| # | Fato | Evidência | Para a opção |
|---|---|---|---|
| M1 | **Bot que não revisou parece ter revisado.** O Copilot publicou review com estado `COMMENTED` no #32 e no #33, e o corpo dizia "unable to review … insufficient remaining quota". No `dotp-remake`, o CodeRabbit está no plano Free: só gera resumo e walkthrough, sem revisão linha a linha, e respondeu ao `@coderabbitai review` com "Review finished". Num PR do kit, ele bateu no limite por hora ("Review limit reached") e revisou 4 min depois. | `gh api repos/j0ruge/dotp-remake/pulls/32/reviews`; comentários do CodeRabbit no #32 | O W7 lê o **corpo**: cota, limite ou plano Free contam como "não revisou", uma lacuna declarada no PR, nunca como "limpo". Falta decidir se "não revisou" bloqueia. Nesta noite não bloqueou: bastaram o Codex limpo e o `/codereview` em A |
| M2 | **O Codex respondeu em minutos:** 2 min 42 s no #32 (06:26:01Z → 06:28:43Z) e 1 min 12 s no #33. No `sales_quote`, o C6 mediu um achado que chegou a 51 min. | `gh api repos/j0ruge/dotp-remake/issues/{32,33}/comments` | A espera de ≥ 60 min do W7 é um teto, não o tempo típico |
| M3 | **A `main` anda durante a run.** A run da 5a levou cerca de 5 h, e nesse meio a `main` ganhou commits. O PR precisou de merge da `main`, com conflito, antes da revisão final. | `41de7ef` | O worker precisa do passo "trazer a `main` e rodar a suíte de novo" antes do merge. A re-revisão tem de saber deixar de fora o que veio da `main`, e a skill `codereview` não tem esse caminho (candidata a retro) |
| M4 | **Um merge invalida o PR seguinte.** O merge do #409 mudou a base do #408: novo merge da `main`, catraca recontada, push e bots de novo. | `8905bd0` | Uma fila de merges re-valida cada PR depois do merge anterior. Nunca mergear em lote |
| M5 | **A régua do REVIEW do pipeline é mais baixa que a do dono.** A r1 do pipeline deu Documentation B, que o `REVIEW_PROSE_CRITERIA` aceita, e o dono exige A. Foram 3 rodadas à mão (r2 a r4) depois do PR aberto. | `40-review-r1.md` a `40-review-r3.md` da 5a; o corpo do #32 | A régua do merge delegado é configuração do alvo, e o laço de rodadas tem teto (3) |
| M6 | **Consertar prosa pode exigir remedir.** O MEDIUM da r2 eram números citados sem a saída guardada. O conserto foi rodar de novo uma sonda descartável (13 de 2 397 paradas com bloqueio) e guardar a saída. | `record-r2-medidas.md` da 5a, `d45dbe1` | O worker precisa poder rodar uma sonda fora do `TEST_CMD` e guardar a evidência |
| M7 | **O pós-merge vira PR.** Sem push na `main`, o pós-merge (roadmap, `TODO.md`, `KAIZEN_LOG.md`) passou por PR próprio. A rodada do `/codereview` veio antes de abrir o PR; depois de aberto, o PR esperou só o Codex e ficou 2 min 29 s até o merge. | #33 (07:19:30Z → 07:21:59Z) | A opção nunca precisa de push na `main` |
| M8 | **Um grill sem o dono pode recomendar sobre evidência errada.** Na 6a, uma recomendação se apoiou num número errado: "o decodificador de TDX recusa 25,5 %", quando eram 28 de 9 176. O próprio planner achou o erro depois, e a confirmação voltou ao dono. | `00-missao.md` da 6a (`dotp-remake`) | Aceitar "as recomendadas" sem humano chega perto do D1 recusado. O approve tem de mostrar a evidência que mudou desde o grill |
| M9 | **A execução não viu as próprias capturas.** Na 5a, o `Read` da imagem que o EXEC gerou foi negado. A primeira carta desenhada passou pelo gate sem que ninguém olhasse, e o dono achou o visual feio na manhã seguinte. | journal da 5a | Aceite visual não é trabalho de worker: fica com o humano, como a Métrica 5 |

## 5. O que a opção precisaria decidir (perguntas, não decisões)

- **Onde se delega.** Nesta noite foi por palavra, para PRs nomeados e com prazo implícito
  ("hoje"). No kit, pode ser um campo do `00-missao.md` gravado pelo `sdd approve`, para o humano
  delegar no momento em que aprova, ou uma config do alvo. Delegação sem prazo nem alcance vira
  permissão permanente.
- **O que é "tudo ok" em cada alvo:** a régua do `/codereview`, quais bots contam, se bot sem cota
  bloqueia (M1) e o teto de rodadas (M5).
- **O merge da `main` na branch** antes do merge (M3): se é automático, com a suíte de novo, e o
  que fazer com conflito. Escalar sempre, ou só quando o conflito sai dos arquivos mecânicos, como
  as âncoras do `TODO.md`?
- **A ordem da fila** de merges (M4).
- **O que nunca entra:** `sdd approve`, apagar branch ou worktree, push na `main` e aceite visual
  (M9). O pós-merge entra como PR (M7).
- **A trilha:** cada merge delegado deixa no PR o checklist da §3 preenchido com os shas, e a
  delegação fica marcada como esgotada depois do último merge, como a marca "usada e esgotada" da
  memória fez nesta noite.
