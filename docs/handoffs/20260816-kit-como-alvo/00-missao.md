---
missao: 20260816-kit-como-alvo
titulo: quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram
data: 2026-08-16
versao:
branch: missao/20260816-kit-como-alvo
aprovacao: humano-2026-08-16
ddd: n/a
---

# Missão — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> Escrita pelo `sdd-kaizen` na volta do laço documentada em `05-verdict.md`, ao lado. É a única
> fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão headless começa lendo
> estes dois.

## Problema (Gemba)

O kit foi desenhado para rodar em repo-alvo, e passou a rodar em si mesmo. Nesse regime — e **só**
nesse regime — quatro instrumentos afirmam ter medido algo que não mediram. Todos verificados
nesta sessão, com comando e linha:

1. **O ledger é global e nenhum leitor filtra por repo.** O caminho é
   `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl` para qualquer repo (`bin/sdd:761`) e os três
   leitores — `cmd_autonomy` (`:1817`), `kaizen_series` (`:1937`) e o lembrete pós-pipeline
   (`:2039`) — abrem o arquivo inteiro. O campo que resolveria isso **já é escrito**:
   `--arg repo "$REPO_ROOT"` nos dois construtores (`bin/sdd:860` e `:888`). Ninguém o lê. Já
   mordeu: um `sdd run` de fixture com sandbox em `/tmp` escreveu 3 linhas no ledger de produção
   e o juiz passou a ler `66% waste · 2 mission(s)` onde o verdadeiro era `0% · 1`. É a **fonte da
   verdade do juiz** contaminável por qualquer teste.
2. **O preflight compara a existência do agente, nunca o conteúdo.** `bin/sdd:1283` é
   `[ -f "$REPO_ROOT/.claude/agents/$(basename "$a")" ]` e `:1288` então imprime
   `"$n kit agent(s) checked"` — rótulo sobre uma comparação que nunca aconteceu. A cópia em
   `.claude/agents/` é o que o harness de fato carrega, então a fonte pode ser corrigida e o
   agente seguir rodando texto velho. Aconteceu: `2132cf5` editou `agents/sdd-kaizen.md` e a cópia
   ficou para trás, verde em tudo.
3. **`main "$@"` é a última linha do arquivo, sem guarda** — `bin/sdd:2365`, confirmado por
   `tail -3 bin/sdd`. Ao retornar dela o bash continua lendo o arquivo a partir do offset salvo, e
   a fase EXEC edita `bin/sdd` durante o `sdd run` que a executa (10× na missão anterior, +7647
   bytes). Reproduzido em script de 114 KB: edição in-place fez o bash **reexecutar o entry point**
   e rodar um fragmento, com **rc 0**. Hoje não morde só porque o editor troca o inode — uma
   invariante de ferramenta alheia que nenhum sensor mede.
4. **O aviso "você está na branch base" mora só no preflight** — `bin/sdd:1294`, única ocorrência
   (`grep -n 'base branch' bin/sdd`). `cmd_run` e `cmd_kaizen` não o têm, e **as duas abrem sessão
   que commita**. O kaizen é o pior dos dois: valida repo-do-kit e árvore limpa, e então escreve
   veredito + três artefatos onde quer que você esteja, `main` inclusive.

Os quatro têm a mesma forma — um instrumento cujo resultado positivo é um rótulo, não um artefato
— e a mesma condição de disparo: o kit sendo o seu próprio alvo.

## Métrica

Fato binário verificável, por incremento, cada um com o vermelho **medido no HEAD** desta sessão
(evidência na tabela PLAN-AUTO, critério `d`):

- `bash tests/check-entrypoint.sh` → rc `0` (hoje: `127`, o sensor não existe);
- a asserção `a row from another repo never enters the series` aparece **e passa** em
  `tests/check-kaizen.sh` (hoje: 0 ocorrências);
- a asserção `a drifted agent copy fails the preflight` aparece **e passa** em
  `tests/check-preflight.sh` (hoje: 0 ocorrências);
- a asserção `the base branch warning reaches sdd run` aparece **e passa** em
  `tests/check-gates.sh` (hoje: 0 ocorrências).

E, no agregado: `tests/run-all.sh` verde com score de mutação **100%** e o catálogo indo de 40
para **44** mutantes — as quatro sabotagens novas provam que as quatro asserções discriminam.

## Resultado esperado

O ledger deixa de ser um espaço de nomes compartilhado por acidente: as três leituras enxergam
só o repo corrente, e uma jornada de QA em `/tmp` não move mais nenhum número que o juiz cita.
O preflight passa a comparar bytes e a frase `N kit agent(s) checked` volta a ser verdadeira —
cópia velha reprova com o conserto no texto. O entry point ganha `{ main "$@"; exit $?; }`, e o
runner que se edita em voo para de depender de o editor trocar o inode. E as três portas que
abrem sessão passam a avisar quando você está na branch base, pela mesma função — não por três
cópias que divergem.

Nenhuma decisão de design é tomada aqui: os quatro consertos ficam dentro do contrato que já
existe.

## Fora de escopo

- **O eixo do juiz (`kit_sha` a cada linha) e a guarda das 3 missões.** É o achado central do
  veredito ao lado e continua no `TODO.md`: muda a pergunta que o juiz responde, pede decisão
  humana e ADR. Esta missão conserta os instrumentos que alimentam o juiz, não a régua dele.
- **O sensor de âncora podre do `check-todo.sh`** (forma medida, alvo nunca re-derivado; 15
  âncoras erradas em 11 itens). Mesma família "rótulo, não artefato", mas a direção — cobrar que
  a linha contenha um termo do título — tem risco de falso positivo que pede desenho próprio.
  Fica no `TODO.md`. Esta missão, aliás, produziu mais uma evidência para ele: a âncora
  `bin/sdd:2324` do item do `main "$@"` já aponta errado, porque o arquivo tem 2365 linhas.
- **Poda de `.sdd/logs/`, `--max-phases` sem sensor, `cmd_health` sem mutação e o resto do
  `TODO.md`.** Valor real, tema diferente; nenhum item foi movido nem apagado.
- **Resolvidos a apagar: nenhum.** `grep -n 'RESOLVIDO por' TODO.md` devolve só as duas linhas do
  cabeçalho de ciclo de vida (`:16` e `:24`) — zero corpos de item. A varredura anterior já saiu
  em `f506f97` e `37f64c0`. Nada a remover nesta missão.

## Gate PLAN-AUTO

Preenchido pelo `sdd-kaizen` **com evidência**. ⚠️ `aprovacao:` fica **vazio de qualquer forma**:
o laço kaizen não aprova os próprios planos (regra pré-I13.4, cobrada por `gate_KAIZEN`,
`bin/sdd:2115`). A tabela existe para o humano decidir com dado, não para liberar o pipeline.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | Sem grill humano — sessão kaizen headless (ADR 0002). As duas 🚩 do `CONTEXT.md:41-51` (confirmação da D11; alvo de tempo da D7) seguem deferidas com dono explícito (humano) e nenhuma toca esta missão. O achado do eixo do juiz foi deferido com dono no veredito, seção "O achado desta volta" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabela K1–K8 abaixo, 8/8; DDD `n/a` justificado abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | `01-plano.md` § "Contexto verificado" traz as 9 âncoras `arquivo:linha` e as 4 saídas de comando desta sessão; o executor não precisa redescobrir onde o `repo` é escrito (`:860`, `:888`) nem quantos leitores existem (3) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 4/4, e os 4 foram **rodados contra o HEAD** nesta sessão: `127`, `0`, `0`, `0` — todos vermelhos pelo motivo certo (sensor ausente / asserção ausente), nenhum verde por construção |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` do kit ⇒ `versao:` vazia satisfaz o critério |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | 9 âncoras lidas no `bin/sdd` e 4 Checks rodados; nenhum achado veio do texto do `TODO.md` sem reconferência — foi assim que a âncora podre `:2324` → `:2365` apareceu |
| K2 | Problema declarado com métrica | ✅ | § Métrica: 4 fatos binários com o vermelho medido, mais catálogo 40 → 44 a 100% (medido: `run-all.sh` → `of 40`) |
| K3 | Desperdícios identificados e cortados | ✅ | Três desperdícios de retrabalho: número de juiz contaminado por teste (correção manual do ledger), agente rodando texto velho (achado só na revisão), commit na branch errada (custou ~US$ 45 de `rebase --onto` no piloto SQ-97) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 4 incrementos independentes; I1/I3/I4 não se tocam, I2 é o único multi-arquivo. Qualquer um pode ser revertido sozinho |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Nenhum Check lê rótulo de sessão: 3 grepam a linha `ok` **da saída do sensor** (a asserção rodou E passou), 1 lê `rc`. A missão inteira é sobre esta distinção |
| K6 | Jidoka — o que para a linha está definido | ✅ | `01-plano.md` § Riscos: se a repro do I1 não for determinística nesta máquina, o incremento **para e diz**, degradando para asserção de forma declarada — nunca uma repro flaky que envenena o CI |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | 4 sensores + 4 mutações no catálogo; `docs/pipeline.md` § "The autonomy ledger" aprende o filtro por repo no mesmo commit (regra do contrato em três lugares, `CLAUDE.md`) |
| K8 | Registro no KAIZEN_LOG | ✅ | Previsto na fase DOCS, com antes/depois medido: os 4 rc de hoje contra os 4 de depois, e o score de mutação |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: são quatro consertos de instrumentação em bash (leitura de ledger,
comparação de arquivo, guarda de entry point e um aviso), sem aggregate, bounded context, evento
ou contrato entre módulos novo.`

## Decisões do grill (não re-litigar)

1. **O eixo do juiz não entra nesta missão**, mesmo sendo o achado mais interessante da volta —
   muda a pergunta que o juiz responde (D4) e por isso é decisão humana com ADR, não incremento.
2. **O filtro por repo é do lado da LEITURA, nunca da escrita.** O ledger é global de propósito e
   grava fato; quem tem de perguntar "deste repo?" é o consumidor. Escrever um ledger por repo
   jogaria fora a visão cross-repo antes de alguém ter pedido.
3. **O aviso de branch base continua `warn`, jamais `die`.** Transformá-lo em erro trancaria o
   próprio laço kaizen na primeira vez que o humano esquecesse de criar a branch — e o `sdd close`
   do kit já retorna cedo. Uma função só, chamada de três lugares (regra do enum único por
   programa, `CLAUDE.md`).
4. **I1 entra com sensor próprio, não pendurado num existente.** A propriedade (o bash relê o
   arquivo pelo offset após edição in-place) não é da família de nenhum dos dez sensores atuais, e
   a asserção certa é **diferencial**: duas cópias, guardada e não-guardada, comparadas entre si.

## Pendências para o humano

1. **Decidir o eixo do juiz** (`TODO.md`, "A guarda do juiz é insatisfazível quando o kit
   desenvolve a si mesmo"). Enquanto não for decidido, todo veredito neste repo é `indeterminado`
   por construção — duas voltas já terminaram assim. As duas saídas estão no veredito ao lado.
2. **Confirmar a D11** (`event: "degraded"` próprio vs `blocked` com `kind` novo) — 🚩 aberta em
   `CONTEXT.md:41`, sem relação com esta missão mas de novo sem dono ativo.
3. **A régua de tempo da suíte** (`CONTEXT.md:43`): esta missão acrescenta 4 mutantes ao catálogo
   e cada mutante é uma suíte inteira, então o estouro do alvo "<30 s" da D7 **vai crescer**. É a
   escolha já registrada (não cortar mutação para ganhar tempo); o que falta é subir o alvo ou
   aceitar o estouro por escrito.
