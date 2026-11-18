---
campaign: <YYYYMMDD>-<slug — o id da campanha, igual ao campaign: do campaign.md ao lado>
level: <assisted | pr | plan | merge | full>
lots: <all, ou L1 L2 … separados por espaço>
expires: <YYYY-MM-DD HH:MM, hora local>
budget_mission_usd: <número de pelo menos 0.01 — o teto de cada missão, passado como assinado ao sdd run como BUDGET_MISSION_USD, se nenhum .sdd/config.sh lido (o da campanha e o de cada worktree que guarda missão dela) fixar essa chave acima dele; 0 é sem teto, e o budget para>
budget_campaign_usd: <número — o teto da campanha inteira, somado do ledger; o budget para quando o que resta dele é menor que o budget_mission_usd>
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
e só passa do assinado pelo que o runner gasta além do próprio teto: ele lê o gasto antes de abrir
cada fase, e uma fase pode gastar além do `BUDGET_MISSION_USD`. A parada vale antes de todo ato, o
merge incluso; para seguir, assine um teto de campanha maior ou um teto de missão de no máximo o que
resta.

## Como assinar

1. Preencha as seis primeiras chaves e deixe `signed:` vazio.
2. Num terminal, rode `bin/sdd-worker delegate <diretório desta campanha>`: ele mostra o que está
   sendo concedido (as seis chaves e uma linha `ceiling <lote>: <teto>` por lote da tabela do
   `campaign.md` ao lado) e pergunta. Só `y` assina. Uma edição salva enquanto a assinatura é gravada
   fica no arquivo, e nada é assinado: rode o `delegate` de novo.
3. A assinatura grava `signed: <YYYY-MM-DD HH:MM> <digest>`, e o digest cobre as seis chaves e o
   `Lot` e o `Ceiling` de cada linha da tabela de lotes do `campaign.md`. Mudar uma das seis chaves,
   subir ou baixar um teto, ou pôr ou tirar um lote da tabela depois disso invalida o digest, e a
   delegação volta a valer `assisted` até ser assinada de novo. Riscar itens e reescrever o título
   ou a contagem de um lote não invalida: a campanha faz isso enquanto anda.
4. Commite o arquivo: a delegação é versionada no repo-alvo, e o commit é a trilha.
