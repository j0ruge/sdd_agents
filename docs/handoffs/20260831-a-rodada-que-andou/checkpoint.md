---
missao: 20260831-a-rodada-que-andou
atualizado: 2026-08-31 00:00
---

# Checkpoint — A rodada que andou

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.** Um
> Check que grepa o texto solto responde "a asserção existe", nunca "a asserção passou".
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | A linha de REVIEW carrega `rounds_before`, `rounds_after` e `rounds_max` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the REVIEW row carries rounds_before, rounds_after and rounds_max' <<< "$o"` → `1` | pending | — |
| I2 | `def outcome` aprende que a rodada andou, com guarda de não-nulo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a REVIEW round that advanced reads advanced, never churned' <<< "$o"` → `1` | pending | — |
| I3 | Caminho datado: linhas de REVIEW antigas recuperam a rodada do `gate_why` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a pre-schema REVIEW row recovers its round from gate_why' <<< "$o"` → `1` | pending | — |
| I4 | A fase que fechou sem gastar sessão para de ler `refez` | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a phase that closed without a session does not read refez' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-31 00:00 · `—` · Plano nascido pelo `sdd kaizen` sobre o veredito de `bf001fe`
  (`05-verdict.md` ao lado). `aprovacao:` vazio por contrato — o destravamento é
  `sdd approve 20260831-a-rodada-que-andou`.
- 2026-08-31 00:00 · `—` · **Estado do ledger ANTES da missão**, para o antes/depois do K8:
  `sdd autonomy --all-repos | grep bf001fe` →
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`.
  A série do mesmo sha: `labels {ok: 16, leve: 1, refez: 1}`, `advance_rate 0.91`,
  `escalations {}`, `guard.sufficient true`.
- 2026-08-31 00:00 · `I3` · **Ponto de corte da métrica.** Depois do I3 e ANTES do I4, rode
  `sdd autonomy --all-repos | grep bf001fe` e registre a saída aqui. Esperado:
  `22 advanced · 1 churned · 0 idle · 4% waste`, com `3 mission(s) · US$ 175.96` inalterados.
  Se não fechar, **pare** — não avance para o I4 com a métrica em aberto.
- 2026-08-31 00:00 · `I4` · **Condição de Jidoka escrita.** Se a asserção diferencial do I4 acusar
  diferença em qualquer campo além de `labels` — em especial nos cinco baldes de `excluded` —, o
  I4 vira `blocked` e missão própria. I1–I3 já entregam a métrica sozinhos.
- 2026-08-31 00:00 · `—` · ⚠️ **Ordem que custa 20 a 50 min quando se erra:** `./bin/sdd health`
  roda **depois do último commit de código**. Registrar achado no `TODO.md` move
  `tests/health-baseline.txt`, que mora dentro da chave do carimbo e o invalida.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
