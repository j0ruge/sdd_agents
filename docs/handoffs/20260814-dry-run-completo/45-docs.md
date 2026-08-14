---
missao: 20260814-dry-run-completo
fase: DOCS
status: done
data: 2026-08-14
gate: "`tests/run-all.sh` → exit 0 · 120 asserções, 0 falhas · `bash -n bin/sdd` limpo · working tree limpo · 8 commits nesta fase · checklist de drift abaixo sem item pendente"
---

# Documentação — 20260814-dry-run-completo

> Escopo: o diff `main..HEAD` — 29 arquivos, +3238/−56. Cada área tocada tem uma linha abaixo,
> com hash de commit ou justificativa concreta. Achado que não cabia nesta missão foi para o
> `TODO_FILE`, nunca para o diff.

## TL;DR

O drift mais caro não era o mais visível. A entrega da missão — `--dry-run` projetando o pipeline
inteiro — **não aparecia em nenhum documento em prosa**: `docs/pipeline.md` não continha a string
`dry`, e o `README.md` seguia byte a byte igual a `main`, descrevendo o comportamento antigo.

O segundo é pior de achar: `53cf63a` mudou o contrato do `gate_QA`, o review sincronizou README,
`docs/pipeline.md` e `docs/failure-modes.md` — e deixou fora o **agente**, que é o terceiro lugar
que o `CLAUDE.md` manda atualizar no mesmo commit. O `agents/sdd-qa.md` instruía a próxima sessão
de QA a ler uma árvore que não existe e não dizia que o campo `gate:` virou carga estrutural.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — projeção do dry-run (`next_pending_phase`, cursor `dry_next`) | `docs/pipeline.md` §"Dry-run — a projeção" (nova) + `README.md` §Uso | ✅ | `ab19819` — seção nova com os 3 casos de parada e exit codes; README ganhou frase + link |
| `bin/sdd` — strings de saída do dry-run | a própria saída do runner | ✅ | `1f34bf6` — "nada será executado" era falso e contradizia o `--help` duas telas adiante |
| `bin/sdd` — `cmd_close` (era `die` stub em `main`) | `docs/pipeline.md` §"Depois do PR" | ✅ | `ab19819` — tabela com as 3 precondições que só existiam no código |
| `bin/sdd` — `ALLOWED_TOOLS` / `--allowedTools` em `run_phase` | `config/schema.md`, `CLAUDE.md`, `docs/pipeline.md` §Permissões, `docs/failure-modes.md` | ✅ | `2083680` (schema/confs), `10a5438` (pipeline/failure-modes), `545e3c7` (regra do `CLAUDE.md` + formato de argumento único) |
| `bin/sdd` — Jidoka de `blocked` com escalação imediata | `docs/failure-modes.md` §"Incremento `blocked`" + `docs/pipeline.md` §EXEC | ✅ | `10a5438`; entrada correspondente do `TODO_FILE` anotada como resolvida em `f1c88ff` |
| `bin/sdd` — `gate_QA` com 2º contrato (projeto sem interface) | `docs/pipeline.md` §QA + `README.md` | ✅ | `10a5438` — tabela de sub-passos e as duas formas da evidência |
| `bin/sdd` — `gate_QA`, 2º contrato → **o agente** | `agents/sdd-qa.md` + espelho `.claude/agents/` | ✅ | `747f890` — §0 nova ("Dois contratos"); era o terceiro lugar do contrato, e estava dessincronizado |
| `bin/sdd` — `phase_budget` da QA = `QA_MAX_ITER × 3` | `config/schema.md` (linha `QA_MAX_ITER`) | ✅ | `545e3c7` — teto real da fase é 9 no default, não 3 |
| `bin/sdd` — diário movido para `.sdd/logs/<missão>/` | `docs/pipeline.md` §"Custos e logs", `docs/failure-modes.md` | ✅ | `10a5438`; varredura do repo inteiro nesta sessão: **zero** referências vivas ao caminho velho fora dos registros históricos da missão |
| `bin/sdd` — invocações de `claude` fora de `run_phase` (preflight, close) | `CLAUDE.md` §"Ao mexer no runner" | ✅ | `545e3c7` — a regra "toda invocação passa por `run_phase()`" tinha virado falsa |
| `tests/check-dry-run.sh` (novo), `check-gates.sh`, `run-all.sh` | `CLAUDE.md` §"TDD aqui dentro" | ✅ | `545e3c7` — a regra dizia que a suíte era `preflight`/`bash -n`/dry-runs; a suíte é `tests/run-all.sh`, e o sensor novo entra nela |
| `agents/sdd-planner.md`, `sdd-reviewer.md`, `sdd-docs.md`, `sdd-publisher.md` (novos) | `README.md` §"Os 6 agentes" + `docs/pipeline.md` | ✅ | `10a5438` — tabela com fase, modelo e entrega de cada um; entrega do `sdd-publisher` corrigida para incluir TICKET |
| `.claude/agents/*.md` (espelhos) | — | n/a | não são superfície de documentação: são cópias byte-idênticas de `agents/*.md`, geradas por `sdd install`. Verificado nesta sessão: os 6 pares idênticos por `diff -q` |
| `config/schema.md`, `config/starter.conf`, `config/examples/sales_quote.conf` | eles próprios (são a documentação da config) | ✅ | `2083680` (chave + comentário nas duas confs), `545e3c7` (formato de argumento único e teto de sessões da QA) |
| `.sdd/config.sh` (novo — dogfooding do kit no kit) | `config/schema.md` + `README.md` §Instalação | n/a | é uma **instância** de um artefato já documentado, não uma superfície nova: cada chave dele está descrita no `config/schema.md`, e o fluxo que o cria (`sdd install`) está no README |
| `README.md` | ele próprio | ✅ | `ab19819` — `--dry-run` reescrito; "a QA são três sessões" → "até três" (projeto sem interface tem uma só, que é o caso deste repo) |
| `docs/pipeline.md` (novo nesta missão) | ele próprio | ✅ | `ab19819` — 3 seções acrescentadas sobre comportamento que a missão introduziu depois de ele ser escrito |
| `docs/failure-modes.md` (novo nesta missão) | ele próprio | n/a | conferido linha a linha contra o HEAD nesta sessão e **já correto**: caminho do diário em `.sdd/logs/`, entrada do `ALLOWED_TOOLS`, entrada do `blocked` com exit 3. Nenhuma alteração necessária — n/a por verificação, não por omissão |
| `templates/*.md` | contrato de artefato do `gate_QA` | n/a | o `gate_QA` passou a medir o campo `gate:` do handoff, e `templates/handoff.md:7` **já o traz** desde `54ae6c9`, com a descrição certa ("a evidência de que o gate desta fase passou — comando + saída resumida, não adjetivo"). O contrato mudou no runner sem exigir mudança no template |
| `KAIZEN_LOG.md` | ele próprio | ✅ | `08989ea` — 3 entradas com antes/depois medido, conforme o item K8 do checklist kaizen do plano |
| `CLAUDE.md` | ele próprio | ✅ | `545e3c7` — 3 regras que a missão tornou imprecisas |
| `TODO_FILE` do kit | ele próprio | ✅ | `f1c88ff` (3 entradas completadas + 3 achados novos), `9f66135` (o achado do próprio `gate_DOCS`) |
| `docs/handoffs/20260814-dry-run-completo/*` | — | n/a | são o registro imutável da missão, não documentação viva do repo: por contrato ninguém os reescreve depois da fase que os produziu |

**Nenhum item pendente.** Toda linha está `✅` com hash ou `n/a` com justificativa verificada.

## Progressive disclosure — o que foi decidido

O índice roteia, a profundidade vive no doc específico. Aplicado assim:

- o `README.md` ganhou **uma frase e um link** sobre o dry-run, não a explicação — que foi inteira
  para `docs/pipeline.md`. O README foi de 79 para 89 linhas; a seção nova do `pipeline.md` tem 43.
  Se a explicação tivesse ido para o índice, o arquivo que todo agente lê primeiro cresceria a
  cada missão;
- o `CLAUDE.md` ganhou **3 linhas**, cada uma apontando para onde está o detalhe
  (`config/schema.md`, `tests/`), porque ele é lido por toda sessão de toda fase — doc que estoura
  janela é doc quebrado;
- o `agents/sdd-qa.md` recebeu uma tabela de 4 linhas em vez de prosa: o agente precisa **decidir
  em qual contrato está**, não entender a história da decisão, que está no `docs/pipeline.md`.

Nenhum documento tocado está inchado a ponto de pedir quebra em `references/`. O maior é o
`TODO_FILE` (268 linhas), que é log de achados por natureza e já tem seção "Feito" para drenar.

## Achados registrados nesta missão

As entradas que os outros agentes criaram durante a missão, conferidas contra o formato
obrigatório (o quê + `arquivo:linha` + por que importa + descoberto por/missão/data):

| Entrada | Autor | Estava bem-formada? | Ação |
|---|---|---|---|
| sessão headless sem permissão para rodar `TEST_CMD` | `sdd-executor` | sim — com atualização de escopo já anotada | nenhuma |
| incremento `blocked` deveria escalar na hora | `sdd-executor` | **não** — estava aberta e já tinha sido resolvida | anotada `RESOLVIDO por 2083680` + endurecimento `1807d75` (`f1c88ff`) |
| `gate_QA` insatisfazível em projeto sem interface | `sdd-qa` | sim — resolvida com hash `53cf63a` | nenhuma |
| `sdd install` não ignora o diário das missões | `sdd-qa` | sim — resolvida com hash `53cf63a` | nenhuma |
| asserção "dry-run não toca no disco" é mais fraca do que parece | `sdd-qa` | sim — reconfirmada na volta 2 com evidência nova | nenhuma |
| `gate_EXEC` aceita commit órfão | `sdd-qa` | sim | nenhuma |
| suíte sem teste de mutação | `sdd-qa` | sim | nenhuma |
| suíte não exercita o caminho real de `pipeline_log_line` | `sdd-executor` | **não** — dizia "RESOLVIDO na volta 2" sem hash, contra a convenção fixada 3 linhas acima | hash `85dfc9f` acrescentado (`f1c88ff`) |
| `config/schema.md` promete chaves não implementadas | `sdd-reviewer` | **não** — título dizia "quatro", corpo listava cinco | título corrigido para cinco (`f1c88ff`) |
| fase TICKET recebe agente **e** slash | `sdd-reviewer` | sim | nenhuma |
| `latest_matching` ordena por string | `sdd-reviewer` | sim | nenhuma |
| `bad_rows` escrito e nunca lido | `sdd-reviewer` | sim | nenhuma |

Acrescentados por esta fase, todos fora de escopo e por isso **registrados, não corrigidos**:

| Achado novo | Por que não foi corrigido aqui |
|---|---|
| `gate_DOCS` reprova o `45-docs.md` que cita o arquivo de achados pelo nome — e o próprio `agents/sdd-docs.md:81` manda usar um título que contém a palavra nua | mexer em gate está fora do escopo declarado no `00-missao.md`; o contorno desta sessão (usar `TODO_FILE`) é honesto e não esconde o defeito |
| o `## Uso` do `README.md` omite `sdd why`, `sdd phase`, `--phase`, `--max-phases` | os quatro já existiam em `main` — pré-existente, não drift desta missão |
| `sdd preflight` gasta uma sessão paga e o README não avisa | probe pré-existente em `main` |
| o kit não tem changelog e o `agents/sdd-docs.md` cobra um | criar a convenção retroagiria a toda a história do repo: é missão própria |

## Verificação

```
tests/run-all.sh          →  exit 0 · 120 asserções · 0 falhas
bash -n bin/sdd           →  limpo
git status --porcelain    →  vazio
bin/sdd run 20260814-dry-run-completo --dry-run
                          →  exit 0, projeta DOCS→PR com sdd-docs/sdd-publisher
                             e as strings novas de honestidade
diff agents/*.md .claude/agents/*.md  →  os 6 pares byte-idênticos
```

A suíte continua em 120 asserções: esta fase não acrescentou sensor porque não acrescentou
comportamento — a única mudança em `bin/sdd` foi texto de saída, e nenhum teste se acopla a essas
strings (verificado por `grep` antes de tocá-las).

## Commits desta fase

| Hash | O quê |
|---|---|
| `1f34bf6` | saída do dry-run parou de prometer o que não cumpre |
| `ab19819` | projeção do dry-run, `sdd close` e vocabulário `QA:close` no `docs/pipeline.md`; README |
| `747f890` | `agents/sdd-qa.md` sincronizado com o 2º contrato do `gate_QA` |
| `545e3c7` | 3 regras do `CLAUDE.md`/`config/schema.md` que a missão tornou imprecisas |
| `08989ea` | `KAIZEN_LOG.md` com 3 melhorias medidas |
| `f1c88ff` | entradas de achados completadas + 3 registros novos |
| `9f66135` | o achado do próprio `gate_DOCS` |

## Boot da próxima fase (PR)

Ler `40-review-r1.md` (Overall Grade A, todas as lanes fechadas) e este arquivo. O corpo do PR
precisa citar, além das evidências das fases anteriores:

1. o achado do `gate_DOCS` — é um defeito no kit encontrado **pela própria fase que ele mede**, e
   o `sdd-publisher` deve listá-lo entre os achados registrados;
2. os itens do `TODO_FILE` marcados `RESOLVIDO por <hash>` que ainda estão na seção "Aberto" com a
   caixa desmarcada: são 4, e a convenção do arquivo diz que é o PR quem cita a evidência antes de
   eles descerem para "Feito" no merge.

Não há pendência de julgamento humano vinda desta fase.
