# Plano de correção do preflight do worker Codex no kit

**Objetivo.** Fazer o `TEST_CMD` do kit passar pelo mesmo sandbox usado pelo preflight e pelos gates do Codex.

O PR #511 está em `main`. Na primeira tentativa da L5, o preflight terminou com rc 1. Os sensores
de gates, autonomia e preflight assumiam sockets TCP locais. O de autonomia assumia ainda que
`/var/tmp` era gravável e que um repo recém-inicializado herdaria a identidade Git do host.

- [x] Reproduzir as três premissas com `bin/sdd-codex --sandbox-check` e usar como Check as três suítes que já ficaram vermelhas no preflight da L5.
- [x] Manter os casos TCP/HTTP reais onde o ambiente permite loopback. Onde o sandbox recusa o socket, fornecer respostas de transporte aos mesmos casos, sem alterar as asserções sobre o runner.
- [x] Dar identidade explícita ao fixture de reflog e medir os dois casos do guard do ledger usando um diretório gravável fora das raízes temporárias quando `/var/tmp` estiver indisponível.
- [x] Verificar os casos afetados, os sensores estáticos, a suíte completa e o preflight com `PHASE_ENGINE=codex` em worktree do kit. Registrar o comportamento da suíte na documentação do pipeline.

A delegação real da L5 mantém assinatura do dono, escopo L5 e consentimento explícito para sessões
com valor faturado indisponível. O Check usa sandbox sem abrir uma sessão de modelo.

A validação concentrada passou nos 35 testes do adaptador e nos três do planner com
`SDD_TEST_NATIVE_CODEX=$(command -v codex)`. O controle de `APP_expect_status_ignored`
passou com o sensor íntegro e ficou vermelho sob mutação, no host e pelo sandbox. O
preflight integrado (`PHASE_ENGINE=codex ./bin/sdd preflight`) terminou com rc 0,
`TEST_CMD ran green` e worktree limpo, com a correção em `2e24b21`.
