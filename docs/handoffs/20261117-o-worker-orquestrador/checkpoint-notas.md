# Notas de execução — O worker orquestrador

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
> O prompt de boot inlina as últimas 10 notas e manda não abrir este arquivo.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> Intervenção humana abre a linha com o marcador `intervention:`, fora desta citação.

- 2026-11-17 16:58 · `PLAN` · plano escrito pelo planner; esta missão é o primeiro `sdd run` de uma missão do kit num worktree ligado (decisão 12): se a corrida morrer por causa do arranjo, registre aqui o comando, o rc e a última linha do `pipeline.log`, e pare
- 2026-11-17 18:34 · `I1` · feito em bdfa30e; Check → `3`, suíte verde (12 min, rc 0). O `--anchors` já dizia `0 off target` com a âncora em :41 (tolerância de 10 linhas), mas o plano manda o número exato e ela foi para :43. Os probes do sensor leem as chaves só do frontmatter (`fm:`), como o verbo vai ler; sete sabotagens em cópia dos templates derrubaram uma asserção cada
- 2026-11-17 19:20 · `I2` · feito em f7f99ea; Check → `1 0`, suíte verde (rc 0, 814 mutantes aplicam). Dois ajustes fora da lista do plano: o `apply_mutant` faz `bash -n` no `bin/sdd-worker` quando o mutante o altera (controle `invalid_worker:91` no `--anchors`, sabotado → SENSOR-BROKEN), e o probe "a suite that lost steps" do `check-health.sh` passou a comentar toda linha `run` de topo: cortado no preflight, o mundo degradado ia de 9 para 10 passos com o passo novo e alcançava o `SURFACE_FLOOR=10` (o I3 em diante não move mais esse probe). Âncora `tests/run-all.sh:292` → `:294`
- 2026-11-17 19:51 · `I3` · feito em 3b6d636; Check → `3 0`, suíte verde (rc 0, 816 mutantes aplicam). O `now()` entrou simples (só `date`): a costura `SDD_WORKER_NOW` é do I4. A sabotagem manual achou três regras de legibilidade sem probe — chave vazia (`lots:`), instante malformado e teto que não é número; a do instante falhava ABERTA (sem a regex, `expired` erra no `[ -le ]`, lê "não vencida" e assina) — e os três mundos entraram dobrados na terceira asserção. O prazo é comparado pelos 12 dígitos, nunca como texto sob a colação do locale
- 2026-11-17 20:24 · `I4` · feito em dc66ce2; Check → `6 0`, suíte verde (rc 0, 819 mutantes aplicam). Lote sem linha na tabela do `campaign.md` e `Ceiling` que não é nível respondem `assisted` (falha fechada; o plano não os nomeava), e `--lot` sem lote é rc 2, nunca o nível sem teto. Sabotagem manual em cópia (timeout 120 s, `ulimit -v`) degradou 14 regras além dos 3 mutantes, cada uma derrubou a sua asserção. Para o I7: o `lots_table` pula a linha separadora e para no fim da tabela, e nenhum probe do `level` alcança essas duas regras — é o `next`, que percorre a fila, quem as mede
