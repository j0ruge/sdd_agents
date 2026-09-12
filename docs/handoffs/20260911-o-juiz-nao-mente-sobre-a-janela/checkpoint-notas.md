# Notas de execução — o juiz não mente sobre a janela

> Append-only. O prompt de boot inlina as últimas 10 notas; a sessão não abre este arquivo.

- decision: I1(b) é **apagar com backup**, e não preservar-e-filtrar. Decisão humana de
  2026-09-11, tomada na aprovação do plano, respondendo à pergunta que o próprio I1 levanta:
  copie `~/.sdd/autonomy-log.jsonl` para `autonomy-log.jsonl.bak-2026-09-11` antes de remover as
  11 linhas sob `/tmp`, e mantenha o Check como está (`grep -c '"repo":"/tmp'` → `0`). Filtrar na
  leitura foi recusado por acrescentar uma regra que pode falhar aberta.
- decision: `BUDGET_MISSION_USD` fica em 150 sem ajuste. O humano optou por decidir na hora se a
  escalada `budget-exhausted` aparecer; não trate a parada como defeito do plano.
