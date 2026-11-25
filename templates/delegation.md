---
campaign: <YYYYMMDD>-<slug — o id da campanha, igual ao campaign: do campaign.md ao lado>
level: <assisted | pr | plan | merge | full>
lots: <all, ou L1 L2 … separados por espaço>
expires: <YYYY-MM-DD HH:MM, hora local>
budget_mission_usd: <número de pelo menos 0.01 — o teto de cada missão, passado como assinado ao sdd run como BUDGET_MISSION_USD, se nenhum .sdd/config.sh lido (o da campanha e o de cada worktree que guarda missão dela) fixar essa chave acima dele; 0 é sem teto, e o budget para>
budget_campaign_usd: <número — o teto da campanha inteira, somado do ledger; o budget para quando o que resta dele é menor que o budget_mission_usd>
allow_unknown_cost:
signed:
---

# Delegação — <título da campanha>

> **Só o frontmatter acima é lido.** Esta prosa é para o dono, e nenhum verbo a lê. O
> `bin/sdd-worker` relê este arquivo a cada passo, e é ele, não uma palavra dita numa sessão, que
> decide o que o worker faz sozinho.
>
> O valor de uma chave é o texto depois do primeiro `: `, sem os espaços do fim e sem aspas.
> Enquanto um valor for um placeholder `<…>`, a delegação é **ilegível** e vale `assisted`.
> Ilegível também: um `campaign:` (o daqui ou o do `campaign.md` ao lado) que não é o nome do
> diretório, um `lots:` que não é `all` nem uma lista de lotes da tabela do `campaign.md` (o
> placeholder acima incluso: `<all,` não é lote), e um `expires:` que o relógio não tem
> (`2026-11-31 10:00`, `2026-11-18 99:99`).

## Os cinco níveis, cumulativos

| Nível | O que o worker faz sem perguntar |
|---|---|
| `assisted` | nada: propõe cada ato e espera o sim do dono |
| `pr` | roda a missão, abre o PR e trata os bots |
| `plan` | o de `pr`, e planeja a missão seguinte |
| `merge` | o de `plan`, e mergeia e faz o pós-merge |
| `full` | o de `merge`, e aprova o plano (`sdd approve`) |

Delegação ausente, ilegível, sem assinatura, editada depois de assinada ou vencida vale `assisted`.
Acima de `assisted`, um `ON_ESCALATION_CMD` vazio no `.sdd/config.sh` do checkout da campanha ou de
um worktree ligado que guarda uma missão dela também vale `assisted`, nomeando o arquivo, porque o
`sdd run` de uma missão roda no worktree dela e avisa pelo config de lá. Worktree sem missão da
campanha não é lido: nenhum `sdd run` dela roda ali, e ler o arquivo seria executá-lo. Uma noite sem
ninguém olhando precisa de um aviso que chegue. Pager fora do commit é escrito também em cada
worktree de missão.

## O teto por missão

O worker passa o `budget_mission_usd:` ao `sdd run` como `BUDGET_MISSION_USD`, no ambiente, e o
runner lê o `.sdd/config.sh` do checkout em que roda **por cima** do ambiente: uma linha que atribui
essa chave vence o teto assinado, e o `config/starter.conf` que o `sdd install` semeia atribui
`150`. O checkout em que o `sdd run` roda é o worktree da missão, não o da campanha, e um worktree
cortado de um commit que ainda tem a linha a carrega mesmo depois de ela ser apagada aqui. Por isso
o `bin/sdd-worker budget` lê o arquivo do checkout da campanha e o de cada worktree que guarda uma
missão dela, e de nenhum outro, cada um a partir do próprio checkout, e sai com rc 1 numa linha
`no mission cap — …`, que nomeia o arquivo e o valor, quando um deles fixa a chave acima do teto
assinado, em `0` (sem teto), vazia ou num valor que o runner recusa (ele aceita dígitos e no máximo
um ponto: `1e2` é recusado). Um valor menor ou igual ao assinado é o teto mais estrito, e vale. Um
`budget_mission_usd: 0` assinado também é sem teto para o runner, e um abaixo de `0.01` é menos que
o centavo em que o worker conta: os dois param o `budget` antes de ler qualquer `.sdd/config.sh`,
nomeando esta delegação. O teto que o `budget` imprime é o assinado, como está escrito.

Antes de assinar, resolva a linha `BUDGET_MISSION_USD` do `.sdd/config.sh` por um de dois caminhos:
apague-a e commite a remoção antes de cortar os worktrees das missões (um worktree cortado antes do
commit continua com a linha), ou deixe-a, no checkout da campanha e em cada worktree de missão, no
teto assinado ou abaixo dele.

## O teto da campanha

O `budget_campaign_usd:` é limite duro. Abaixo dele, o `bin/sdd-worker budget` compara o que resta
(o teto menos o gasto, em centavos) com o `budget_mission_usd:` assinado, também em centavos (a
fração de centavo arredonda para cima), e sai com rc 1 numa linha `no room — …`, que nomeia o resto
e o teto de missão, quando o resto é menor: o `run` seguinte pode gastar até o teto dele e passaria
do da campanha. Resto igual ao teto de missão ainda abre o `run`, e a campanha termina no teto. A
comparação é com o teto assinado, porque o que o runner aplica nunca passa dele (o `budget` já para
num `.sdd/config.sh` que o passa). Assim a campanha pode acabar com até um teto de missão sem usar,
e só passa do assinado por três gastos: o que o runner gasta além do próprio teto (ele lê o gasto
antes de abrir cada fase, e uma fase pode gastar além do `BUDGET_MISSION_USD`), o de uma missão que
o `budget` não acha, no parágrafo abaixo, e o da sessão que orquestra a campanha e dos subagentes
dela, que fica fora dos dois tetos: eles somam o ledger que o runner escreve nesta máquina, e essa
sessão não roda pelo runner. A parada vale antes de todo ato, o merge incluso; para
seguir, assine um teto de campanha maior ou um teto de missão de no máximo o que resta.

Uma missão da campanha que nunca chegou à base e cujo worktree foi removido não é achada, e
o gasto dela sai da soma: um PR fechado sem merge, ou uma missão largada depois de um
`budget-exhausted`, fica no disco só no worktree dela, a branch dela não é a base, e o ledger não
sabe de campanha. O `budget` responde então uma soma menor, com rc 0, e a campanha pode passar do
teto por esse gasto. Até o ledger saber de campanha (a direção está no `TODO.md` do kit),
remova o worktree de uma missão que não vai chegar à base só depois de
assinar um teto de campanha menor pelo que ela gastou: a soma do `cost_usd` das linhas do ledger
com o id dela.

## Sessões Codex sem valor faturado

`allow_unknown_cost:` é opcional. Ausente, vazio ou `false` não concede a exceção. Marque
`true` e assine só se aceitar sessões do Codex cujo valor faturado em dólares não é informado.
A opção exige `harness: codex` e `exec_model:` no `campaign.md`. Os três ficam cobertos pela
assinatura e não mudam o nível delegado. Antes de abrir cada sessão paga, inclusive nas novas tentativas, o runner confere a
delegação no checkout principal do repositório da missão, o lote, o ato, a validade e os dois
tetos de gasto conhecido. Uma cópia antiga no worktree da missão não vale.

No ledger, o valor faturado dessas sessões fica nulo, não zero. O `budget` informa o subtotal
conhecido e a quantidade de sessões sem valor faturado. Se houver estimativas, mostra o
subtotal estimado à parte, sem somá-lo ao gasto conhecido. Os tetos continuam limitando o
gasto conhecido, mas não garantem um teto em dólares para sessões sem valor faturado. A exceção
não cobre sessões de outros engines com valor desconhecido.

## Como assinar

1. Preencha as seis primeiras chaves, decida sobre `allow_unknown_cost:` e deixe `signed:` vazio.
2. Num terminal, rode `bin/sdd-worker delegate <diretório desta campanha>`: ele mostra o que está
   sendo concedido (as seis chaves, a opção quando preenchida e uma linha
   `ceiling <lote>: <teto>` por lote do `campaign.md` ao lado) e pergunta. Só `y` assina. Uma
   edição salva enquanto a assinatura é gravada fica no arquivo, e nada é assinado.
   Rode o `delegate` de novo.
3. A assinatura grava `signed: <YYYY-MM-DD HH:MM> <digest>`. O digest cobre os termos mostrados,
   inclusive o `harness:` e o `exec_model:` quando a exceção é `true`, e o `Lot` e o `Ceiling` de cada linha da
   tabela. Uma assinatura antiga continua válida se a opção estiver ausente ou vazia. Se mudar
   os termos, um teto ou um lote da tabela, a delegação volta a valer `assisted` até ser assinada
   novamente. Riscar itens e reescrever o título ou a contagem de um lote não invalida a assinatura.
4. Commite o arquivo: a delegação é versionada no repo-alvo, e o commit é a trilha.
