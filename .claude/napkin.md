# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-08-15] A caixa `- [ ]` do TODO.md mente; o corpo é a verdade**
   Do instead: antes de planejar sobre um item do TODO.md, ler o corpo — itens com
   **RESOLVIDO por `<hash>`** já estão fechados mesmo desmarcados.
2. **[2026-08-15] Gate/sensor novo não entra sem mutação**
   Do instead: toda asserção nova de gate ganha entrada em `tests/check-mutation.sh`
   e o catálogo do `sdd health`; provar por sabotagem que a suíte morre.
3. **[2026-08-15] A suíte é `tests/run-all.sh` (~23s, mutação 20/20)**
   Do instead: rodar ela como TEST_CMD; `SDD_MUTATION_JOBS=10` derruba para ~15s
   nesta máquina de 20 núcleos (default 4, decisão de default é do humano).

## Language & Contract
1. **[2026-08-15] Superfície do kit = inglês; artefato de missão = OUTPUT_LANG (pt-BR aqui)**
   Do instead: arquivo novo em `bin/ agents/ docs/ tests/ config/ README` nasce em inglês
   e entra na catraca de `tests/check-lang.sh`; `TODO.md`, `KAIZEN_LOG.md`, handoffs,
   `CONTEXT.md` e planos ficam em pt-BR.
2. **[2026-08-15] Contrato ainda tem 5 pontos PT-BR por herança**
   Do instead: usar `aprovacao`/`versao`/`titulo` e `00-missao.md`/`01-plano.md` como estão;
   renomear é missão própria (TODO.md).

## User Directives
1. **[2026-08-15] Fluxo de missão do kit: planejar no Fable, executar no Opus**
   Do instead: brainstorm + grill-with-docs + kaizen no Fable → plano autocontido em
   `~/.claude/plans/AAAA-MM-DD-<slug>.md` (padrão do I13.5) → humano troca para Opus e executa.
2. **[2026-08-15] Kaizen exige número**
   Do instead: toda melhoria proposta declara antes/depois medível; sem número vai como
   opinião, não como kaizen.
