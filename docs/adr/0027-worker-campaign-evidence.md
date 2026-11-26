# ADR 0027 — Planejamento antecipado e evidências do merge delegado

- **Status**: accepted (—, 2026-11-26)
- **Spec**: docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/00-missao.md
- **Relacionada**: ADR 0022

## Contexto

O `sdd-worker next` informa que um lote sucessor pode ser planejado, mas o procedimento de
execução pode chegar à espera do PID do predecessor sem acionar o planner. Algumas campanhas
querem adiantá-lo e outras exigem aguardar o merge. O próximo plano precisa sobreviver à troca
de sessão e manter uma identidade única quando duas retomadas concorrem.

O `pr-ready` verifica a revisão e os threads. Para fechar o lote #419, a campanha precisa
também de evidência da suíte no SHA efetivo do PR, de uma decisão sobre pedidos de alteração
vigentes e de registro do que aconteceu com os achados publicados apenas no corpo da revisão.

## Decisão

A sessão orquestradora aciona o planner do sucessor indicado por `ahead plan` depois de
observar que o runner do predecessor adquiriu o próprio checkout. O disparo vale quando há
um pedido escrito e identificável do dono para aquela campanha. Em outra situação, o sinal
continua sendo uma sugestão.

O orquestrador revalida orçamento e autorização para o lote e usa um worktree separado.
Reserva a identidade da campanha, do lote e da missão antes de lançar o relay e recupera
a mesma sessão nas retomadas. A assinatura continua sendo verificada a cada turno Codex.
O planejamento produz um rascunho. A aprovação e o EXEC dependem do merge do predecessor,
da base integrada, da validação do plano e das permissões aplicáveis.

O ato `review` publica o resultado da suíte em `local/ci` para o SHA que testou. Um head novo
exige resultado próprio. O mesmo ato registra como tratou achados publicados no corpo da
revisão e só resolve threads com evidência. Um pedido de alterações ainda vigente bloqueia
o merge mesmo quando não traz comentários em linha.

## Alternativas consideradas

- Disparar por padrão em toda campanha com permissão de planejar. Isso obrigaria campanhas
  que precisam aguardar o merge a declarar uma exceção antes de manter seu comportamento.
- Acrescentar uma chave à delegação para o planejamento antecipado. A autorização de plano
  por lote já existe. A nova chave exigiria assinar de novo campanhas com pedido registrado.
- Depender de um check da infraestrutura de CI. O ato `review` já executa a suíte, portanto
  pode publicar o resultado diretamente para o head que verificou.

## Consequências

O planejamento ocupa um worktree próprio e pode sobrepor seu tempo ao EXEC do predecessor,
sem adiantar o aceite ou o lançamento do sucessor. A retentativa recupera a identidade
reservada e evita dois relays para o mesmo lote. Campanhas sem pedido mantêm o sinal como
sugestão. A publicação de status exige permissão no GitHub e uma publicação por head testado.
A falta de evidência mantém o PR pendente com a causa registrada.
