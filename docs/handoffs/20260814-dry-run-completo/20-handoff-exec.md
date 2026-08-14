---
missao: 20260814-dry-run-completo
fase: EXEC
status: done
sessao: 4f33f916-e481-476f-b7b4-06576d014523
data: 2026-08-14 04:20
gate: "`tests/run-all.sh` → exit 0 · 98 asserções ok, 0 falhas · 4 sub-suítes (bash -n, shellcheck -S warning, contrato dos templates, máquina de estados dos gates) + a nova `projeção do dry-run`; saída final `suíte verde`"
---

# Handoff — EXEC — dry-run mostra o pipeline inteiro

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

`sdd run <missão> --dry-run` agora projeta **todas** as fases pendentes (EXEC → QA → REVIEW →
DOCS → PR), cada uma com agente, modelo e prompt de boot — antes imprimia só a primeira e
parava. Único incremento do plano (I1) feito em TDD no commit `357b401`; suíte verde.
Sensor novo `tests/check-dry-run.sh` entrou em `tests/run-all.sh` e roda daqui em diante.
Esta foi a **primeira execução headless bem-sucedida da fase EXEC** do kit.

## Estado do repo

- **Branch:** `missao/20260814-dry-run-completo` — local, sem remoto configurado; push é da fase PR.
- **Último commit:** `357b401` `feat(runner): dry-run projeta o pipeline inteiro, nao so a primeira fase (I1)`
- **Working tree:** sujo apenas com os artefatos desta fase (`checkpoint.md` e este handoff),
  commitados logo em seguida.
- **Suíte:** `tests/run-all.sh` → **verde**, exit 0, 98 asserções ok / 0 falhas.
- **E2E:** `E2E_CMD` vazio no `.sdd/config.sh` — o kit é bash + markdown, não tem jornada de
  navegador. Não rodou por não existir.

## O que foi feito

- `357b401` — **I1: dry-run projeta o pipeline inteiro.** Três arquivos, um commit:
  - `tests/check-dry-run.sh` (novo, o sensor — escrito **primeiro**, falhou primeiro): monta um
    repo-fixture em `mktemp -d`, instala o kit, cria uma missão parada em EXEC e roda
    `sdd run <m> --dry-run`. A asserção central compara a sequência
    `EXEC=sdd-executor / QA=sdd-qa / REVIEW=sdd-reviewer / DOCS=sdd-docs / PR=sdd-publisher`
    extraída da saída — uma asserção que cobre quatro coisas de uma vez: quais fases aparecem,
    em que ordem, quantas vezes cada uma, e qual agente foi anunciado em cada bloco. Mais três:
    fase com gate satisfeito (TICKET, com `JIRA_ENABLED=false`) **não** entra na projeção; a
    árvore de arquivos e o `git status` do fixture são idênticos antes e depois (dry-run não
    escreve nada); e `--phase QA` continua imprimindo uma fase só.
  - `bin/sdd` — função nova `next_pending_phase()` e, no bloco `DRY_RUN` de `cmd_run()`, o
    `return 0` virou avanço para a próxima fase pendente via o cursor `dry_next`.
  - `tests/run-all.sh` — registra o sensor como sub-suíte permanente.

**Red observado antes do Green** (não é formalidade — é a prova de que o sensor testa o que se
acha que testa): o teste falhou com `obtido: EXEC=sdd-executor`, faltando as outras quatro
fases. As demais asserções já passavam antes da mudança, o que as torna guardas de regressão
das três coisas que o plano mandou não quebrar.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-dry-run.sh` | Sensor durável da projeção do dry-run; roda em toda `tests/run-all.sh` |
| `bin/sdd` | `next_pending_phase()` + cursor `dry_next` no bloco `DRY_RUN` de `cmd_run()` |
| `tests/run-all.sh` | Sub-suíte "projeção do dry-run" registrada |
| `docs/handoffs/20260814-dry-run-completo/checkpoint.md` | I1 `done` / `357b401` + notas de execução |

## Boot da próxima fase

A próxima fase é **QA**. O que ela precisa saber:

- **O diff é user-visible pela saída de um comando de CLI, não por tela.** Não há navegador,
  não há `APP_URL`, não há jornada de usuário em browser. `E2E_CMD` está vazio de propósito:
  a "jornada" deste repo é alguém digitar `sdd` no terminal e ler o que sai.
- **A jornada tocada é uma só:** `sdd run <missão> --dry-run` — "o que acontece se eu rodar
  isto?". Vale exercitá-la contra uma missão real e contra os estados de borda: missão parada
  em PLAN (deve imprimir a instrução interativa e sair 2, sem projetar nada — PLAN bloqueia
  todo o resto); missão com incremento `blocked` (deve escalar com exit 3, comportamento
  anterior preservado); missão completa (deve dizer "pipeline completo"); `--phase <FASE>`
  combinado com `--dry-run` (uma fase só).
- **Como subir o ambiente:** não há ambiente para subir. `cd` no repo e rodar
  `tests/run-all.sh` (exit 0) ou `bin/sdd run 20260814-dry-run-completo --dry-run`. O dry-run
  é seguro por construção — o próprio sensor afirma que ele não escreve nada no disco.
- **Comando de verificação manual usado nesta fase:**
  `bin/sdd run 20260814-dry-run-completo --dry-run` → lista EXEC, QA, REVIEW, DOCS, PR nesta
  ordem, com `sdd-executor`/`sdd-qa`/`sdd-reviewer`/`sdd-docs`/`sdd-publisher` e os modelos do
  `.sdd/config.sh` (`opus` nas quatro primeiras, `sonnet` na PR).
- **Ler primeiro:** `00-missao.md` (a métrica), o `checkpoint.md` inteiro **incluindo as notas
  de execução** — elas contam por que esta missão travou uma vez e o que a destravou.

## Pendências / Decisions for a Human

Nenhuma. Nada aqui depende de julgamento humano: não há política de UX, decisão de produto,
pagamento nem acesso externo envolvido.

## Riscos e não-feitos

- **A projeção é do estado de HOJE e não simula o efeito das fases** — decisão do grill, não
  omissão (`00-missao.md`, "Fora de escopo"). Consequência prática que a QA vai ver: com um
  incremento pendente, o dry-run lista EXEC uma vez só, embora o runner real fosse rodar uma
  sessão EXEC por incremento. É informação honesta, não completa. Se isso incomodar na prática,
  vira missão nova, não conserto aqui.
- **Gates rodam de verdade durante a projeção**, inclusive os que chamam `TEST_CMD`
  (`gate_EXEC`, `gate_QA`, `gate_REVIEW`). No kit isso custa ~2s e `run_check_cmd` memoiza por
  processo; num repo-alvo com suíte lenta, o dry-run herda essa lentidão. Não medido em repo
  grande — o piloto `sales_quote` é onde isso aparece, se aparecer.
- **A borda PLAN + `--dry-run` não tem asserção automatizada.** É comportamento pré-existente e
  intocado (o `return 2` acontece antes do bloco `DRY_RUN`), mas a afirmação de que continua
  intacto é minha leitura do código, não um sensor. Candidato natural a charter da QA.
- Nenhum outro comando do runner foi tocado: `status`, `why`, `phase`, `retry` e `preflight`
  estão exatamente como estavam.

## Achados fora de escopo

Nenhum novo nesta sessão. O achado que travou a sessão EXEC anterior — sessão headless sem
`--allowedTools` não consegue rodar `TEST_CMD` nem commitar — **já foi corrigido** por `2083680`
(fora desta missão) e esta sessão é a prova viva do conserto: rodou a suíte, viu o Red, viu o
Green e commitou. O `TODO.md` continua com a proposta de sensor durável para isso
(`sdd preflight` afirmando que uma sessão headless de fato executa `TEST_CMD`), que segue de pé
e **não** foi feita aqui — corrigir a causa não é o mesmo que instrumentar contra a recaída.
