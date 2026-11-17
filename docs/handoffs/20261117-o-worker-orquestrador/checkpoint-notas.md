# Notas de execução — O worker orquestrador

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
> O prompt de boot inlina as últimas 10 notas e manda não abrir este arquivo.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> Intervenção humana abre a linha com o marcador `intervention:`, fora desta citação.

- 2026-11-17 16:58 · `PLAN` · plano escrito pelo planner; esta missão é o primeiro `sdd run` de uma missão do kit num worktree ligado (decisão 12): se a corrida morrer por causa do arranjo, registre aqui o comando, o rc e a última linha do `pipeline.log`, e pare
