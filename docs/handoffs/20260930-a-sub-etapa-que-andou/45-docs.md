# Documentação — 20260930-a-sub-etapa-que-andou

## TL;DR

A documentação viva já estava quase toda em dia: o I5 (`4c0e079`) escreveu a 4ª emenda da D16, o
verbete Churn, o `docs/pipeline.md`, o `KAIZEN_LOG.md` e o `docs/failure-modes.md`, e o chapéu do
`sdd-kaizen` ganhou o braço da QA em `c8d156b`, com o espelho idêntico. Esta fase fechou o único
drift que restava, o achado #1 da r2: o `docs/pipeline.md` e o verbete Churn do `CONTEXT.md` não
diziam que a recuperação de `step_after` vale só para a mesma corrida (`run_id` igual e não nulo).
O conserto está em `88ed6ea`. Nenhum `⛔`, nenhuma regra nova, nenhum `CLAUDE.md` tocado: a
convenção não mudou, só a rubrica de um campo do ledger. O item do `TODO.md` que esse achado abriu
está consertado, mas o `TODO.md` fica fora do `writes:` deste chapéu, então a marca
`RESOLVED by 88ed6ea` fica para o publisher ou o humano (ver Pendências).

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `bin/sdd` (`ledger_outcome_defs`: braço do sub-passo da QA e laço QA⇄EXEC) | `docs/pipeline.md` | ✅ | § Field reference (`step_after`, `pending_*` "null outside EXEC and QA") em `74996fa`/`ec4ecf0`; narrativa do rótulo em `4c0e079`; "da mesma corrida" em `88ed6ea` |
| `bin/sdd` (`historic_steps`, caminho datado da QA, guarda de corrida do `R1`) | `CONTEXT.md` | ✅ | D16 4ª emenda e verbete Churn em `4c0e079`; D16 com a corrida em `8a1b3a5`; Churn com a corrida em `88ed6ea` |
| `bin/sdd` (régua de `outcome` medida antes × depois) | `KAIZEN_LOG.md` | ✅ | entrada com fatia `5b98087` 44·9 → 47·6 em `4c0e079`; linha das 28 → 22 recuperações em `8a1b3a5` |
| `bin/sdd` (régua citada pelos modos de falha) | `docs/failure-modes.md` | ✅ | "three times" → "four times" e a régua da QA em `4c0e079` |
| `agents/sdd-kaizen.md` | `.claude/agents/sdd-kaizen.md` | ✅ | espelho atualizado no mesmo commit `c8d156b`; `cmp` dos dois arquivos sem diferença |
| `bin/sdd` (saída de `sdd autonomy`: rodapé `QA row(s) older than step_after`) | `README.md` | n/a | o `README.md:83` descreve só o comando e os três baldes, que não mudaram; o rodapé novo está documentado no `docs/pipeline.md` |
| `bin/sdd` (convenção do runner) | `CLAUDE.md` | n/a | nenhuma convenção mudou: a missão acrescenta um braço a uma rubrica que já existia na mesma forma, sem gate, porta de escalada ou sensor novo (o censo continua `ls tests/check-*.sh` = 16) |
| `bin/sdd` (componente "verificação" da anatomia) | `.claude/rules/anatomia-do-agente.md` | n/a | a rule não descreve os braços da rubrica de `outcome`, e nenhum dos sete componentes mudou de forma |
| `tests/check-autonomy.sh` | — | n/a | asserções novas do escritor e do laço QA⇄EXEC; o cabeçalho do sensor recebeu o limite declarado do I6 no próprio arquivo, e nenhum doc enumera as asserções |
| `tests/check-kaizen.sh` | — | n/a | asserções do braço e do caminho histórico (m84/m85); nenhum doc enumera as asserções do sensor |
| `tests/check-mutation.sh` | — | n/a | 20 mutantes novos (495 → 515); o `CLAUDE.md` manda ler o número da linha `score:` e nunca o fixa, então não há número para envelhecer |
| `tests/check-health.sh` | — | n/a | só recebeu um limite declarado (D15) movido do `TODO.md` para o cabeçalho, que é o próprio documento daquele limite |
| `tests/health-baseline.txt` | — | n/a | a catraca `todo-findings` acompanha o `TODO.md` (90 → 85 → 87) no mesmo commit de cada movimento; é dado da catraca, não prosa |
| `TODO.md` | — | n/a | backlog: cinco itens saíram pela régua D15 em `7ee1c3e`, dois achados entraram nas rodadas de review; as entradas estão conferidas na seção abaixo |
| `docs/handoffs/20260930-a-sub-etapa-que-andou/*` | — | n/a | artefatos da própria missão, que são a fonte, não o alvo, do drift |

## Achados do `TODO_FILE` conferidos nesta missão

`bash tests/check-todo.sh --check TODO.md` → `ok    87 finding(s), all within 8 lines, carrying
anchor + date, every anchor on target`, rodado depois de `88ed6ea`, com as âncoras de linha intactas.

- **A ida e volta de branch do `check-autonomy.sh` herda o rótulo da sessão REVIEW** (r1): bem
  formada, com âncora `tests/check-autonomy.sh:6409` (`foreign_elsewhere`), porquê, `Direção:`,
  `Fonte:` apontando o `40-review-r1.md` e autor/missão/data. Segue aberta.
- **Duas descrições da recuperação de `step_after` não dizem "da mesma corrida"** (r2): consertada
  nesta fase em `88ed6ea`. Ela está incompleta pela gramática: a âncora `docs/pipeline.md:1398` não
  traz `<símbolo>` entre parênteses e não há `Fonte:` apontando o `40-review-r2.md`. Como o item
  agora está resolvido, o certo não é completá-lo e sim marcar `RESOLVED by 88ed6ea` e apagá-lo
  depois do merge. O `TODO.md` não está no `writes:` do `sdd-docs`, então isso fica pendente
  (abaixo).
- **Registrar achado durante a janela do juiz parte a janela** (veredito): bem formada, âncora
  `tests/health-baseline.txt` (`todo-findings`), `Direção:` e autor. Segue aberta, e está fora do
  escopo por decisão da missão (pede ADR).
- Os três registros decididos que o I6 escreveu (`retrofit-watch` 0.2.0, preflight refutado, stub
  do `adr new`): estão em uma linha cada, sob `<!-- sdd:decided -->`, com a evidência apontada.

## Pendências / Decisions for a Human

- No item **"Duas descrições da recuperação de `step_after` não dizem 'da mesma corrida'"** do
  `TODO.md`, acrescentar `RESOLVED by 88ed6ea` ao corpo antes do PR e apagar o item depois do
  merge, provando com `git merge-base --is-ancestor`. O `sdd-docs` não escreve o `TODO.md`. A
  contagem da catraca não muda com a marca, só muda com a remoção (87 → 86 no chore pós-merge).
- Herdada da missão: decidir se a janela 2 é refeita ou se a próxima abre depois desta missão (a
  régua de `outcome` mudou).
