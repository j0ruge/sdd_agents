---
missao: 20260816-kit-como-alvo
data: 2026-08-16
---

# Plano — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Tudo que foi verificado nesta sessão está abaixo com âncora e saída de comando. O que **não**
> foi verificado está em § Riscos, marcado como risco — nunca como contexto.

## Contexto verificado (não re-descobrir)

Tudo aqui foi confirmado no HEAD `df18c88` (branch `kaizen/20260816`), com o comando ao lado.

- **O `bin/sdd` tem 2365 linhas** — `wc -l < bin/sdd` → `2365`. ⚠️ Várias âncoras do `TODO.md`
  citam offsets de quando o arquivo tinha 2324; **confira a linha antes de editar**, sempre.
- **`main "$@"` é literalmente a última linha executável** — `tail -3 bin/sdd` →
  `}` / *(vazia)* / `main "$@"`. Sem chaves, sem `exit`.
- **O ledger é um caminho só, para todo repo** — `bin/sdd:761`,
  `autonomy_log_path() { printf '%s/autonomy-log.jsonl' "${SDD_STATE_DIR:-$HOME/.sdd}"; }`.
  ⚠️ `SDD_STATE_DIR` já existe: é o gancho que os fixtures usam para não sujar o ledger real.
- **O campo `repo` JÁ é escrito, nos dois construtores** — `bin/sdd:860` e `:888`, ambos
  `--arg repo "$REPO_ROOT"`, emitido como `repo: $repo` (`:865`, `:896`). O valor é o
  **caminho absoluto** do repo, não o basename. Nenhuma escrita precisa mudar nesta missão.
- **São exatamente três leitores, e nenhum filtra** — `grep -n autonomy_log_path bin/sdd` →
  `761` (a definição), `807` (o escritor `autonomy_append`), `1817` (`cmd_autonomy`),
  `1937` (`kaizen_series`) e `2039` (o lembrete pós-pipeline da D6). Os três últimos são os
  consumidores.
- **O `kaizen_series` tem DOIS produtores da mesma shape** — o `jq` do caminho normal e um
  literal para o ledger vazio (`bin/sdd:1942`). `tests/check-kaizen.sh` compara os dois como
  conjuntos de chave. Um filtro que esvazie o resultado tem de cair no ramo do literal, não
  produzir um objeto meio preenchido.
- **O preflight só checa existência** — `bin/sdd:1283`,
  `[ -f "$REPO_ROOT/.claude/agents/$(basename "$a")" ] || _fail "... not installed"`, e `:1288`
  imprime `"$n kit agent(s) checked"` sob a condição `[ "$fails" -eq 0 ]`.
- **O aviso de branch base tem ocorrência única** — `grep -n 'base branch' bin/sdd` → `1143`
  (mensagem do `sdd install`, não é o aviso) e `1294` (o aviso, dentro de `cmd_preflight`).
- **Os sensores imprimem `  ok    <texto da asserção>`** — `bash tests/check-kaizen.sh | head`
  confirma o formato. É isso que os Checks de I2/I3/I4 grepam: a asserção **rodou e passou**,
  não que ela existe no fonte.
- **Mutante = função `mut_<SLUG>()` em `tests/check-mutation.sh`**, aplicada a uma cópia sandbox
  por `run_mutant` (`tests/check-mutation.sh:492`). ⚠️ Se a sabotagem não alterar o arquivo,
  `run_mutant` devolve **rc 90** com "the mutation did not apply — did the anchor change?" —
  é assim que âncora podre no catálogo se denuncia. Catálogo hoje: **38** mutantes.
- **Os 4 Checks deste plano foram rodados contra este HEAD e deram vermelho**: I1 `rc=127`
  (sensor não existe), I2 `0`, I3 `0`, I4 `0` (asserções não existem). Nenhum nasce verde.

## Arquitetura da mudança

Quatro consertos independentes, unidos pelo modo de falha e não pelo código. Só o I2 toca mais de
um ponto:

```
I1  bin/sdd:2365                     → { main "$@"; exit $?; }
                                       + tests/check-entrypoint.sh (novo, diferencial)
                                       + run-all.sh (registro) + mut_RUN_entrypoint_unguarded

I2  bin/sdd  ledger_row_is_local()   ← predicado ÚNICO (regra do enum por programa)
      ├── cmd_autonomy      :1817
      ├── kaizen_series     :1937
      └── lembrete pós-run  :2039
                                       + asserção em check-kaizen.sh e check-autonomy.sh
                                       + mut_RUN_ledger_no_repo_filter
                                       + docs/pipeline.md § "The autonomy ledger"

I3  bin/sdd:1283  [ -f ] → cmp -s     + asserção em check-preflight.sh
                                       + mut_PRE_agent_presence_only

I4  bin/sdd  warn_if_on_base_branch() ← extraída de :1294, chamada por
      cmd_preflight · cmd_run · cmd_kaizen
                                       + asserção em check-gates.sh
                                       + mut_RUN_base_branch_warn_dead
```

O I2 é o único com risco de contrato: o filtro muda **o que o juiz enxerga**, então
`docs/pipeline.md` aprende o filtro no mesmo commit — a regra de "contrato quebrado em três
lugares" do `CLAUDE.md`.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia.

### I1 — o entry point ganha guarda contra reexecução

**O quê:** trocar a última linha de `bin/sdd` por `{ main "$@"; exit $?; }`. A chave fecha a
unidade sintática e o `exit` garante que o bash nunca volte a ler o arquivo a partir do offset
salvo, mesmo que ele tenha crescido durante a execução.
**Onde:** `bin/sdd:2365`, `tests/check-entrypoint.sh` (novo), `tests/run-all.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** o sensor vem primeiro e é **diferencial** — a única forma que nenhum regime de
fixture satisfaz por acidente. Ele gera duas cópias de um script de brinquedo grande (≥128 KB de
comentário de enchimento, para vencer qualquer buffer de leitura), idênticas exceto pela última
linha: uma com `main "$@"`, outra com `{ main "$@"; exit $?; }`. Cada uma, ao rodar, **acrescenta
bytes a si mesma in-place** (`printf >> $0`, sem trocar o inode — `>>` preserva, ao contrário do
que o editor faz) e conta as execuções num arquivo contador. A asserção compara as duas saídas
entre si: a não-guardada executa o entry point **mais de uma vez**, a guardada exatamente uma.
Antes de existir a guarda no `bin/sdd`, o sensor já deve estar verde (ele testa scripts próprios);
o que prova a mudança no runner é a mutação.
**Check:** `bash tests/check-entrypoint.sh >/dev/null 2>&1; echo $?` → `0`
*(medido no HEAD: `127` — o arquivo não existe)*
**Sensor durável:** `tests/check-entrypoint.sh` registrado em `tests/run-all.sh`, mais
`mut_RUN_entrypoint_unguarded` no catálogo (desfaz a chave em `bin/sdd`) — a mutação é o que prova
que a asserção olha para o runner e não só para os próprios brinquedos. ⚠️ A asserção do runner
tem de ser sobre a **forma final da linha**, senão o mutante não morre.
**Reversível por:** `git revert` do commit — a linha volta ao que é hoje e o sensor sai do
`run-all.sh` junto.

### I2 — os três leitores do ledger param de enxergar outro repo

**O quê:** um predicado único, `ledger_row_is_local()`, que responde "esta linha é deste repo?"
comparando `.repo` com `$REPO_ROOT`, usado pelos três consumidores. Uma definição por programa, na
mesma regra que fez `is_escalation` existir depois de o par `blocked`/`degraded` divergir em três
pontos.
**Onde:** `bin/sdd:1817` (`cmd_autonomy`), `:1937` (`kaizen_series`), `:2039` (lembrete),
`tests/check-kaizen.sh`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`,
`docs/pipeline.md` § "The autonomy ledger".
**Como (TDD):** asserção **diferencial** primeiro, em `check-kaizen.sh`: um ledger com linhas de
dois repos, lido duas vezes com `REPO_ROOT` diferente, e as duas saídas comparadas **entre si** —
cada leitura vê só as suas linhas, e o total das duas é o arquivo. Um fixture só, num regime só,
não distingue "filtra" de "sempre devolve tudo". Texto da asserção, literal, porque o Check o
grepa: `a row from another repo never enters the series`. A gêmea em `check-autonomy.sh` cobre a
tabela humana.
**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c 'a row from another repo never enters the series' <<< "$o"` → `1`
*(medido no HEAD: `0`)*
**Sensor durável:** as duas asserções + `mut_RUN_ledger_no_repo_filter` (remove o filtro do
predicado). ⚠️ Sabote **o predicado**, não uma das três chamadas: sabotar uma chamada mede uma
chamada; sabotar a definição mede que as três realmente passam por ela.
**Reversível por:** o predicado é aditivo — remover a função e as três chamadas volta ao
comportamento de hoje sem tocar em escrita nenhuma.

### I3 — o preflight compara bytes, e a frase que ele imprime volta a ser verdade

**O quê:** trocar `[ -f <cópia> ]` por `cmp -s <fonte> <cópia>`, com duas falhas distintas —
ausente ("not installed") e divergente ("stale — run 'sdd install'"). São consertos diferentes e
merecem mensagens diferentes.
**Onde:** `bin/sdd:1283`, `tests/check-preflight.sh`, `tests/check-mutation.sh`.
**Como (TDD):** a asserção primeiro, num fixture que instala os agentes e **então** altera um byte
da cópia em `.claude/agents/`: o preflight tem de reprovar, dizer `stale`, e **não** imprimir
`kit agent(s) checked` (a linha só sai com `fails -eq 0`, então exija o texto certo **e a ausência**
do outro — asserção que lê só o `rc` não distingue esta falha de qualquer outra do preflight).
Texto literal da asserção: `a drifted agent copy fails the preflight`.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c 'a drifted agent copy fails the preflight' <<< "$o"` → `1`
*(medido no HEAD: `0`)*
**Sensor durável:** a asserção + `mut_PRE_agent_presence_only` (devolve o `cmp` para `[ -f ]`).
**Reversível por:** uma linha; nenhum outro caminho depende dela.

### I4 — o aviso de branch base alcança as três portas que abrem sessão

**O quê:** extrair o corpo de `bin/sdd:1294` para `warn_if_on_base_branch()` e chamá-la de
`cmd_preflight`, `cmd_run` e `cmd_kaizen`, antes de qualquer sessão. Continua `warn`: avisa e
segue.
**Onde:** `bin/sdd:1294` + `cmd_run` + `cmd_kaizen`, `tests/check-gates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** asserção primeiro em `check-gates.sh`, sobre um fixture parado na branch base:
`sdd run --dry-run` imprime o aviso, e a mesma função é exercitada pela porta do kaizen. Texto
literal: `the base branch warning reaches sdd run`. ⚠️ Afirme também que o `rc` **não** mudou —
a regressão cara aqui não é o aviso sumir, é ele virar erro e trancar o laço.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c 'the base branch warning reaches sdd run' <<< "$o"` → `1`
*(medido no HEAD: `0`)*
**Sensor durável:** a asserção + `mut_RUN_base_branch_warn_dead` (a função vira no-op).
**Reversível por:** inlining de volta em `cmd_preflight`; as outras duas chamadas somem.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| **A repro do I1 não é determinística nesta máquina.** O comportamento depende de o bash ainda não ter lido o arquivo inteiro; o tamanho que basta (114 KB no achado original) é empírico, não contratual | média | **Jidoka: pare o incremento e diga.** Se ≥128 KB não reproduzir de forma estável, NÃO commite uma repro flaky: degrade para a asserção de forma (`{ main "$@"; exit $?; }` é a última linha), registre a degradação em voz alta no `checkpoint.md` e no handoff, e mantenha a mutação. Degradação declarada, nunca silenciosa |
| **O filtro do I2 esvazia a série de quem já tem ledger de outro repo** e o juiz passa a ler menos dados do que ontem | alta (é o efeito pretendido) | É correção, não regressão: os números de hoje incluem linhas que não são deste repo. Garanta que ledger-vazio-após-filtro caia no **literal do ramo vazio** (`bin/sdd:1942`), não num objeto meio preenchido, e que `excluded` conte o que saiu em vez de sumir em silêncio |
| **`repo` é caminho absoluto**, então symlink, `/tmp` resolvido diferente ou repo movido não casam | média | Comparar com `$REPO_ROOT` como o runner o calcula, sem normalizar por conta própria. Se aparecer divergência real, é achado para o `TODO.md` — não invente `realpath` no meio deste incremento |
| **Linhas antigas do ledger sem o campo `repo`** (escritas antes de o campo existir) somem do filtro | baixa | O campo está nos dois construtores desde a origem, mas **confirme antes**: se houver linha sem `repo`, decida explicitamente (contar como local ou como excluída) e registre a decisão no `checkpoint.md` |
| **4 mutantes novos = 4 suítes inteiras a mais**, e o alvo "<30 s" da D7 já estoura em ~15 s | alta | Aceito e declarado: cortar mutação para ganhar tempo violaria o princípio que motivou o I13.2. O item está no `TODO.md` e a decisão de régua é do humano (§ Pendências do `00-missao.md`) |
| **Âncoras deste plano apodrecem** conforme os incrementos mudam o `bin/sdd` | alta | Sempre `grep` pelo texto antes de editar por número de linha. `run_mutant` devolve **rc 90** quando a âncora do catálogo apodrece — leia esse rc como "âncora", não como "mutação fraca" |

**Não-feitos deliberados:** o eixo do juiz e a guarda das 3 missões; o sensor de âncora podre do
`check-todo.sh`; poda de `.sdd/logs/`. Todos seguem no `TODO.md`, nenhum foi movido ou apagado.

## Verificação end-to-end

Com os quatro incrementos `done`:

1. `bash tests/run-all.sh` → verde, e a linha de mutação lê **42/42 (100%)** (hoje: 38/38).
2. Os quatro Checks do `checkpoint.md` rodados em sequência → `0`, `1`, `1`, `1` (hoje: `127`,
   `0`, `0`, `0`). É a métrica do `00-missao.md`, número a número.
3. `sdd health` → verde, com os quatro mutantes reconhecidos (a regra "gate/asserção nova entra
   com mutação") e a catraca de `tests/health-baseline.txt` atualizada se ela mexer.
4. Prova no caminho real, a que fecha a missão: com um ledger que contenha linha de outro repo,
   `sdd kaizen --series` devolve `excluded`/`guard` contando **só** este repo — o defeito que
   já mordeu (`66% waste · 2 mission(s)` onde o certo era `0% · 1`) deixa de ser reproduzível.
