---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 4
status: done
sessao: 1fcb66cc-ba5c-45cb-b4a3-26b0cf23d05e
data: 2026-11-18 09:45
gate: tests/run-all.sh no e0e6fcf verde (rc 0, 2140 ok, nenhuma linha FAIL, as mesmas 12 ocorrências de FAIL dentro de linhas ok, 13 min 43 s, anchors 854 de 854 aplicam); tests/check-worker.sh rc 0, 45 ok e 0 FAIL (44 probes); Check do R5 verde (1 0); WORKER_pager_root_only e WORKER_pager_file_misnamed mortos pelo sensor (--only, rc 1); shellcheck -S warning limpo no bin/sdd-worker e no tests/check-worker.sh; árvore limpa ao abrir; segredos (regex e gitleaks) sem achado no range e na missão; nota A em todo critério com sensor e B em Documentation e Overall (prosa LOW, para a DOCS); nenhum R novo; as letras subiram contra a r3 (Error Handling e Test Coverage, de B para A), com o commit de conserto 7fde4ed atrás
---

# Review — rodada r4 — O worker orquestrador

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Rodada forçada pela CLI depois do teto (`REVIEW_MAX_ITER=3`). Revisado o conserto da r3 (`83ef6e7..e0e6fcf`: o `7fde4ed` do R5) contra o `bin/sdd-worker` inteiro e o runner. O R5 fecha o achado #1 da r3: Check `1 0`, os dois mutantes morrem.
Nenhum achado de código para consertar, e nenhum `R<n>` novo. Error Handling e Test Coverage sobem de B para A. Documentation e Overall ficam em B por derivas LOW de prosa, que o gate tolera.
Para a DOCS (prosa só, lista completa na pendência 1): `docs/pipeline.md:1825`, o passo 1 do `delegation.md` da campanha do kit e as derivas da r3 que seguem abertas.
Para o dono (pendência 2): o conjunto largo do R3 e do R5 executa o `.sdd/config.sh` de todo worktree do repo, o que foi reproduzido; e um pager fora do commit pede uma linha em cada um dos 9 checkouts do kit.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O R5 reusa o `checkouts_of` do `budget`, de modo que as duas perguntas leem um conjunto só; a guarda `(no repo)` evita que o `checkouts_of ""` leia os worktrees do cwd; nenhum símbolo novo ficou sem leitor, e o `shellcheck -S warning` passa limpo. |
| Type Safety | A | O código novo não converte nenhum valor: o `ON_ESCALATION_CMD` é testado só por ser vazio, e o teto segue por `tonumber` e pela comparação com o assinado, como na r3. |
| Error Handling | A | O pager é conferido no config de todo checkout, o worktree da missão incluído. A parada nomeia o arquivo vazio, e o worktree podado cai no lado seguro (`assisted`), um limite declarado no comentário. |
| Security | A | Os segredos (regex e gitleaks) não acham nada no range nem na missão. O conjunto largo executa o config de worktrees onde nenhum `sdd run` roda (reproduzido, LOW, achado 3), um trade-off que vai ao dono. |
| Performance | A | O R5 abre um subshell de `config_key` por checkout (9 neste repo) a cada `level`; o sensor roda em segundos. |
| Test Coverage | A | A família `pager:` monta os regimes que a r3 cobrou: o worktree com missão, o sem missão, o inverso, o controle e o mundo fora de git. Os mutantes `WORKER_pager_root_only` e `WORKER_pager_file_misnamed` morrem por `--only` contra o `check-worker.sh`. |
| Documentation | B | A prosa do R5 confere com o código nas 28 unidades verificadas. Duas frases LOW de comportamento ficaram fora delas: `docs/pipeline.md:1825` e o passo 1 do `delegation.md` do kit. Seguem também as derivas da r3 (pendência 1). |
| **Overall** | **B** | O código fecha em A em todo critério com sensor, e o conserto da r3 está provado. O B vem só da prosa, que vai à DOCS sem rodada nova. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | Prosa, comportamento. A seção do diretório da campanha diz que "`HANDOFF_DIR` and `ON_ESCALATION_CMD` come from that root's `.sdd/config.sh`". Desde o R5, o `ON_ESCALATION_CMD` é lido no config de todo checkout do repo, e a regra 6 do mesmo arquivo (`:1878`) já diz isso. Só o `HANDOFF_DIR` continua lido na raiz. Achado pelo verificador e conferido no código | `docs/pipeline.md:1825-1826`; contradito por `bin/sdd-worker:331-336` |
| 2 | LOW | Prosa, comportamento. O passo 1 que o dono segue manda configurar o pager "commitado ou escrito também em cada worktree de missão". O código lê todo checkout do repo, guarde ele missão ou não: é o mundo `x` da família `pager:` (`tests/check-worker.sh`). Neste repo, `git worktree list --porcelain` dá 9 checkouts: o principal, seis worktrees de `chore/todo-*` sem missão da campanha, o do L1 (cujo `00-missao.md` declara `campaign: 20261117-zerar-as-issues`) e o desta missão. Nenhum dos 9 escreve a chave. Então commitar não chega aos worktrees cortados antes do commit, e escrever só nos de missão deixa os seis de `chore/` vazios: o `level` acima de `assisted` nomearia `/home/joruge/.wt/sdd_agents-todo-aviso-base/.sdd/config.sh` (o primeiro depois do principal na lista). O template (`templates/delegation.md:36`, "em cada worktree") está certo; a cópia do kit, não | `docs/superpowers/campaigns/20261117-zerar-as-issues/delegation.md:32-33` |
| 3 | LOW | Segurança, defesa em profundidade. O `config_key` executa (`. "$cfg"`) o `.sdd/config.sh` de todo worktree que o `checkouts_of` lista, inclusive o de uma branch onde nenhum `sdd run` vai rodar. O `budget` faz isso desde o R3, e o `level`/`allows` acima de `assisted` desde o R5, a cada ato do laço. Reproduzido numa cópia `mktemp -d`: um repo com a campanha do kit (prazo e tetos preenchidos) e um worktree `other`, sem missão, cujo config termina em `touch <MARK>`. `sdd-worker budget` responde `campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 40.00`, rc 0, e o `MARK` nasce. O git nunca executa o conteúdo de uma branch no checkout, e o worker passa a executar. Fica LOW: num repo de um dono só, o worktree é dele. Não vira `R<n>` porque reverter é escolher o conjunto estreito, o que desfaz a escolha da r3 e do R3 ("o lado mais largo é o seguro"). A decisão é do dono (pendência 2) | `bin/sdd-worker:267-273`, `:331-336`, `:506-515` |
| 4 | LOW | Prosa, forma. "any signed level above `assisted` when `ON_ESCALATION_CMD` is empty" não diz em qual checkout. Não é falso, só menos exato que a regra 6. Achado pelo verificador | `docs/adr/0022-the-worker-is-a-session-orchestrator.md:87` |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto. CRITICAL/HIGH → um `R<n>` cada;
> MEDIUM/LOW baratos → **um** `R<n>` de lote na rodada; caros → `TODO_FILE`; o que exige julgamento
> humano → seção de pendências, nunca `R<n>`; achado **só de prosa** (`Documentation` abaixo de A)
> → `TODO_FILE`, nunca `R<n>` — o gate tolera B ali, e foi esse laço que custou quatro rodadas.
>
> ⚠️ Nada de `|` cru na célula do Check — a tabela é lida com `awk -F'|'`. Herestring, como abaixo.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| — | nenhum | Nenhuma linha nova no `checkpoint.md`: os achados 1, 2 e 4 são só de prosa, e o 3 pede uma decisão do dono. |

## O que virou incremento

- Nenhum achado desta rodada virou `R<n>`. Os achados 1, 2 e 4 são prosa e vão à DOCS desta missão
  (pendência 1), pela mesma rota das r1 a r3. Um item no `TODO.md` nasceria e morreria no mesmo PR,
  e o chapéu da DOCS escreve `docs/**`, `config/schema.md` e `templates/**`. O achado 3 vai ao dono
  (pendência 2).
- #1 da r3, o pager do worktree da missão: fechado em `7fde4ed`. O Check do `R5` responde `1 0` no
  `e0e6fcf`. O `effective_level` lê o `ON_ESCALATION_CMD` de cada checkout do `checkouts_of "$root"`,
  o da campanha primeiro (`bin/sdd-worker:331-336`), atrás de uma guarda própria para o mundo fora
  de git (`:321-323`). Os dois mutantes do catálogo morrem por `--only` contra o `check-worker.sh`
  (rc 1, 20 s e 22 s). O sensor sozinho dá rc 0, 45 linhas ok, nenhum `FAIL` e
  `worker verbs: 44 probe(s)`.
- O pedido da r3 ao executor ("feche a classe, não o sítio"): conferido aqui. O `config_key` tem
  quatro chamadores no `bin/sdd-worker`. O `ON_ESCALATION_CMD` (`level`) e o `BUDGET_MISSION_USD`
  (`budget`) são lidos em todo checkout. O `HANDOFF_DIR` (`campaign_mission_dirs`) segue lido só na
  raiz: a r3 o deixou sem reprodução, e esta rodada também não construiu esse mundo (abaixo). O
  único estado que o runner lê fora do config é o ledger, por `SDD_STATE_DIR` (abaixo).

## O que foi refutado

- **O `config_key` de dois argumentos deixa passar o valor que quem chama exporta**, então o `level`
  de uma sessão que exporta `ON_ESCALATION_CMD` passa onde o arquivo do checkout cala a chave.
  Medido: com um config que não cita a chave e o valor exportado, a leitura de dois argumentos dá
  `[from-caller]`; com `ON_ESCALATION_CMD=""` no arquivo, dá `[]`; e a de três argumentos dá o
  `<env>` (`[40]`), nunca o exportado. Não é defeito. O `sdd run` que o comando lança herda o mesmo
  ambiente (`setsid nohup env -u CLAUDECODE`, `commands/sdd-worker.md:112`), então o worker e o
  runner leem o mesmo pager. E a frase "the caller's own value of <key> never reaches that reading"
  (`bin/sdd-worker:266`) se refere à leitura com `<env>`, onde é verdade.
- **Um `SDD_STATE_DIR` escrito num `.sdd/config.sh` tiraria do `budget` o ledger que o runner
  escreve**, porque o `autonomy_log_path` do runner o lê depois de carregar o config. Não levantado:
  o `config/schema.md:355-360` declara que ele não é chave de config ("deliberately not a
  `.sdd/config.sh` key"), e um arquivo que o escreve quebra o contrato documentado.
- **Um config de worktree que não faz parse daria ao `level` um pager que o runner não usa.** O
  `load_config` do runner roda `bash -n` e morre antes de qualquer sessão (`bin/sdd:145`). Não há
  corrida sem ninguém olhando nem rc 3 a avisar, e o `sdd run rc=` da sessão diz que parou.
- **O `HANDOFF_DIR` lido só na raiz** continua como a r3 o deixou: pede mudar a chave no meio de uma
  campanha, e este mundo não foi construído. Hipótese sem reprodução não vira `R<n>`.

## Achados fora de escopo

- Nenhum registrado no backlog nesta rodada. As derivas de prosa são desta missão e vão à DOCS dela
  (pendência 1). O achado 3 é uma decisão de desenho da própria missão (pendência 2).

## Pendências / Decisions for a Human

1. **Para a DOCS, prosa só, nenhum `R`.** As derivas abaixo são LOW e foram todas conferidas no
   código ou no disco no `e0e6fcf`.
   - Desta rodada: os achados 1 (`docs/pipeline.md:1825-1826`, só o `HANDOFF_DIR` é lido na raiz) e
     2 (`delegation.md:32-33` da campanha do kit, onde é "cada worktree do repo", não "de missão",
     e o commit não chega ao worktree cortado antes dele). Também o achado 4, de forma
     (`docs/adr/0022…:87`).
   - Abertas desde a r3, e o R5 não as tocou:
     - "before any file is read" em `docs/pipeline.md:1933` e `config/schema.md:290`, e "antes de
       ler qualquer arquivo" em `templates/delegation.md:49`. O `budget` lê o `delegation.md` antes
       de parar; o certo é "before any `.sdd/config.sh` is read".
     - A dica do `budget_mission_usd:` em `templates/delegation.md:6` e na cópia do kit ainda fala
       de um `.sdd/config.sh` só e não diz que zero para.
     - A linha órfã "Antes de assinar, apague a linha" em `templates/delegation.md:50`.
     - O "no such key" sem antecedente em `commands/sdd-worker.md:143`.
   - A conta de mutantes do `20-handoff-exec.md` já está certa (41), então esse item da r3 fechou.
2. **O conjunto largo do R3 e do R5 tem dois custos, e decidir entre ele e o estreito é do dono.**
   O conjunto largo é todo checkout do repo. O estreito é o checkout da campanha mais os worktrees
   que guardam uma missão dela, a alternativa que a r2 e a r3 deixaram no Check.
   (a) **Execução.** O worker executa o `.sdd/config.sh` de todo worktree, a cada `budget` e a cada
   `level` acima de `assisted`, inclusive o de branches onde nenhum `sdd run` roda (achado 3,
   reproduzido).
   (b) **Onde mora um pager fora do commit.** O runner lê só o `.sdd/config.sh` (`bin/sdd:98`,
   `:147`), e ele é rastreado. Neste repo, um pager fora do commit vira uma linha modificada num
   arquivo rastreado em cada um dos 9 checkouts, e todos ficam sujos. Seis deles (os de `chore/`)
   não guardam missão da campanha, e o conjunto estreito os deixaria de fora. Hoje, no kit, funciona exportar o `ON_ESCALATION_CMD` no ambiente da sessão orquestradora:
   o config do kit não cita a chave, e o runner herda esse ambiente (refutação 1). Num alvo vindo do
   starter não funciona, porque `ON_ESCALATION_CMD=""` no arquivo vence o ambiente.
   Não medi o efeito de um `.sdd/config.sh` sujo no worktree da missão sobre o bloco de sobras do
   boot de cada fase. Fica como hipótese.
   O que está em aberto: um config local não rastreado no runner, a rota do ambiente escrita na
   prosa, ou o conjunto estreito. Qualquer dos três mexe no runner ou na decisão da r3.
3. **O laço fecha nesta rodada.** As letras andaram: Error Handling e Test Coverage foram de B a A,
   e Documentation e Overall ficaram em B. O movimento tem atrás o commit de conserto `7fde4ed`, e
   não só o relatório. A régua do dono no PR (A em todo critério, decisão 9) é mais estrita que o
   gate. Esta rodada não grava `reviewed_head:`, que é chave das rodadas do worker, não da fase
   REVIEW do runner.
4. **O lado do runner** segue como as r1 a r3 o deixaram: o R1, o R3 e o R5 só fazem o worker falhar
   fechado. Fazer a delegação valer num alvo cujo config fixa a chave pede mexer na precedência de
   config do `bin/sdd`.
