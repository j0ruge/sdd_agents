# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).
Formato, esqueleto e ciclo de vida: [`templates/todo.pt-BR.md`](templates/todo.pt-BR.md) — a
semente que o `sdd install` grava nos repos-alvo, uma variante por `OUTPUT_LANG`, com a forma
medida por `tests/check-todo.sh`. Os planos estacionados do kit moram na gaveta,
[`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`](docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md).

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

> **Catraca do volume — crescer é permitido, crescer calado não.** Quantos itens este arquivo
> carrega é o achado `todo-findings <N>` do `sdd health`, congelado em `tests/health-baseline.txt`.
> Reprova nos **dois** sentidos: número que subiu sem registro, e baseline que ficou para trás
> depois de uma faxina. Quem acrescenta item aqui **e** move a linha da baseline no mesmo commit
> está certo — o número tem dono e aparece no diff. Quem só acrescenta descobre no `sdd health`.
> Ela mora lá e não no `TEST_CMD` porque um teto dentro da suíte reprovaria toda missão em voo.
> ⚠️ A contagem sai de `tests/check-todo.sh`, nunca de um `grep -c '^- \[ \]'`, que não sabe
> onde a seção aberta termina.

## Aberto
<!-- sdd:open -->

### Sensores que faltam

- [ ] **`Closable by: deferred` passa no `gate_QA` sem a decisão humana escrita no bug** —
  `bin/sdd:1695` (`genre_line`) — a âncora 3 lê só a linha do campo; `sdd-qa.md` §5.1 e a ADR 0009
  exigem `## Decision`/`## Decisao` no corpo, e nada confere (a fixture `write_genre_bug` codifica o
  caso). Medido no sales_quote: a `qa-execution` diferiu um bug "porque o conserto mora no TODO", sem
  decisão, e o PR sairia sem ele. O alvo escreve `## Decisão`, com til. Direção: sem a seção fora de
  cerca, o bug conta como `agent`; mundos "sem seção bloqueia" e "til passa" e um mutante.
  — descoberto por `sessão interativa` na missão `20261005-mascaras-ncm-e-painel` (2026-10-05)

- [ ] **O guarda do kit é cego a kit já sujo editado de novo, e o BLOCKED não diz o que mudou** —
  `bin/sdd:3848` (`AUTONOMY_KIT_STAMP`) — o carimbo é `sha|dirty`: dirty→dirty no mesmo sha passa
  calado (fora dos DECLARED LIMITS), e o KIT-TOUCHED só imprime os dois carimbos. Medido no
  sales_quote: achar o autor exigiu `git status` no kit e caçar sessões com cwd nele. Direção: guardar
  o `status --porcelain` no arm, como o `HAT_STATUS_BEFORE`, e pôr no motivo as linhas novas e o
  `log before..after`; regime "kit já sujo e editado" e mutante irmão do `kit_touched_silent`.
  — descoberto por `sessão interativa` na missão `20261005-mascaras-ncm-e-painel` (2026-10-05)

- [ ] **O `--red` aborta sob `set -u` em bash 4.0–4.3 quando o Check não imprime nada** —
  `tests/check-checkpoint.sh:553` (`red_norm`) — `read -ra w` de uma saída vazia deixa o array vazio, e
  `"${w[*]}"` é "unbound variable" antes do bash 4.4: o caso que o `--red` existe para recusar (o Check
  mudo) vira aborto do sensor. Não reproduz no bash 5.2 daqui; o kit promete bash 4+. Direção:
  `${w[@]+"${w[*]}"}`, o idioma que o `check-todo.sh` já usa.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **Linha `|`-led com menos de cinco células some dos dois leitores do checkpoint** —
  `bin/sdd:600` (`if (n < 6)`) — `| I2 | slice | pending |` é linha da tabela no GFM, mas o
  `checkpoint_rows` a descarta em silêncio: o `pending` sai do `checkpoint_tally` e o `gate_EXEC` pode
  passar — a falha aberta da linha sem `|` inicial (c71913c), por outra forma. O `rows_of` do
  `check-checkpoint.sh` pula igual (`if (NF < 6) next`), e nem `--check` nem `--red` a acusam. Direção:
  dentro da tabela, linha que não dá cinco colunas é recusada pelo nome, como a sem `|` inicial.
  — descoberto por `claude` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **Relatório na ponta da base ainda conta se outra missão editar o checkpoint desta** —
  `bin/sdd:951` (`tip_add_carries_mission`) — desde 79b6f93 o commit da base que adicionou o relatório
  tem de mover `checkpoint.md` ou `checkpoint-notas.md` da missão; um commit de outra missão que traga o
  próprio relatório e edite também o checkpoint desta ainda passa, e o `gate_QA` fecha com a evidência
  alheia. Declarado na ADR 0015 §3, sem escritor conhecido. Direção: exigir que o checkpoint deixado
  por esse commit seja um blob que a branch da missão já teve.
  — descoberto por `claude` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **A suíte herda `GIT_DIR` de quem a chama, e os fixtures escrevem no repositório real** —
  `tests/run-all.sh:36` (`SDD_TEST_STATE`) — o `run-all.sh` isola o estado do runner, mas não limpa
  `GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE`. Sob `git bisect run` (e num hook `pre-push`, que o git chama
  com `GIT_DIR` exportado), o `git init --bare` do `check-gates.sh` reinicializou o kit como bare, o
  `git config user.email` gravou `[user] Fixture` e fixtures criaram tags — medido em 2026-10-05 21:17,
  reparado à mão. Direção: `unset` de todo `GIT_*` de repositório ao lado do `SDD_STATE_DIR`, com probe
  que rode um sensor sob `GIT_DIR` apontando para um repo-isca.
  — descoberto por `sessão interativa` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

### Contrato e configuração

- [ ] **`sdd run --phase PR` com só o carimbo faltando grava uma intervenção e não abre sessão** —
  `bin/sdd:8703` (`checkpoint_note_intervention`) — a nota "forced from the CLI" é commitada antes de a
  volta chegar à parada no carimbo (rc 2), e o `sdd autonomy --by-mission` conta uma intervenção numa
  corrida que não fez nada. Mesma forma da porta do PLAN, anterior ao lote. Direção: escrever a nota só
  quando a volta forçada abre sessão, ou declarar o limite nas duas portas.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **O `/sdd-plan` no próprio kit grava a missão no checkout que os `sdd run` dos alvos executam** —
  `commands/sdd-plan.md:15` (`HANDOFF_DIR`) — o `sdd` do PATH é este checkout, e o `kit_guard_check`
  de um run de alvo em voo lê o `status --porcelain` dele. Reproduzido numa cópia: kit limpo e um
  `00-missao.md` não rastreado gravado durante o EXEC do alvo → rc 3 e `KIT-TOUCHED` (`|false` → `|true`);
  controle rc 0. Direção: missão cujo repo é o kit é escrita e executada num worktree ligado, que não
  move o carimbo do checkout principal; probe `command:` no `check-hat.sh` sobre o comando.
  — descoberto por `sessão interativa` no planejamento do lote 5 (2026-10-06)

- [ ] **O `sdd kaizen` no checkout principal do kit escreve e commita onde os `sdd run` dos alvos executam** —
  `bin/sdd:10778` (`cmd_kaizen`) — a sessão KAIZEN escreve o veredito e o plano da próxima missão do kit e
  commita no `REPO_ROOT` de onde foi chamada. Chamada do checkout que o `sdd` do PATH resolve, com um
  `sdd run` de alvo em voo, é o mesmo `kit-touched` do `/sdd-plan` (lido no código, não reproduzido). A
  ADR 0016 §2 manda a missão do kit para um worktree ligado e não decide o `sdd kaizen`. Direção: recusar
  rodar nesse checkout nomeando o worktree, ou criá-lo; decidir com o humano.
  — descoberto por `claude` na missão `20261006-lote-5-o-que-o-lote-4-deixou` (2026-10-06)

### Saída humana e cosmética

- [ ] **Servidor deixado por uma fase segura o `sdd run` vivo e mudo depois do veredito** —
  `bin/sdd-coordination.py:337` (`waitpid`) — o supervisor é subreaper e espera até ECHILD (desenho,
  `docs/pipeline.md:53`), mas não diz por quem espera. Medido no sales_quote: o QA:exec reiniciou o
  backend com `nohup … &`, o runner imprimiu BLOCKED e ficou em `do_wait` até o `npm run dev` morrer.
  Nem agente nem `turn_rule` proíbem subir processo longo. Direção: worker colhido com filhos vivos
  imprime uma vez pid e cmdline de cada um; e uma frase no `turn_rule` da fase QA.
  — descoberto por `sessão interativa` na missão `20261005-mascaras-ncm-e-painel` (2026-10-05)

- [ ] **A parada no carimbo manda rodar o `sdd health` mesmo quando o carimbo é impossível** —
  `bin/sdd:8483` (`GATE_PR_STAMP_WHY`) — numa cópia do kit fora do git, ou com um caminho medido
  ausente, nenhum `sdd health` carimba aquela árvore; o remédio certo só vem dentro do motivo, na linha
  de cima, e as linhas `dim` repetem a ordem genérica. Parar está certo; a prosa engana. Lido do
  código, não reproduzido. Direção: quando o motivo é "impossível", trocar as linhas de remédio.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **A dica do `sdd status` pergunta "feita à mão?" de toda fase verde de missão rodada noutra máquina** —
  `bin/sdd:7023` (`status_unrecorded`) — o ledger é por máquina, então missão executada noutro
  computador não tem linha `session` aqui e toda fase verde recebe o `sdd note-manual`; quem seguir a
  dica grava como feita à mão uma fase que não foi. A frase diz "this machine's ledger" (declarado no
  plano do I19). Direção: calar quando o ledger local não tem nenhuma linha da missão.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **O `ok` do `sdd note-manual` diz que gravou a nota mesmo sem `checkpoint.md`** —
  `bin/sdd:11308` (`checkpoint_note_intervention`) — sem o arquivo o escritor volta 0 em silêncio, a
  linha `manual` vai para o ledger e a mensagem final afirma "the note in the checkpoint": rótulo sem
  artefato, na saída humana. Direção: o escritor publicar se escreveu, e o `ok` dizer só o que
  aconteceu.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

### Comentário e registro

### Idioma

### Custo e escala

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

## Decidido — não reabrir
<!-- sdd:decided -->
- **O laço de melhoria da sessão interativa não enxergaria o kit** — resolvido fora do kit, sem commit deste repo: `retrofit-watch` 0.2.0 (`j0ruge/skills@960e47b`) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd` (2026-10-01)
- **O `sdd preflight` não provaria que a sessão headless executa comando** — refutado: `bin/sdd:5168` manda rodar `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`, e sob o chapéu do executor desde 2026-09-06 (2026-09-25)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7030` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado como defeito sem causa e como fila: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a segura enquanto eles rodam, sem prazo; a trava é não-bloqueante, então quem chega depois não enfileira, recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:9943` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:195` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5031` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1773` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4670` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (2026-10-03)
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1050` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:94` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
