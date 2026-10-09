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

### Contrato e configuração

### Saída humana e cosmética

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
- **A entrada do índice na árvore do kit leva vírgula inicial (`@,100644:…`)** — decidido (D15): o mawk avalia o lado esquerdo de `ix[q] = (q in ix) ? … : e` antes do `in`, então toda entrada nasce com `,`; é representação interna, igual nas duas amostras que a guarda compara, e o motivo do `kit-touched` não a imprime — sem consumidor, não é achado — `bin/sdd:4003` (`kit_guard_tree`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **`kit_checkout_targets_run` com `REPO_ROOT` vazio responderia "recusado"** — decidido (D15): inalcançável, a recusa de identidade do `cmd_kaizen` vem antes e o `load_config` sempre publica a raiz; reabre se a função ganhar outro chamador — `bin/sdd:10963` (`kit_checkout_targets_run`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
