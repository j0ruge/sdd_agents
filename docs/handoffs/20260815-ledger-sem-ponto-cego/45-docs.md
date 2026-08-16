---
missao: 20260815-ledger-sem-ponto-cego
fase: DOCS
status: done
data: 2026-08-16
gate: "`./tests/run-all.sh` → rc 0, `suite green`, `score: 30 caught, 0 known gap(s), of 30` (66,3 s) com todas as edições desta fase no disco; `./bin/sdd health` → rc 0, verde nos 5 checks (suíte, mutação 30/30, mutação por gate, proveniência dos 3 fixtures, catraca `6 known debt(s), none new`); `git status --porcelain` vazio; 5 commits nesta fase; checklist de drift abaixo sem item pendente."
---

# Documentação — 20260815-ledger-sem-ponto-cego

> Escopo: o diff `main..HEAD` — 13 arquivos, +1413/−63 antes desta fase, produção 100% em
> `bin/sdd` e `tests/`. Cada área tocada tem uma linha abaixo, com hash de commit ou justificativa
> concreta. Achado que não cabia nesta missão foi para o `TODO.md`, nunca para o diff.

## TL;DR

O drift caro desta missão não estava no schema do ledger — o EXEC e a revisão já haviam fechado o
`docs/pipeline.md` campo a campo. Estava **um degrau acima**: quem chega pelo *sintoma* não tinha
rota nenhuma. Um PR que sai draft sozinho é o evento de autonomia mais interessante que o kit
produz, e nem o `docs/failure-modes.md` (o documento que existe para "isto quebrou, e agora?") nem
a linha do `PUBLISH_ON_REVIEW_BLOCKED` no `config/schema.md` diziam que a decisão agora fica
registrada — nem como ler a contagem sem errar por 3×.

O segundo é o de sempre, e o `CLAUDE.md` o nomeia: contrato em três lugares. O evento novo foi
ensinado ao runner e ao `docs/pipeline.md`, e o **agente que consome a série** ficou sem saber que
`review-to-draft` existe — o mesmo modo de falha que a fase DOCS da missão anterior pegou no
`agents/sdd-qa.md`. Corrigido, com uma ressalva honesta: o espelho `.claude/agents/` não pôde ser
escrito nesta sessão, e isso está na tabela e no `TODO.md` em vez de escondido.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd:1097` e `bin/sdd:1520` — herestring no probe do preflight e no Jidoka do `blocked` (I1) | `CLAUDE.md` § "TDD aqui dentro" (⚠️ do `pipefail`) | n/a | a convenção já estava escrita e continua correta palavra por palavra ("use herestring"); quem mentia era o **comentário do runner** (`bin/sdd:1490-1495`), corrigido dentro do próprio I1 (`3521b9a`). Convenção não mudou ⇒ não se escreve regra nova (SDCA). Conferido linha a linha nesta sessão |
| `bin/sdd` — o Jidoka do `blocked` volta a disparar em qualquer tamanho de checkpoint | `docs/failure-modes.md` § "A `blocked` increment" | n/a | o texto descreve `rc 3` + `BLOCKED in EXEC` sem abrir sessão, que é **exatamente** o comportamento restaurado: o conserto tornou o documento verdadeiro, não obsoleto. Lido contra o `bin/sdd` do `HEAD` nesta sessão |
| `bin/sdd:805-843` — `autonomy_escalation_row`/`autonomy_degraded_row` e o evento `degraded` (I2) | `docs/pipeline.md` § "The autonomy ledger" (field reference) | ✅ | `6853796` (enum `event`/`kind` e as duas formas de linha), `56b2365` (cardinalidade "at most one per `run_id`"), `e764cd2` (a regra dos três consumidores do enum). Conferido campo a campo contra o `jq` do `HEAD`, sem lacuna |
| `bin/sdd:1543-1560` — o ramo `PUBLISH_ON_REVIEW_BLOCKED=draft` passa a registrar (I2 + F1) | `docs/failure-modes.md` § "The runner published a draft PR by itself" (nova) + `docs/pipeline.md` § REVIEW + `config/schema.md` (linha da chave) | ✅ | `274c906` — a seção nova entra pelo sintoma (PR draft), lista as três trilhas (warn, diário, ledger) e ensina a ler a contagem: `review-to-draft: 3` são três runs, nunca um run que degradou três vezes |
| `bin/sdd:1800-1845` — o enum de escalada que o **juiz** consome (`escalations`, `phase_label`) | `agents/sdd-kaizen.md` § 3 | ✅ | `274c906` — o terceiro lugar do contrato que o `CLAUDE.md` manda atualizar junto. O juiz agora sabe que `review-to-draft` é o espelho do `increment-blocked`: lá o kit parou de propósito (pode ser sinal bom), aqui baixou a própria régua e seguiu |
| espelho `.claude/agents/sdd-kaizen.md` | — | n/a | cópia gerada por `sdd install`, não superfície de documentação — mesma classificação do `45-docs.md` da missão anterior. ⚠️ **Está um parágrafo atrás do fonte**: esta sessão roda com escrita bloqueada sob `.claude/` (`cp`, `Edit` e `Write` recusados, os três). Sem efeito em suíte, gate ou `check-lang`; conserto num comando (`sdd install --force`), registrado no `TODO.md` em `aa34f00` |
| `bin/sdd:1735-1765` — escaladas do `cmd_autonomy` no eixo `kit_sha` (I3) | `docs/pipeline.md` § "The autonomy ledger" (parágrafo do eixo compartilhado) | ✅ | `e9a74aa` — "Both readers group escalations on the **same axis**… a change to one reader's grouping belongs in the same commit as the other's". Conferido contra o `jq` dos dois leitores nesta sessão |
| `bin/sdd:1801` — um `is_escalation` por programa, usado nos três pontos (achado R1) | `CLAUDE.md` § "Ao mexer no runner" (regra nova) | ✅ | `31966f5` — "enum lido em mais de um ponto vira UMA definição por programa". A convenção mudou de fato: o par escrito à mão em três lugares é como eles divergiram, e o custo medido foi a única missão em que o runner baixou a própria régua ler `ok` para o juiz |
| `bin/sdd` — vocabulário de domínio novo (`degraded`, `review-to-draft`, "escalada" como guarda-chuva) | `CONTEXT.md` — glossário + decisão **D11** | ✅ | `31966f5` — dois termos no glossário (com a cardinalidade por `run_id`, que é o erro de leitura mais provável) e a D11 com a alternativa barata e seu custo; 🚩 aberta porque a confirmação é do humano |
| `tests/check-gates.sh`, `check-autonomy.sh`, `check-kaizen.sh` — as 5 vacuidades e as técnicas que nasceram contra elas | `CLAUDE.md` § "TDD aqui dentro" (regra nova) | ✅ | `31966f5` — "Red observado não basta: tem de ser vermelho pelo motivo certo", com as 3 perguntas. O exemplo trabalhado (asserção diferencial) fica no `tests/check-kaizen.sh`, não no índice |
| `tests/check-mutation.sh` — catálogo 25 → 30 e o custo em segundos | `KAIZEN_LOG.md` | ✅ | `df7e2f5` — duas tabelas de antes/depois **medidas nesta sessão** (`fdf8708` num worktree descartável contra o `HEAD`): mutação 25→30, asserções 219→260, suíte 47,9 s→66,3 s, ledger 0→1 linha por run, leitores no eixo 1/2→2/2, consumidores do enum 2/3→3/3 |
| `TODO.md` — as entradas que a missão abriu, fechou e narrowed | ele próprio | ✅ | `aa34f00` — 2 entradas-origem fechadas com hash, 1 medição de fecho, 1 formato normalizado, 1 achado novo desta fase. Detalhe na seção "Achados conferidos" abaixo |
| `bin/sdd` — saída humana do `sdd autonomy` (bloco `escalations` agora com a versão na frente) | `README.md` § Uso | n/a | nada mudou em **instalar, rodar ou usar**: a única linha do README sobre o assunto ("waste per kit version, from the global ledger") ficou *mais* verdadeira com o eixo do I3, e a profundidade mora no `docs/pipeline.md`. Conferido por `grep -n "autonomy\|kaizen\|degrad\|blocked" README.md` |
| `templates/*.md` | contrato de artefato | n/a | nenhum contrato de artefato mudou nesta missão — `git diff --name-only main...HEAD -- templates/ config/` era **vazio** antes desta fase. Nenhuma chave de frontmatter, nenhum heading novo; `tests/check-templates.sh` verde na suíte desta sessão |
| `config/starter.conf`, `config/examples/sales_quote.conf` | — | n/a | o comentário de uma linha da chave ("`draft` opens a draft PR when the review runs out of rounds") continua verdadeiro. A profundidade nova — o que fica registrado e onde — foi para o `config/schema.md`, que é **o** documento da config: o arquivo de exemplo roteia, o schema aprofunda |
| `docs/adr/*` | — | n/a | nenhuma decisão arquitetural tomada ou revertida. A escolha de vocabulário do evento é contrato de **dado**, não de arquitetura, e sua profundidade já vive no field reference do `docs/pipeline.md`; registrada como D11 no `CONTEXT.md` para não virar folclore. ADR 0001 e 0002 seguem valendo, intocados |
| `CHANGELOG.md` | — | n/a | o repo não tem changelog, e nada externamente visível mudou (o kit não tem usuário fora deste repo e do piloto). Criar a convenção agora retroagiria a toda a história — item já registrado no `TODO.md` desde a missão `20260814-dry-run-completo`, e continua sendo missão própria |
| `docs/handoffs/20260815-ledger-sem-ponto-cego/*` | — | n/a | registro imutável da missão, não documentação viva do repo: por contrato ninguém os reescreve depois da fase que os produziu. Este arquivo é a exceção porque é o artefato **desta** fase |

**Nenhum item pendente.** Toda linha está `✅` com hash ou `n/a` com justificativa verificada nesta
sessão.

## Progressive disclosure — o que foi decidido

O índice roteia; a profundidade vive no documento específico. Aplicado assim:

- o `docs/failure-modes.md` ganhou a **seção nova** (26 linhas), e o `docs/pipeline.md` § REVIEW
  ganhou **uma frase e um ponteiro** para o field reference que já estava escrito. O contrário —
  explicar o evento na descrição da fase — duplicaria a única fonte da verdade do schema, que é
  onde o juiz é escrito contra;
- o `CLAUDE.md` cresceu **19 linhas** e é o arquivo que toda sessão de toda fase lê, então as duas
  regras entraram como regra + custo medido, com o exemplo trabalhado apontado
  (`tests/check-kaizen.sh`) em vez de transcrito. Doc que estoura janela é doc quebrado;
- o `CONTEXT.md` recebeu 2 linhas de glossário, 1 de decisão e 2 🚩 — a história de *como* se
  chegou ao `degraded` está no `01-plano.md` e no `40-review-r1.md`, e não se repete aqui;
- o `agents/sdd-kaizen.md` recebeu **um parágrafo** no lugar onde o agente já lê a nuance irmã
  (`increment-blocked`), porque o que ele precisa é **decidir como interpretar um número**, não
  entender a história da decisão.

Nenhum documento tocado está inchado a ponto de pedir quebra em `references/`. O maior continua
sendo o `TODO.md` (1,3 mil linhas), que é log de achados por natureza e já tem seção "Feito" para
drenar — a proposta de split segue registrada lá, não executada no meio desta missão.

## Achados conferidos nesta missão

As entradas que os outros agentes criaram no `TODO.md` durante a missão, contra o formato
obrigatório (o quê + `arquivo:linha` + por que importa + descoberto por/missão/data):

| Entrada | Autor | Estava bem-formada? | Ação |
|---|---|---|---|
| a suíte ainda carrega o `printf \| grep -q` que o runner perdeu | `sdd-executor` (I1) | sim — com os 6 caminhos citados | nenhuma |
| `shellcheck -S warning tests/` reprova e o `LINT_CMD` não olha | `sdd-executor` (I1) | sim | nenhuma |
| três das quatro metades do `degraded` sem mutante permanente | `sdd-executor` (I2) | sim — com a evidência de sabotagem manual | nenhuma |
| o runner se auto-degrada mais de uma vez no mesmo `sdd run` | `sdd-executor` (I2) | sim, e **exemplarmente**: narrowed pelo `sdd-qa` e atualizada pelo `F1`, com a metade de laço explicitamente separada da de registro | nenhuma |
| o que arma a corrida do Jidoka é a POSIÇÃO da linha `blocked` | `sdd-qa` | sim — com o "não há defeito vivo" dito na própria entrada | nenhuma |
| duas definições de comparabilidade no mesmo `jq` | `sdd-executor` (I3) | sim | nenhuma |
| a tabela do `sdd autonomy` ordena versões lexicograficamente | `sdd-executor` (I3) | sim | nenhuma |
| `sdd install` diz "config criada" sobre arquivo vazio | `sdd-executor` (F1) | sim | nenhuma |
| missão só de escalada satisfaz `guard.sufficient` (R4) | `sdd-reviewer` | sim — com a reprodução e a marca "herdado, não regressão" | nenhuma |
| a sessão de fase é um ponto cego enquanto roda | revisão humana | **não** — sem título em negrito e colada na entrada anterior, contra o formato do arquivo | normalizada em `aa34f00`, conteúdo intocado |
| a degradação `draft` não escreve linha no ledger (**origem do I2**) | `/codereview` (I13.1) | **não** — continuava aberta descrevendo um defeito que não existe mais | fechada em `aa34f00` com `6853796`+`56b2365`+`e764cd2` e com o que o conserto ensinou: foram 4 pontos, não 2, mais o 5º da revisão |
| as escaladas perdem o eixo antes/depois (**origem do I3**) | `/codereview` (I13.1), recalibrada pelo `sdd-kaizen` | **não** — mesma coisa: aberta sobre defeito já fechado | fechada em `aa34f00` com `e9a74aa`, mantendo aberto só o que sobrou (a **ordem** das versões, que é outra família) |
| a suíte fechou o I13.3 acima do alvo da D7 | `sdd-kaizen` | **não** — parava na projeção "25 → 28", sem a medição de fecho | medida em `aa34f00`: 47,9 s/25 → 66,3 s/30, ~2,2 s por mutante na média e 3,7 s na margem desta missão |

Acrescentado por esta fase, fora de escopo e por isso **registrado, não corrigido**:

| Achado novo | Por que não foi corrigido aqui |
|---|---|
| o espelho `.claude/agents/sdd-kaizen.md` ficou atrás do fonte | não é decisão, é impedimento: a sessão roda com escrita bloqueada sob `.claude/` e as três vias (`cp`, `Edit`, `Write`) foram recusadas. Fingir `n/a` sem dizer isso seria rótulo sobre não-artefato — exatamente o que o kit proíbe. O conserto é um comando e está na entrada |

## Verificação

```
./tests/run-all.sh        →  rc 0 · suite green · score: 30 caught, 0 known gap(s), of 30 · 66,3 s
./bin/sdd health          →  rc 0 · verde nos 5 checks · ratchet: 6 known debt(s), none new
git status --porcelain    →  vazio
./tests/run-all.sh @ fdf8708 (worktree descartável)
                          →  rc 0 · score: 25 caught, of 25 · 47,9 s   (o "antes" do KAIZEN_LOG)
git diff --name-only main...HEAD -- templates/ config/   →  vazio antes desta fase
diff agents/sdd-*.md .claude/agents/sdd-*.md             →  6 dos 7 pares idênticos; sdd-kaizen
                                                            diverge pelo bloqueio de escrita acima
```

A suíte não ganhou sensor nesta fase porque a fase não acrescentou comportamento: as mudanças são
prosa e, no `bin/sdd`, **nenhuma**. O `check-lang.sh` é quem mede o que esta fase escreveu na
superfície inglesa (`agents/`, `docs/`, `config/schema.md`) e passou nas duas rodadas.

## Commits desta fase

| Hash | O quê |
|---|---|
| `274c906` | a auto-degradação ganha rota em `failure-modes`, `pipeline` § REVIEW, `schema` e no agente do juiz |
| `31966f5` | `CONTEXT.md` (glossário + D11 + 2 🚩) e as duas regras novas do `CLAUDE.md` |
| `df7e2f5` | `KAIZEN_LOG.md` com o antes/depois medido nesta sessão |
| `aa34f00` | `TODO.md`: 2 entradas-origem fechadas, 1 medição de fecho, 1 formato, 1 achado novo |
| _este_ | `45-docs.md` — o checklist de drift |

## Boot da próxima fase (PR)

Ler o `40-review-r1.md` (Overall Grade A, nada pendente) e este arquivo. Além das evidências das
fases anteriores, o corpo do PR precisa carregar:

1. **as duas pendências de julgamento humano**, que atravessaram a missão inteira e continuam
   abertas — o vocabulário do evento (D11: `degraded` próprio contra reusar `blocked`; a revisão
   r1 fortaleceu o argumento e o `is_escalation` compartilhado torna a troca um ponto só) e o alvo
   de tempo da suíte (66,3 s contra os "<30 s" da D7, agora com a aritmética: ~2,2 s por mutante);
2. **o espelho `.claude/agents/sdd-kaizen.md`**, que ficou atrás do fonte por bloqueio de escrita
   desta sessão — vale um `sdd install --force` antes ou logo depois do merge, e está no `TODO.md`;
3. **os itens do `TODO.md` marcados com hash nesta missão** (`[I1 — FEITO em 3521b9a]`,
   `[I2 + F1 — FEITO em 6853796 e 56b2365]`, `[I3 — FEITO em e9a74aa]`): pela convenção do arquivo,
   é o PR que cita a evidência antes de eles descerem para "Feito" no merge.

Nenhuma outra pendência de julgamento humano vem desta fase.
