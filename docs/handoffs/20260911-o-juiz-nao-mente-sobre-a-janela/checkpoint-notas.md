# Notas de execução — o juiz não mente sobre a janela

> Append-only. O prompt de boot inlina as últimas 10 notas; a sessão não abre este arquivo.

- decision: I1(b) é **apagar com backup**, e não preservar-e-filtrar. Decisão humana de
  2026-09-11, tomada na aprovação do plano, respondendo à pergunta que o próprio I1 levanta:
  copie `~/.sdd/autonomy-log.jsonl` para `autonomy-log.jsonl.bak-2026-09-11` antes de remover as
  11 linhas sob `/tmp`, e mantenha o Check como está (`grep -c '"repo":"/tmp'` → `0`). Filtrar na
  leitura foi recusado por acrescentar uma regra que pode falhar aberta.
- decision: `BUDGET_MISSION_USD` fica em 150 sem ajuste. O humano optou por decidir na hora se a
  escalada `budget-exhausted` aparecer; não trate a parada como defeito do plano.
- 2026-09-11 22:15 · `I1` · **A metade (a) já estava entregue antes desta missão, e o plano não
  sabia.** A guarda que o I1 pede — o escritor recusar o ledger real a um checkout sob `/tmp` ou
  `$TMPDIR` — existe em `bin/sdd:2886` (`autonomy_append`, sobre `ledger_repo_is_temp`), veio com
  a ADR 0005 parte 3 em `28af7ea`, e já tem sensor: as **quatro** asserções `writer:` de
  `tests/check-autonomy.sh:3904` (dois pares diferenciais, A/B sob `/tmp` e C/D sob `/var/tmp`) e
  o mutante `mut_LEDGER_tmp_repo_allowed` (`tests/check-mutation.sh:903`). Nada foi reescrito: o
  probe vermelho que o plano manda escrever **não pode** ficar vermelho, porque o mundo em que o
  fixture contamina já está fechado. É o caso que a cláusula Jidoka do I1 previu, com a resposta
  invertida — o mundo não foi impossível de construir, foi impossível de **quebrar**. `SDD_MUTANT`
  não existe no runner e não foi criado: o catálogo sabota uma cópia em `mktemp -d`, que a guarda
  de caminho já recusa.
- 2026-09-11 22:15 · `I1` · Metade (b) executada como o humano decidiu — apagar com backup.
  `~/.sdd/autonomy-log.jsonl` 292 → 281 linhas; as 11 sob `/tmp` (`/tmp/qa-portas/clone` 5,
  `/tmp/sddrev.q49jXD/r7b` 3, três `/tmp/manual-*` 1 cada) saíram; sobraram só os dois repos reais
  (`sdd_agents` 156, `sales_quote` 125). Original em `~/.sdd/autonomy-log.jsonl.bak-2026-09-11`,
  com a grafia de data que a decisão humana pediu. Filtrado por `grep -v` e não por `jq`, de
  propósito: `jq` reserializaria as 281 linhas sobreviventes (ordem de chave, formato de número) e
  o diff seria indistinguível de uma reescrita — provado por
  `grep -v … bak | diff -q - autonomy-log.jsonl` → idêntico. Check verde: `0`.
