# Registro de revisões e incidentes

Este resumo preserva a evidência necessária depois da limpeza do scratch local. Logs volumosos
não são versionados; os caminhos e o pacote local de evidências estão no handoff da entrega.

## Revisões

- `1c9146d..9089493`: Task 1 aprovada, sem achado Critical, Important ou Minor.
- `9089493..c4ecb31`: Task 2 encontrou um Important: o worker herdava `SIGINT` ignorado e não
  executava limpeza cooperativa.
- `c4ecb31..b7e012e`: conserto do `SIGINT` aprovado, sem nova quebra Critical ou Important.
- `1c9146d..6c5e6f7`: revisão integral encontrou três Important:
  - F1: `adr new --repo` não admitia o checkout efetivamente alterado;
  - F2: clean filters/EOL podiam esconder divergência de bytes do plano aprovado;
  - F3: `SIGINT` não alcançava filhos foreground do worker.
- `6c5e6f7..f11bf27`: F1/F2/F3 corrigidos. A revisão encontrou ainda a fronteira física de
  `--spec`, fechada em `d12ace4`.
- `f11bf27..d12ace4`: complemento de spec aprovado. Veredito final: F1/F2/F3 endereçados, sem
  novo achado Critical, Important ou Minor.
- Primeira certificação: `RUN_branch_option_name` sobreviveu porque outra recusa satisfazia o
  fixture. O patch focado recebeu revisão **APPROVED — no findings** antes de entrar em `d159a9d`;
  `8875643` corrigiu a omissão de ajuda de `sdd-link-agents`.

## Decisões e custos preservados

1. Supervisor local Python com `PR_SET_CHILD_SUBREAPER`: cobre órfãos, `setsid` e double-fork. O
   custo é exigir Python 3.9+, procfs e Linux nos comandos coordenados.
2. Toda a árvore do hook usa prazo único de cinco segundos mais um segundo: trabalho que o hook
   lança em background também é encerrado; descendentes comuns do runner conservam posse até o
   reap.
3. A sinalização usa pidfds para fixar identidade: exige Linux 5.3+ e syscalls permitidas sob
   seccomp; ausência da capacidade recusa antes de config ou sessão.
4. `--spec` precisa resolver fisicamente dentro do checkout admitido: specs externas antes
   aceitas passam a ser recusadas; aliases internos relativos e absolutos continuam válidos.

## Incidentes

### Preflight real no primeiro RED da coordenação

O fixture não tinha stubs globais e abriu uma sessão real do Claude. O JSONL registra um único
`tool_use`, `bash -c 'echo sdd-preflight-ok'`; o preflight também alcançou o probe de leitura
`gh auth status`. Não há evidência de escrita externa nem missão de produção. O custo não foi
preservado e permanece **desconhecido**. A isolação passou a ser fail-closed e ganhou controles
negativos antes de qualquer nova rodada.

### `git apply` no checkout compartilhado

Ao validar a correção do fixture sobrevivente, o autor criou uma cópia por `git archive`, mas
omitiu o `cd` antes de `git apply`. O patch atingiu `tests/check-gates.sh` no checkout compartilhado
durante a primeira certificação, quebrando o congelamento. O erro foi admitido, corrigido no
relatório e informado ao usuário. A corrida diagnóstica terminou rc 1, 372/373, sem carimbo e foi
descartada. O patch foi revisado, integrado deliberadamente e uma recertificação nova começou de
um snapshot limpo.

## Certificação válida

`SDD_MUTATION_JOBS=16 ./bin/sdd health` terminou rc 0 sobre
`8875643a31d67ef1189cc57615fd5886b7cc8d44`: 373/373 capturados, zero gap conhecido, suíte verde e
`kit healthy`. O controle extra sob 16 workers também ficou verde. Não houve drift; a chave antes,
depois e no carimbo foi `d15d55d80f67c0b6f77ee8f3a2f32796`.

A auditoria final encontrou 373 resultados, todos rc 1, sem log ausente nem mutante sem falha
nomeada. Os 27 mutantes novos e o antigo sobrevivente foram conferidos. Quatro grupos carregam
diagnósticos incidentais depois ou ao lado da detecção correta:

- `COORD_admission_missing`: comandos/ferramentas ausentes e traceback não são a evidência
  contada; as falhas nomeadas de lock, recusa e ausência de efeitos aparecem antes.
- `HEALTH_stamp_tree_blind`: o gate falha pela correspondência carimbo/árvore antes de um timeout
  posterior no probe de health.
- `RUN_escalation_hook_silent`: as asserções nomeadas de hook/contexto/ledger/prazo falham antes
  do `FileNotFoundError` de readiness.
- `RUN_guard_counts_escalations`: seis asserções corretas de população da guarda falham antes de
  um timeout posterior de oito segundos cuja causa não foi estabelecida.

Essas adjudicações não afirmam que toda suíte mutante terminou sem exceção; afirmam que nenhuma
exceção ou timeout foi a única razão que matou a propriedade catalogada.
