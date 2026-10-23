# Reincidência no TODO.md — design

Data: 2026-10-23. Pedido do dono, conversado na sessão do relay do `/sdd-plan` da 3.4b do `dotp-remake`.

## Intenção

Um achado que volta, apontado por outro projeto ou outra missão, é o sinal mais forte de que a dor é real. Hoje
essa volta se perde. Quem acha o item já registrado não tem o que fazer com ele, e pula. O dono quer que a
volta fique registrada no próprio item, que o item reincidente ganhe prioridade e que isso apareça onde ele
escolhe o que consertar: no `TODO.md` e nas issues que o `todo-to-github-issues` espelha.

Caso medido, que motivou o pedido: o item "O `/sdd-plan` delega ao `sdd-planner` sem saída para o agente não
registrado" (`TODO.md:175` do kit, na `1e49e30`).
- **O que o item já registra:** duas ocorrências escritas à mão no campo final ("descoberto pelo relay… no
  `dotp-remake` (2026-10-19) e por `retrofit-watch` no `magic_tutor` (2026-10-20)"). Nada conta isso.
- **O que se perdeu:** a falha voltou na 3.4a (2026-10-22) e na 3.4b (2026-10-23) do `dotp-remake`. Na retro da
  3.4b o relay achou o item e não escreveu nada, porque o item já estava no teto de 8 linhas e não havia forma
  de somar a volta.

## Objetivos

1. **Registrar a volta no item que já existe.** Quem encontra um achado que já está aberto soma uma
   ocorrência a ele, sem duplicar e sem pular.
2. **Contagem medida.** O sensor do kit (`tests/check-todo.sh`) confere que o número declarado bate com as
   ocorrências listadas, e que cada uma tem onde e quando. É o princípio 2 do kit: um número em prosa que
   ninguém mede apodrece.
3. **Prioridade visível.** O item mostra a contagem no `TODO.md`. A issue espelhada ganha uma label filtrável
   (`gh issue list --label reincidente`).
4. **Todo escritor conhece a regra.** Hoje são quatro:
   - os chapéus do kit que escrevem no `TODO_FILE`;
   - o relay do `/sdd-plan`;
   - a retro pedida pelo `retrofit-watch`;
   - a triagem manual dos LOW de PR.
5. **Migrar as voltas que já existem escritas à mão.** No kit são três itens (linhas na `1e49e30`):
   - `TODO.md:155-159`, "O `sdd install` adota a branch atual…";
   - `TODO.md:175-182`, o do `/sdd-plan` acima;
   - `TODO.md:296-302`, "O corpo do PR promete CI…".

   Nos alvos desta máquina com `.sdd` (`dotp-remake` e `magic_tutor`), o revisor não achou nenhuma. Os outros
   alvos (`sales_quote`, `lighthouse_project`, `ui24_agent`, as missões `amep-*`) não estão aqui e não são
   migrados. Eles adotam a linha quando o kit avança neles, e o sensor aceita o item sem ela (ver "Restrições").
   É decisão minha.

## Não-objetivos (desta versão)

- **O kit não age sozinho sobre a prioridade.** Por exemplo, o planner não passa a puxar primeiro os
  reincidentes ao montar um lote. Fica como próximo passo, depois que a contagem existir e for confiável.
- **Nada de peso composto.** Não há pontuação, nem severidade × reincidência. A contagem é o peso.
- **Nada de detecção automática de duplicata por semelhança de texto.** Quem registra decide se é o mesmo
  achado (o `RENAME?` do espelho é outra coisa).
- **Nada de sincronizar entre os `TODO.md` de repos diferentes.** Cada arquivo é a fonte da verdade do seu repo,
  e a ocorrência só cita o projeto em que a falha voltou.
- **Registro decidido não conta reincidência.** Se um achado que já foi decidido volta, quem o encontrou avisa o
  dono, que decide se reabre. Confirmado pelo dono.

## Anti-objetivos (o que faria isto falhar, mesmo funcionando)

- **Reabrir a porta para itens longos.** O teto de 8 linhas existe porque o `TODO.md` do kit chegou a 861 linhas,
  com item mediano de 10 (cabeçalho do `check-todo.sh`). Uma ocorrência é uma entrada curta de forma fixa, nunca
  um parágrafo.
- **Uma contagem que o sensor não mede.** É o "e por" de hoje.
- **Quebrar a chave do espelho.** O título é a chave da issue, e mudá-lo dá `RENAME?`. A contagem nunca vai no
  título.
- **Inflar a contagem.** Uma missão ou sessão que relê o próprio achado não conta.

## Restrições

- **O token da linha é contrato, em inglês e igual em todo idioma**, como o `RESOLVED by` e os marcadores
  `sdd:open`/`sdd:decided`. O texto das entradas segue o idioma do repo.
- **O dono autorizou subir o teto de 8 linhas** ("Pode aumentar o limite, se isso está atrapalhando").
  - **Minha decisão:** em vez de subir o teto para todo o corpo, isentar só a linha de reincidência, como o
    sensor já isenta a âncora longa (issue #257, `check-todo.sh:28`). O resto do item continua no teto e na
    largura de 120.
- **Compatível para trás.** O sensor novo chega ao gate dos alvos assim que o `~/repos/sdd_agents` avança. O
  `TEST_CMD` do `magic_tutor` chama `$SDD_HOME/tests/check-todo.sh --check … --baseline`. Por isso, um `TODO.md`
  sem nenhuma linha de reincidência passa exatamente como hoje, e só a linha nova, quando existe, é medida.
- **Regra 4 do sensor.** A data na última linha é o campo "descoberto por". A colocação da linha nova não pode
  esvaziar essa regra.
- **O espelho é idempotente.** Uma mudança só na linha de reincidência não deve cair no `UPDATE (text)`, o único
  `UPDATE` que pede leitura humana. Hoje ela cairia lá.
- **O espelho exige recursos do kit** (a tabela de requisitos do `SKILL.md` do `todo-to-github-issues`). A
  contagem nova entra nessa tabela, com a recusa clara de um kit mais velho.
- **Onde se escreve:**
  - O checkout `~/repos/sdd_agents` é o que o `sdd` do PATH executa, e o kit muda numa worktree ligada, com
    PR.
  - As duas skills moram em `~/repos/skills` (marketplace `j0ruge/skills`), hoje 45 commits atrás do
    `origin/main`. Antes de mexer, avançar com `--ff-only`. A versão sobe com CHANGELOG, como o
    `/retrofit-skill` faz no modo completo.
- **ADR.** O formato do `TODO.md` é contrato do kit, e o ADR 0011 (a âncora com símbolo) é o precedente. Esta
  mudança pede um ADR.

## O que foi decidido

Do dono:
- conta como reincidência o achado apontado de novo por outro projeto, e também por outra missão ou sessão do
  mesmo projeto;
- prioridade visível no `TODO.md` e nas issues;
- o teto pode subir;
- a linha lista só as voltas, e a primeira ocorrência fica no "descoberto por" (confirmou a decisão 2 abaixo);
- quando volta um achado que já foi decidido, quem o achou avisa o dono e não conta (confirmou o não-objetivo).

Minhas decisões, para o dono conferir:
1. **Desta versão:** a prioridade é ver e filtrar. O kit não reordena nada sozinho.
2. **Quem é a primeira ocorrência:** a do "descoberto por", que continua como está. A linha nova lista só as
   voltas, e o número é o de voltas. O item é reincidente quando a linha existe.
3. **Uma ocorrência por projeto e missão (ou sessão).** Cada entrada traz o projeto, onde (missão ou sessão) e a
   data.
4. **O teto:** isenta-se a linha de reincidência, e o teto do corpo fica em 8.
5. **A label da issue é `reincidente`**, posta quando a linha existe e tirada quando ela sai.
6. **Ordem de entrega:** primeiro o kit (formato, sensor, template nos idiomas, ADR, a regra nos escritores),
   depois o espelho, depois o texto do `retrofit-watch`, e por fim a migração. O espelho lê o sensor do kit.
7. **A regra para quem escreve** entra ao lado da que já existe ("Antes de registrar, leia os decididos: o que
   está lá não volta"): leia também os abertos, porque o achado que já está lá ganha uma ocorrência, não um
   item novo.
   - Ela entra no preâmbulo do `templates/todo*.md`, que todo `TODO.md` carrega. É ele que governa o quarto
     escritor, a triagem manual dos LOW de PR, que não tem arquivo próprio.
   - O `coderabbit-pr`, do plugin `codereview`, não muda nesta versão.
8. **A migração do item do `/sdd-plan` aplica a decisão 3.** O "descoberto por" fica com a 3.2b do
   `dotp-remake` (2026-10-19). São 4 voltas: a 3.2c (2026-10-19, outra missão), o `magic_tutor` (2026-10-20), a
   3.4a (2026-10-22) e a 3.4b (2026-10-23).

## O que fica para quem constrói

- O token exato e a gramática da linha: a forma de cada entrada, o separador, e se o número vai explícito ou
  sai da contagem das entradas.
- Onde a linha fica no item em relação à `Fonte:` e ao "descoberto por", respeitando a regra 4.
- O que fazer quando as entradas passam da largura de 120. Por exemplo, a linha guarda as N mais novas e o
  total, e a lista completa vai para o handoff citado.
- As mensagens do sensor, os testes dele (casos que falham de propósito) e se o `--count` passa a relatar
  reincidentes.
- Como o espelho classifica a mudança só de reincidência (um `UPDATE` de tipo próprio), a cor da label e o caso
  da label apagada à mão.
- O texto do Stop hook do `retrofit-watch` (`plugins/retrofit-watch/skills/retrofit-watch/scripts/retrofit_watch.py`)
  e em que pontos do kit a regra é escrita: o `templates/todo*.md`, os `agents/*.md` que escrevem no
  `TODO_FILE` e o `commands/sdd-plan.md`.
- Como confirmar que a lista de migração do objetivo 5 está completa. O `grep -c ' e por ' TODO.md` achou só 1
  dos 3, porque o "e por" no fim de linha e o "e no `<projeto>`" escapam dele. A busca tem de ler o campo final
  de cada item, não uma expressão solta.

## Sucesso

Na próxima vez que uma retro, um planner ou uma triagem cruzar um achado que já está aberto:
- a ocorrência entra no item no mesmo commit;
- o `check-todo.sh --check` e o `--anchors` ficam verdes;
- o próximo `--apply` do espelho põe a label `reincidente` sem pedir leitura;
- o item do `/sdd-plan` acima mostra as voltas da 3.4a e da 3.4b.
