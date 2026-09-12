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
- 2026-09-11 23:40 · `I2` · **A rota que o achado nomeava estava MORTA; a divergência, viva por outra porta.** O `TODO.md:815` dizia "com a closure como primeira linha de um sha, os dois respondem `latest`/`previous` INVERTIDOS". Reproduzido nesta sessão: **não invertem** — o `shas_in_file_order` positivo de `20260831` já fechou a rota do `gate_pass` nos dois lados. O que estava vivo era a linha **KAIZEN** liderando uma versão: o `kaizen_series` tira as sessões do próprio juiz do eixo (`$meta`), o `cmd_autonomy` não tinha essa separação, e a tabela leu `bbbbbbb` contra `ccccccc` da série sobre um arquivo só. Escritor real (`cmd_kaizen`), não linha editada à mão — e no repo do kit a sessão do juiz pousa num sha só dela por construção. Lição para quem lê achado de revisão: **o defeito pode sobreviver ao mundo que o achado descreve**; o probe diferencial acha a porta, a prosa do achado não.
- 2026-09-11 23:40 · `I2` · A metade (b) (`missions` sobre linha não-graduável) estava viva **exatamente como escrita**: `missions: 2` sobre `detail: 1`, e a `composition` da ADR 0005 junto. Fechada com `graded_row` — UMA definição para os três leitores, escrita positivamente.
- 2026-09-11 23:40 · `I2` · ⚠️ **Apostrofe em comentário DENTRO do programa jq mata o `bin/sdd` na hora do parse.** Os dois blocos de jq do `cmd_autonomy`/`kaizen_series` são uma string shell de aspas simples só; escrevi "the judge's own session" no comentário **e** na frase impressa e o `bash -n` morreu a 500 linhas de distância. O aviso já está nos comentários do próprio bloco — custou duas voltas mesmo assim. Vale para a frase que o runner IMPRIME também, e o probe teve de aprender a grafia sem apostrofe.
- 2026-09-11 23:40 · `I2` · Dois commits: `7e6b3f5` (conserto + probes + 2 mutantes) e `d93b9bd` (os dois achados marcados `RESOLVIDO por 7e6b3f5`). A **catraca não se move** (105): item com `RESOLVIDO por` segue aberto até o merge — quem a move é o I6. Cada item foi encurtado para o teto de 8 linhas do `check-todo.sh` no mesmo diff; o que saiu foi a linha `Direção:`, que achado fechado não tem mais.
