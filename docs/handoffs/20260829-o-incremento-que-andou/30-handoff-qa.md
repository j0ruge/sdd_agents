---
missao: 20260829-o-incremento-que-andou
fase: QA
status: done
sessao: e41c13ea-bbd5-4fac-a546-72be879173ca
data: 2026-08-30 04:10
gate: "**Projeto sem interface** (`E2E_CMD=\"\"`, `APP_URL` ausente): não há relatório datado a exigir, e a evidência da jornada andada é este campo. **4 jornadas andadas na linha de comando, uma por uma.** (1) `./bin/sdd autonomy --all-repos --by-mission` → `sdd_agents/20260816-runner-sem-dividas  15 session(s) · 14 advanced · 1 churned · 0 idle` (o alvo exato da métrica 2; o `1` é a r1 do REVIEW, churn de verdade), e as 9 sessões EXEC do laço desenhado auditadas linha a linha com a definição do **próprio runner** extraída por `sed` de `ledger_outcome_defs` — `pb=10→pa=9`, `9→8`, … `2→1`, todas `src=gate_why`, todas `advanced`. (2) `./bin/sdd autonomy --all-repos` → `10` versões a `100% waste` de `112` (era `49 de 107`; alvo ≤ 10), frase de contabilidade `(53 EXEC row(s) older than the pending fields read their progress from gate_why)` presente, e suprimida quando o balde é zero (`if $historic > 0 … else empty`, `bin/sdd:4646`); a variante do repo do kit (`./bin/sdd autonomy`, `./bin/sdd autonomy --by-mission`) fecha a aritmética: header `111 row(s)`, `103` versões, `43` linhas lidas da prosa, `45` de outro repo declaradas como nunca contadas. (3) `./bin/sdd kaizen --series` → `.latest` `{kit_sha 60f0ee7, outcomes {advanced:1,churned:0,idle:0}, advance_rate 1, labels {ok:1}}`, `guard.degenerate_axis true` / `sufficient false` (estado esperado no repo do kit, ADR 0003). (4) **escritor re-caminhado de verdade, com `sdd run` e `sdd retry` reais** sobre fixture próprio e stub de `claude`: `sdd retry … --phase EXEC` escreveu `{invocation:\"retry\", pending_before:2, pending_after:1, increments_total:2}`. `sdd status` e `sdd phase` conferidos sobre esta missão. **Suíte:** `tests/run-all.sh` → rc 0, `suite green`, **692** `ok`, 0 FAIL, medida no HEAD de EXEC (`60f0ee7`). ⚠️ **A jornada achou 1 defeito confirmado e ele é regressão desta missão** — a sessão que **bloqueia** um incremento lê `advanced` a `0% waste`, reproduzido ponta a ponta com `sdd run` real: o sensor `a blocked increment publishes no pending_after` está **commitado e VERMELHO** (`expected: 2 null null / got: 2 1 2`, única FAIL da suíte), com a testemunha `and the refusal that produced it is the Jidoka one` verde ao lado provando que o fixture chega ao ramo Jidoka. Vira `F1` no `checkpoint.md`; direção do conserto provada satisfazível em cópia descartável (`694 ok`, 0 FAIL) e `bin/sdd` restaurado byte a byte. **Registry:** `docs/qa/bugs/` — 6 bugs, 5 `verified` + 1 `fixed`, **0 `open`** (Âncora 3 limpa); nada foi escrito nem apagado na árvore `docs/qa/`, que é das skills."
---

# Handoff — QA — o incremento que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

4 jornadas de CLI andadas (`sdd autonomy`, `sdd kaizen --series`, `sdd run`/`sdd retry`,
`sdd status`/`sdd phase`); as 4 métricas do `00-missao.md` conferidas contra o ledger real.
**1 achado confirmado, e é regressão desta missão:** a sessão que *bloqueia* um incremento passou a
ler `advanced` a `0% waste` — fail-open na direção da lisonja, sobre a única sessão que **para a
linha**. Virou 1 sensor commitado e vermelho + o incremento `F1`. 0 achados para o humano,
0 para o `TODO.md`. **Próximo passo: EXEC do `F1`**, não REVIEW.

## Estado do repo

- **Branch:** `feat/o-incremento-que-andou` — 10 commits à frente de `origin/…`, 12 à frente de
  `main`. Sem push (não é desta fase).
- **Último commit:** o desta sessão — sensor vermelho + `F1` + este handoff.
- **Working tree:** limpo depois do commit.
- **Suíte:** `tests/run-all.sh` → **verde no HEAD de EXEC** (`60f0ee7`, rc 0, 692 `ok`) e
  **vermelha depois do commit desta sessão, de propósito**: 1 FAIL, o Red do `F1`. É Jidoka, não
  quebra — o `gate_EXEC` recusa em `1 of 6 increment(s) still to execute` **antes** de rodar
  `TEST_CMD` (`bin/sdd:789` vem antes de `:791`), então a linha não gasta suíte por isso.
- **E2E:** `E2E_CMD=""` — não existe e não rodou. Sem interface; a jornada é linha de comando, e a
  evidência dela é o campo `gate:` acima (é o que o `gate_QA` mede neste caminho, `bin/sdd:837-842`).

## O que foi feito

- `tests/check-autonomy.sh`, bloco novo `== a blocked increment publishes no count ==` — o sensor
  durável do achado, escrito **antes** do conserto e provado vermelho pelo motivo certo.
- `docs/handoffs/20260829-o-incremento-que-andou/checkpoint.md` — linha `F1` (`pending`) e 6 notas
  de execução da QA.
- `docs/handoffs/20260829-o-incremento-que-andou/30-handoff-qa.md` — este arquivo.
- **Nada em `bin/`.** O `sdd-qa` não conserta produção: a direção do conserto foi provada numa
  cópia descartável e o `bin/sdd` restaurado byte a byte (`diff -q` contra a cópia pristina).

## O achado, por extenso

**`blocked` é status válido**, então o laço de validação do `gate_EXEC` o deixa passar; a
publicação de `GATE_EXEC_PENDING`/`GATE_EXEC_TOTAL` acontece logo em seguida (`bin/sdd:785-786`) e
só **depois** dela vem a recusa Jidoka (`:788`). Como `checkpoint_tally` conta `pending|doing` e
arquiva `blocked` num balde próprio, **desistir** de um incremento baixa `pending` exatamente como
**terminá-lo**.

Reproduzido com um `sdd run` real (fixture própria, stub de `claude` que marca `I1 blocked` e
commita):

```
{"event":"session","phase":"EXEC","gate":"fail","moved":true,
 "pending_before":2,"pending_after":1,"increments_total":2,
 "gate_why":"1 increment(s) 'blocked' — Jidoka: the line stops"}
→ outcome = advanced      (definição extraída do próprio bin/sdd, nunca uma cópia)
→ sdd autonomy sobre esse ledger:  1 session(s) · 1 advanced · 0 churned · 0 idle · 0% waste
```

**O que torna isso caro é o dado real, não a hipótese.** Das **2** linhas EXEC que ainda leem
`churned` em todo o ledger depois desta missão, **uma é exatamente essa sessão**
(`sales_quote/20260825-cif-forma-pagamento`). Ela lê honesto hoje **só** porque é anterior aos
campos — o `gate_why` dela não casa `^N of M increment`, então o caminho histórico não a anota.
Escrita por este runner, ela leria `advanced`, e o instrumento perderia a última acusação que tem
sobre uma linha parada. O texto de uso do `sdd autonomy` (`bin/sdd:5426`) promete *"advanced is the
gate that passed OR the EXEC session that **closed** an increment"* — bloquear não é fechar.

Mesma família da guarda de não-nulo do I2, e a mesma direção de falha: lisonja.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-autonomy.sh` (bloco `== a blocked increment publishes no count ==`) | as duas asserções do achado: a nomeada (vermelha) e a testemunha Jidoka (verde) |
| `docs/handoffs/20260829-o-incremento-que-andou/checkpoint.md` | a linha `F1` e as 6 notas de QA — inclusive a sugestão de nome do mutante e a prova de satisfazibilidade |
| `docs/handoffs/20260829-o-incremento-que-andou/30-handoff-qa.md` | este handoff; o `gate:` é a evidência das jornadas |
| `docs/qa/` | **intocada.** Lida (registry, 6 bugs, 0 `open`), não escrita, não apagada |

## Boot da próxima fase

⚠️ **A próxima fase não é REVIEW, é EXEC.** `./bin/sdd status 20260829-o-incremento-que-andou`
imprime `next phase: EXEC — 1 of 6 increment(s) still to execute`.

**Para o `sdd-executor` (F1) — ler primeiro** este handoff § "O achado, por extenso", depois as
notas `2026-08-30 04:10 · QA` do `checkpoint.md`:

- O Red já está em disco. `o=$(bash tests/check-autonomy.sh 2>&1)` hoje devolve **1 FAIL**,
  `a blocked increment publishes no pending_after`, `expected: 2 null null / got: 2 1 2`.
- **Direção do conserto, já provada satisfazível** (aplicada numa cópia descartável, suíte
  `694 ok` / 0 FAIL, e o `bin/sdd` restaurado): a recusa Jidoka em `gate_EXEC` tem de vir
  **antes** da publicação de `GATE_EXEC_PENDING`/`GATE_EXEC_TOTAL`, pelo mesmo argumento que já
  põe o laço de validação antes delas — `pending_after` é **veredito**, e não há veredito a dar
  sobre um checkpoint que o gate vai recusar. `pending_before` fica: é fotografia, e é ela que
  impede a asserção de passar sobre um ledger vazio.
- **Nenhuma asserção vizinha muda de lado** com essa ordem: `an EXEC row carries…` segue `2 1 2`,
  `a done without commit…` segue `2 null null`, `the EXEC row that closed the last increment says
  so` segue `EXEC pass 1 0 1`.
- **O `F1` nasce com mutante próprio** — sugestão `mut_EXEC_blocked_publishes_count`, que devolve a
  publicação para cima da recusa; assassino nomeado: `a blocked increment publishes no
  pending_after`. Catálogo **192 → 193**. Provar em cópia antes do commit (aplica, `diff` mostra
  **uma** linha, `bash -n`, sensor nomeado vermelho só na asserção nomeada).
- **Atualizar `docs/pipeline.md:596`** no mesmo commit: a célula de `pending_after` hoje nomeia só
  a recusa "rótulo sem artefato"; passa a nomear as duas (contrato em três lugares — runner, tabela
  e sensor — é a regra do `CLAUDE.md`).

**Para o `sdd-reviewer`, quando o `F1` fechar** — o que a QA viu e o revisor precisa saber:

1. **As 4 métricas do `00-missao.md` foram conferidas contra o ledger real**, com a definição do
   próprio runner extraída por `sed` e nunca uma cópia de `jq`. Métrica 1 (binário) verde; métrica 2
   no alvo exato (`14 advanced · 1 churned`, `10 de 112` versões, `2 de 77` EXEC `churned`);
   métrica 3 verde na primeira metade e **refutada** na segunda (já registrado pelo EXEC);
   métrica 4 (paridade humana × juiz) verde pela asserção diferencial.
2. **O `refez` do laço desenhado no repo do kit não é defeito, é o eixo degenerado.** No
   `sdd kaizen --series`, o grupo `e97d96b` lê `refez` com uma única sessão que **avançou** — porque
   a primeira cláusula de `phase_label` é "a última sessão do grupo não passou o gate", e no repo
   que **constrói** o kit cada `kit_sha` tem exatamente uma sessão. Está declarado no comentário do
   próprio `phase_label` (`bin/sdd:4872`) e o `guard.degenerate_axis: true` desliga o veredito. Num
   repo-alvo o `kit_sha` não muda dentro da missão e o grupo inteiro da fase é lido junto. **Não
   reabrir** — mas vale saber que a correção do `leve` não alcança o `refez`.
3. **A frase do `20-handoff-exec.md` sobre as linhas desta missão no ledger está errada.** Ela diz
   que só a **primeira** linha EXEC tem os três campos `null`; as **cinco** têm. O motivo não é
   defeito — o `sdd run` inteiro correu num processo carregado **antes** da edição do I1, e a última
   linha `{ main "$@"; exit $?; }` impede o bash de reler o arquivo —, mas o comando de verificação
   que aquele handoff entrega devolve `null` cinco vezes onde a prosa promete uma. Quem prova o
   escritor é a asserção e2e e o `sdd retry` re-caminhado nesta sessão.
4. **`sdd health` não foi rodado nesta fase** (~15–20 min, 193 mutantes depois do `F1`) e o carimbo
   de mutação segue **inválido** por desenho. Quem o re-emite é o `sdd-publisher`, **depois** do
   último commit de código.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- **Nenhuma.** O único achado tem causa técnica clara e nenhuma decisão de produto embutida:
  `Closable by: agent`, e por isso virou `F1` e não uma linha desta seção. Nenhum bug do registry
  precisou ser marcado `Closable by: human` — ele está limpo (0 `open`).

## Riscos e não-feitos

- **A suíte fica vermelha entre este commit e o do `F1`, e isso é o desenho.** 1 FAIL, a asserção
  nomeada do achado. O `gate_EXEC` recusa por incremento pendente **antes** de chamar `TEST_CMD`,
  então a linha não paga suíte por isso; mas um humano que rodar `tests/run-all.sh` nesta janela vê
  vermelho — é o sensor fazendo o que sensor faz.
- **Só o lado do ESCRITOR foi sondado para o achado.** A asserção pede que o `gate_EXEC` não
  publique; ela **não** prova o que o leitor faria com um par `2 / 1` fabricado à mão, porque esse
  par não pode mais nascer. Se alguém quiser blindar o leitor também, é uma decisão de desenho —
  ficaria com dois donos para uma regra, o que este repo recusa em toda outra família.
- **A jornada do `sdd autonomy` sobre a fixture não pôde virar asserção direta.** O `kit_sha`/dirty
  da linha nasce do checkout real do kit, que fica sujo durante uma fase EXEC ⇒ a linha vira
  não-comparável e sai do histograma. A asserção seria intermitente por causa do estado da árvore de
  quem roda, e não do defeito. Por isso a re-caminhada da jornada mora na célula do `F1`
  (`case` sobre a saída de `sdd autonomy --all-repos --by-mission`, sem `grep`, para não violar a
  regra 2 do `check-checkpoint.sh`) e não numa asserção da suíte.
- **`sdd kaizen` (o comando completo, não `--series`) não foi rodado** — ele abre uma sessão paga e
  daria à luz o plano da missão seguinte, que por decisão do grill (§6 do `00-missao.md`) **não**
  nasce de `sdd kaizen`. Só o `--series`, determinístico e de graça, foi andado.
- **`sdd health` e o catálogo de mutação não rodaram** (opt-in desde `4c86712`; rodá-lo num gate já
  tornou uma fase insatisfazível). O `score: N caught of N` de ponta a ponta sai da fase PR.
- **Os limites já declarados pelo EXEC continuam de pé** e a QA não os reabriu: o `N of M` como
  **dado** e não contrato do caminho histórico; a ausência de sensor para o aviso "a régua mudou";
  `pass/false` sem fixture próprio; e a sessão que fecha o último incremento sobre suíte vermelha
  lendo `advanced` pela contagem.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

**Nenhum, e a conta é a mesma que o EXEC fez.** O único achado desta fase é **dentro** do escopo —
é a regressão que a própria missão introduziu — e por isso virou `F1`, não linha de backlog. Os
três candidatos que sobraram do EXEC (o `N of M` como dado; a ausência de sensor para o aviso da
régua; `pass/false` sem fixture) foram re-auditados pela régua **D15** e continuam **fora** do
`TODO.md`: nenhum é fail-open — nenhum sensor afirma medir o que não mede — e nenhum tem consumidor
fora da suíte do próprio kit; os três são limite declarado no cabeçalho do código. Registrar
qualquer um deles moveria `tests/health-baseline.txt`, que está **dentro** da chave do carimbo de
mutação, e obrigaria a re-rodar `sdd health` depois do `F1` — custo sem achado do outro lado.
