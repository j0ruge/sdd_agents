---
missao: 20260917-o-numero-do-adr-nao-e-prosa
titulo: o ADR nasce com número alocado por comando e o vínculo spec ↔ ADR ↔ plano passa a ser medido por sensor, no kit e em qualquer repo-alvo
data: 2026-09-17
versao:
branch: feat/o-numero-do-adr-nao-e-prosa
aprovacao:
ddd: n/a
adr: TBD
---

# Missão — o número do ADR não é prosa

> Escrita pelo `sdd-planner` com o humano presente (grill de 9 perguntas + 3 injeções,
> 2026-09-17). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda
> sessão começa lendo estes dois. ⚠️ `adr: TBD` é deliberado: o incremento I4 roda o primeiro
> `sdd adr new` real e substitui o valor — é o teste de bootstrap do próprio mecanismo.

## Problema (Gemba)

Uma nota do vault (feature de lembrete, ticket do repo-alvo) declarou livremente "ADR 0030" em
2026-08-25; em 2026-08-26 o `docs/adr/0030-…` real do repo-alvo foi aceito para **outra**
decisão (frete). A nota nunca chegou ao repo — `grep` do ticket no repo-alvo responde zero —,
então a colisão é latente: materializa no dia em que alguém implementa contra a nota.
Verificado nesta sessão, não suposto:

- **Nada aloca IDs em lugar nenhum.** `grep -c traceab bin/sdd` → 0; a única menção a `docs/adr`
  no runner é a varredura de `RELEASE_FORBIDDEN_WORDS` (`bin/sdd:4280`). Os ADRs do kit
  (`docs/adr/0001–0007`) e os 40 do repo-alvo são numerados à mão.
- **O vínculo é unidirecional onde existe e ausente onde importa.** No repo-alvo, ADR→spec
  existe (`docs/adr/0030-…:4` aponta para `specs/009-…/research.md:42`); spec→ADR é **zero**
  (`grep -rin adr specs/` só acha a palavra "padrão"). No kit, 2 de 13 specs citam ADR — uma por
  caminho, outra por número solto (`docs/superpowers/specs/2026-08-27-missao-2-da-janela-handoff.md:35`).
- **O kit já pagou esta classe uma vez**: `CONTEXT.md:55` registra referências penduradas a
  "ADR 0004" corrigidas à mão na missão `20260820-missao-porteira`.
- **O único sensor hoje é um revisor humano por acaso**: o `40-review-r1.md:51` da missão
  `20260830-invariante-do-frete-no-agregado` do repo-alvo achou em prosa que o ADR 0030 descrevia
  um buraco já fechado.
- **Templates, planner e executor não conhecem ADR**: `grep -rin 'adr\|rastreab' templates/
  agents/sdd-planner.md agents/sdd-executor.md` → 0. Só `agents/sdd-docs.md:26,49` lista
  `docs/adr/*`.
- **Duas gramáticas de cabeçalho coexistem** e uma regra tem de servir às duas: kit
  `# NNNN — título` + `Date: … · Status: accepted`; repo-alvo `# ADR NNNN — título` +
  `- **Status**: aceito (<ticket>, <data>)` com verbos de relação e links relativos.

## Métrica

Quatro fatos, todos verificáveis por comando:

1. `bash tests/check-adr.sh` contém `  ok    ADR whose Spec: points elsewhere fails` — a fixture
   equivalente ao caso do vault (spec aponta para um ADR cujo `Spec:` aponta para outra spec)
   reprova com `arquivo:linha`.
2. `bash tests/check-adr.sh` contém `  ok    the reservation primitive refuses an existing path
   and keeps its bytes` — `sdd adr new` nunca sobrescreve nem repete ID.
3. `./bin/sdd health` termina com `score: 317 caught, 0 known gap(s), of 317` (309 hoje + 8) e
   escreve o carimbo.
4. Com `ADR_CHECK="block"` no `.sdd/config.sh` do kit, `./bin/sdd why
   20260917-o-numero-do-adr-nao-e-prosa PLAN` responde `plan approved` — o kit obedece ao próprio
   gate sobre esta missão.

## Resultado esperado

O kit ganha `sdd adr new` (aloca `max+1`, cria com O_EXCL, escreve o cabeçalho e a linha `adr:`
da spec num comando só) e `sdd adr check` (valida a missão corrente ou o repo inteiro, texto +
rc). Três chaves novas — `ADR_CHECK=off|warn|block`, `ADR_DIR`, `SPEC_DIR` — governam o quanto
os gates de PLAN e EXEC cobram; `block` recusa `TBD` na **saída** do PLAN, a única fase com
humano. Um sensor novo com selftest e oito mutantes provam que o mecanismo mede o que diz. O
próprio kit passa a rodar `block`, com o ADR 0008 criado pelo comando. A adoção em repos-alvo é
gradual e documentada (`warn` → corrigir → `block`), com receitas de CI e de hook SpecKit em vez
de código fora do kit.

## Fora de escopo

- Corrigir a nota do vault ou criar o ADR real da feature de lembrete (humano; fora do kit).
- Tocar o repo-alvo: config, hooks SpecKit, job de CI — vira receita em `docs/pipeline.md` e
  achado `kit:`→alvo no handoff (decisão 1 do grill).
- Workflow reutilizável de CI no kit: impossível entre owners diferentes com repo privado, e o
  kit não tem `.github/` por decisão (ADR 0004).
- `--json` no `sdd adr check`: sem consumidor hoje → entrada no `TODO.md` (I8).
- Namespace local `specs/*/adr/` do repo-alvo: limite declarado no sensor e no
  `config/schema.md` (D15), decisão do repo-alvo.
- Template de corpo de ADR em dois idiomas: o corpo segue `OUTPUT_LANG` e quem o escreve é a LLM
  (injeção do humano); o stub é só o cabeçalho.
- 9ª fase/9º gate: o check corre **dentro** de `gate_PLAN`/`gate_EXEC`.
- Rodar `sdd run` no kit para esta missão: execução interativa por decisão do humano.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | seção "Pendências para o humano": 6 itens, todos com dono e rota |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | um agente Plan sem o contexto da conversa verificou as 8 perguntas de âncora e produziu o fatiamento; as âncoras entraram no `01-plano.md` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 9 de 9, todos em herestring com âncora `^  ok    ` ou rc |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` do kit |

> Todos ✅, e mesmo assim `aprovacao:` fica vazio de propósito: o humano pediu aprovação explícita
> ("somente após aprovação humana explícita do plano"), e o gate humano é `sdd approve`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | 3 exploradores + leituras diretas de `bin/sdd`, `tests/`, docs; repo-alvo e vault só leitura; graphify para `load_config`, `gate_PLAN`, `cmd_preflight`, `main` |
| K2 | Problema declarado com métrica | ✅ | seção "Métrica", 4 fatos por comando |
| K3 | Desperdícios identificados e cortados | ✅ | superprodução: workflow reutilizável, `--json`, template em 2 idiomas, 9º gate, namespace local; superprocessamento: seção `## Rastreabilidade` trocada por uma regex de linha-chave |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | I1–I9, valor desde o I1 (comando existe, sensor registrado) |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | todo Check lê linha `^  ok    ` de sensor, rc de comando ou saída de `sdd why` |
| K6 | Jidoka — o que para a linha está definido | ✅ | `block` para em PLAN com dono nomeado; sensor vermelho para a suíte; catálogo < 100% nega o carimbo |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | poka-yoke (O_EXCL + gate) > template (`adr:` no `missao.md`) > regra escrita (planner, pipeline, schema, rule anatomia) |
| K8 | Registro no KAIZEN_LOG | ✅ | I8, com antes/depois medidos |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: o kit é bash + markdown; a mudança é de contrato de artefato e de sensor, não de modelo de domínio.`

## Decisões do grill (não re-litigar)

1. **Escopo = núcleo + gate**: alocador, validador, config, sensor + selftest + mutantes, preflight,
   exigência dentro de `gate_PLAN`/`gate_EXEC` sob `off|warn|block`, docs. CI e hooks SpecKit são
   receita, não código. Sem fase nova (o censo de 8 gates em `bin/sdd:4564` não move).
2. **CLI = `sdd adr new` + `sdd adr check`**: uma entrada `adr)` no `main()` porque o `sdd health`
   check 6 parseia o `case` com `[a-z|+-]+\)`; verbos dentro de `cmd_adr`.
3. **Gramática = uma regex de linha-chave** `^(- )?(\*\*)?(ADR|Spec)(\*\*)?:`; `adr: none | TBD |
   <caminho>` na spec/missão, `Spec: <caminho>` no ADR; ID lido do **nome do arquivo**
   (`^[0-9]{4}-[a-z0-9-]+\.md$`), servindo aos dois dialetos; plano co-localizado.
4. **Dois escopos; ausência só falha na missão corrente**: `--mission` exige `adr:`; repo inteiro
   valida quem declara, conta quem não declara (`info`), reprova duplicata e número solto.
5. **`ADR_CHECK` recusa TBD na SAÍDA do PLAN** (só ali há humano; recusar em EXEC seria gate
   insatisfazível — US$ 73 medidos na classe); `gate_EXEC` re-roda por drift; `warn` = uma linha
   `degraded kind:adr-check` por corrida; `off` = nada.
6. **Alocador max+1, O_EXCL, stub só de cabeçalho**; corpo em `OUTPUT_LANG` escrito pela LLM
   (duas injeções do humano); `--spec` escreve os dois lados e recusa caminho já declarado.
7. **`specs/*/adr/` fora de escopo**, limite declarado (D15).
8. **Saída texto + rc** (`  ok/FAIL/info`, rc 0/1/2); `--json` só com consumidor.
9. **Dogfood sem corrida**: `adr: TBD` aqui, ADR 0008 nasce do I4 pelo comando; kit `warn` → `block`.
10. **Execução interativa (Opus), não `sdd run` no kit** — reticência do humano em usar o kit
    para melhorar ele mesmo.

## Pendências para o humano

- **`--json` no `sdd adr check`** — só quando um consumidor precisar de mais que rc. Rota:
  `TODO.md` (I8).
- **Adoção no repo-alvo** — chaves no `.sdd/config.sh`, hooks `before_plan`/`before_implement` em
  `.specify/extensions.yml` (campo `condition:` livre), job fino no CI; depois de o `warn` rodar
  limpo lá. Rota: receita em `docs/pipeline.md` (I8) + achado `kit:`→alvo no handoff de EXEC.
- **Namespace local `specs/*/adr/`** no repo-alvo — unificar ou declarar. Rota: handoff.
- **Nota da feature de lembrete no vault** — trocar "ADR 0030" por `ADR canônico: TBD — criar
  via sdd adr new`. Fora do kit.
- **Carimbo de mutação não cobre `docs/adr`** (`TODO.md:101-108`) — o alocador passa a escrever
  lá; o item existente já descreve. Sem ação aqui.
- **`docs/superpowers/{specs,plans}` do kit ficam fora do escopo varrido** — o layout não é
  `<dir>/*/spec.md`. Rota: nota no `KAIZEN_LOG.md` (I8).
