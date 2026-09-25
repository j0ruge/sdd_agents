# O sensor para no primeiro FAIL — o `sdd health` abaixo de 20 minutos (2026-09-25)

> Spec do **P2(b) da frente F1** da [gaveta do kit](2026-09-23-a-gaveta-do-kit.md), escrita com o
> humano presente, logo depois do merge do PR #168 (o passo assassino primeiro, `8f2f2a9`). A meta
> que o humano fixou nesta sessão: **performance, o tempo o mais baixo possível**. Por isso o spec
> leva, além do P2(b), três alavancas escolhidas por ele: o controle em paralelo, a ordem do mais
> longo primeiro e o `check-coordination.sh`. Os números abaixo foram medidos em 2026-09-25, e a
> estimativa de cada alavanca vem dessas medições.

## 1. O problema, medido

O `sdd health` roda o catálogo de mutação inteiro e é a última coisa antes de todo merge do kit
(o `gate_PR` exige o carimbo). Depois do #168 ele leva **37 min 42 s** (406 de 406, `cc03abd`), e
esse tempo se divide assim:

| Fase | Tempo | Fonte |
|---|---|---|
| Suíte verde (`run-all.sh` fora de mutante) | 3,6 min | a suíte rápida sozinha: 15:02:23 → 15:05:59 |
| Controle do catálogo (kit sem sabotagem sob `SDD_MUTANT=1`) | ~3,9 min | soma dos passos do controle da amostra abaixo: 231 s |
| Pool de 406 mutantes, 16 jobs | ~30 min | o resto |

Com o mapa de assassinos, cada mutante já roda **só o passo que o matou** (P2(a)). O custo que
sobra é o do próprio passo assassino, e dez sensores dividem as 406 mortes: autonomy 158, gates
104, kaizen 38, preflight 25, coordination 21, health 19, adr 15, hat 14, dry-run 11, entrypoint 1.

**Amostra fixa.** 24 mutantes sorteados do mapa com semente `20260925`, estratificados pelos
quatro maiores assassinos (autonomy 12, gates 8, kaizen 2, preflight 2). Cada um rodou na sandbox
real (`sandbox` e `apply_mutant` carregados do `check-mutation.sh`), com `SDD_MUTANT=1` e
`SDD_MUTANT_FIRST=<assassino>`, cada linha do log carimbada com o tempo, 12 jobs, mais uma rodada
de controle. Os 24 saíram com rc 1, e em todos só o passo assassino rodou.

| Assassino | n | Tempo do sensor | Até o 1º FAIL | Corte | Mediana 1º FAIL / sensor |
|---|---|---|---|---|---|
| autonomy ledger | 12 | 846,4 s | 424,2 s | 49,9% | 0,48 |
| gate state machine | 8 | 404,4 s | 167,7 s | 58,5% | 0,28 |
| kaizen series and gate | 2 | 28,2 s | 14,1 s | 50,0% | — |
| preflight and the install guard | 2 | 49,7 s | 18,4 s | 63,0% | — |
| **total** | 24 | **1328,7 s** | **624,4 s** | **53,0%** | |

Todo o tempo do sensor depois do primeiro FAIL é pago e não é lido: o catálogo só lê o rc da
suíte, e o rc já está decidido no primeiro FAIL.

## 2. Objetivo e critério de sucesso

- **Meta:** o `sdd health` em **20 min ou menos**, na 2ª rodada depois do merge (a 1ª grava os
  tempos que a ordem usa). Projeção: P2(b) ~22,5 min, mais o controle em paralelo ~18,6 min, mais
  o mais longo primeiro ~17,5 min.
- **Nenhum veredito muda.** 406 de 406 continuam pegos, e 0 de 24 rc diferentes na amostra.
- **Fora de mutante, nada muda.** Quem roda um sensor à mão continua vendo todos os vermelhos.
- **O kit sem sabotagem continua verde sob `SDD_MUTANT=1`.** Quem cobra é o controle do catálogo.
- **Os selftests continuam medindo o que dizem.**

## 3. Desenho

### 3.1 O sensor para no primeiro FAIL

Nos nove sensores que rodam dentro de mutante e têm um ponto único de falha, o registro de uma
asserção vermelha passa a terminar o sensor quando `SDD_MUTANT` não é vazio. A saída vem
**depois** de imprimir e contar: o log do mutante continua dizendo o que o matou, e é dele que o
`killer_of` lê o passo.

| Sensor | Onde | Mudança |
|---|---|---|
| `check-autonomy.sh` | `fail()`, linha 36 | acrescenta `[ -z "${SDD_MUTANT:-}" ] \|\| exit 1` |
| `check-gates.sh` | `fail()`, linha 34 | idem |
| `check-kaizen.sh` | `fail()`, linha 34 | idem |
| `check-preflight.sh` | `fail()`, linha 41 | idem |
| `check-health.sh` | `fail()`, linha 103 | idem |
| `check-adr.sh` | `fail()`, linha 207 | idem |
| `check-hat.sh` | `fail()`, linha 45 | idem |
| `check-dry-run.sh` | `fail()`, linha 38 | idem |
| `check-coordination.sh` | `check()` do Python, linha 71 | no ramo vermelho, `if os.environ.get("SDD_MUTANT"): raise SystemExit(1)` |

Os oito em bash somam 384 das 406 mortes; com o coordination, 405. Nenhum dos oito chama `fail()`
num subshell (as 12 ocorrências que o `grep` acusou em `hat` e `preflight` são falsas: o `$(...)`
está na condição, ou o texto "fail" está dentro de um padrão), e nenhum deixa processo em
segundo plano. O `exit` dispara o `trap … EXIT` que cada sensor já tem para apagar as fixtures.
No coordination, o `SystemExit` atravessa o `try:` da linha 260, e o `finally:` da linha 736 já
libera as famílias de processo, mata só os PIDs com identidade conferida e apaga `work`. Nenhum
`except` genérico engole o `SystemExit`, e as threads do arquivo existem só nos scripts de
fixture, gravados como texto.

**O selftest do `hat` roda o filho fora do mutante.** A linha 117 roda o próprio
`check-hat.sh --check` como processo filho e exige que a saída **nomeie** a regra violada. Esse
filho mede o caminho de relatório que o humano vê, então ele roda com `env -u SDD_MUTANT`. A
regra geral, escrita no comentário do censo: sensor que roda a si mesmo para medir o relatório
roda esse filho fora do mutante. Hoje esse é o único caso. O `check-preflight.sh:803` chama o
`check-todo.sh`, que não tem `fail()`, e o `check-health.sh` só copia os outros sensores e faz
`grep` neles.

**Por que nenhum veredito muda.** O catálogo só lê o rc da suíte. Um sensor que chamou `fail()`
já termina com 1: os oito em bash fecham com `exit 1` quando `fails` não é zero, e o coordination
com `sys.exit(1 if failed else 0)`. A saída antecipada muda **quando** o sensor termina, nunca
**se** ele fica vermelho. Um sobrevivente não chama `fail()` e roda tudo, como hoje.

**As duas redes para o que esta leitura não achou:**
- **Um `fail()` chamado de propósito, esperando continuar** (um controle negativo). Sob a regra
  nova, o sensor sai vermelho no kit sem sabotagem. O controle do catálogo roda exatamente esse
  regime (`SDD_MUTANT=1`, kit intacto), fica vermelho e para o catálogo como HARNESS-BROKEN, alto,
  antes de pontuar qualquer mutante.
- **Um `fail()` num subshell.** Ali o `exit` para só o subshell. Um caso desses já perde o
  `fails` hoje, então não é risco novo, só um ponto sem ganho.

### 3.2 O censo que segura os nove

No `check-health.sh`, junto das probes do mapa de assassinos (`surface:`).

- **Enumera, não amostra.** A população sai da própria suíte: os passos de
  `SDD_MUTANT=1 tests/run-all.sh --list`, cada um ligado ao `tests/check-*.sh` que o
  `run-all.sh` executa naquele passo. Todo sensor dessa lista que define `fail()` em bash, ou
  `check()` no Python embutido, entra no censo.
- **Mede comportamento, não grafia.** Cada definição é carregada com a guarda de tamanho da probe
  do `killer_of` (uma função curta e fechada, ou SENSOR-BROKEN) e chamada três vezes:
  - sob `SDD_MUTANT=1`, sai com rc 1 **e** o FAIL já foi impresso;
  - com `SDD_MUTANT` ausente, volta, e `fails` (ou `failed`) subiu 1;
  - com `SDD_MUTANT=` vazio, volta.
  - A quarta asserção lê o `check-hat.sh`: o filho do selftest roda sob `env -u SDD_MUTANT`.
- **Piso contra vacuidade.** Se o censo encontrar menos sensores que o piso (hoje, 9), o
  resultado é SENSOR-BROKEN, nunca "0 violações".
- **Exceção declarada, com o motivo no comentário:** `check-entrypoint.sh` (1 morte, 0,5 s, sem
  `fail()`).
- **Sensor novo sem a cláusula deixa o censo vermelho.** O CLAUDE.md pede isso de toda porta:
  porta acrescentada sem probe é porta cuja remoção ninguém percebe.

### 3.3 O controle em paralelo

- **Hoje:** o controle roda sozinho, e só depois o pool começa.
- **Depois:** o controle é o **primeiro job do pool**, ocupando uma das 16 vagas, e os mutantes
  começam junto com ele.
- **O placar só sai depois do controle verde.** A contagem de pegos e o `score:` são escritos só
  depois de conferido o rc do controle, então nenhum veredito muda.
- **Controle vermelho:** a cada `wait -n`, o laço confere se o controle terminou. Vermelho, ele
  **para de lançar** mutantes, espera os que já estão rodando e sai com HARNESS-BROKEN. Nada é
  morto: os filhos de cada mutante (`sdd`, o helper de coordenação e seus locks) não têm grupo de
  processo próprio, e matar só o subshell deixaria órfãos. O custo da falha fica em ~4 min mais a
  duração de um mutante, contra ~4 min hoje.
- **Degradação declarada:** bash sem `wait -n` (< 4.3) roda o controle antes do pool, como hoje,
  e diz isso na linha de cabeçalho.
- **Risco novo, na direção segura:** o controle passa a rodar sob carga total. Um probe sensível a
  tempo (frente P3) pode ficar vermelho só por isso. O resultado seria um HARNESS-BROKEN falso,
  alto, nunca um veredito errado. A verificação (§5) roda o controle sob carga antes do merge.

### 3.4 O mais longo primeiro

- **O mapa ganha uma terceira coluna:** `slug TAB passo TAB segundos`. Os segundos são medidos
  com `$SECONDS` (existe no bash 4) em volta da suíte do mutante, dentro do `run_mutant`.
- **A ordem de lançamento:**
  1. os mutantes sem tempo registrado (novos, sobreviventes, linha antiga de duas colunas), na
     ordem do catálogo, porque são os que rodam a suíte inteira;
  2. depois, os com tempo, do mais longo ao mais curto;
  3. empate resolvido pela ordem do catálogo.
- **O placar continua na ordem do catálogo.** A saída do health não muda de forma.
- **Compatibilidade:** o mapa de hoje (duas colunas) é lido sem erro. A 1ª rodada depois do merge
  já corta pelo P2(b) e grava os tempos; a 2ª usa a ordem.
- **A ordem não afeta veredito:** cada mutante roda na própria sandbox.

### 3.5 As probes do pool

Três probes novas:
1. dado um mapa com tempos, os mutantes são lançados do mais longo ao mais curto, com os sem tempo
   na frente;
2. um mapa de duas colunas é aceito;
3. com o controle vermelho, sai HARNESS-BROKEN, não há `score:`, e nenhum mutante é lançado depois
   da leitura do rc do controle.

Onde moram fica para o plano: no mundo de catálogo fixture que o `check-health.sh` já monta, se
ele consegue observar a ordem de lançamento; senão, no próprio `check-mutation.sh`, com uma suíte
stub, no molde do `jobs_selftest`.

## 4. Fora do escopo — limites declarados

- **`check-entrypoint.sh`** fica sem a cláusula (1 morte, 0,5 s).
- **bash < 4.3** mantém o controle antes do pool.
- **A ordem das asserções dentro do sensor** fica como está. Em `autonomy` o 1º FAIL sai, na
  mediana, aos 48% do sensor, e há mutantes em que ele só sai aos 92%. Reordenar asserções é a
  próxima alavanca, com desenho próprio: as fixtures dependem da ordem.
- **Mais jobs (16 → 20):** recusado pelo humano nesta rodada. Continua na frente P3.
- **O 2º Python do worker (P1)** continua na gaveta: pede ADR.

Os cinco são limite de desempenho, não sensor que afirma medir o que não mede. Pela régua D15,
moram neste spec, na gaveta e no comentário do censo, não no `TODO.md`.

## 5. Verificação e medição

**Ordem de trabalho, TDD, cada incremento com o Check escrito antes:**
1. **O censo**, que nasce **vermelho**: hoje nenhum dos nove sai sob `SDD_MUTANT`.
2. **A cláusula nos nove** e o `env -u SDD_MUTANT` no selftest do `hat`. O censo fica verde, e a
   suíte inteira sob `SDD_MUTANT=1` numa sandbox fica verde (o regime do controle).
3. **As probes do pool, vermelhas;** depois o controle em paralelo e o mais longo primeiro, verdes.
4. **A passada de sabotagem**, cada uma exigindo vermelho:
   - tirar a cláusula de um sensor;
   - trocar `exit 1` por `return 1`;
   - pôr a cláusula antes do `printf`;
   - o censo enumerar só metade dos passos (o piso reprova);
   - o pool ignorar os tempos;
   - o controle vermelho ainda publicar placar;
   - o mapa de duas colunas ser recusado.

**Medição:**
- **Diferencial na amostra fixa:** os mesmos 24 mutantes, a mesma semente e o mesmo harness.
  Exige 0 de 24 rc diferentes e compara a soma contra os 1328,7 s de hoje.
- **O controle sob carga:** 3 rodadas com o pool cheio, sem nenhum vermelho.
- **`sdd health` duas vezes**, sempre pelo lançador com `SIG_DFL` e sem `CLAUDE*` no ambiente. A
  1ª corta pelo P2(b) e grava os tempos. A 2ª mede tudo junto e carimba.

## 6. Entrega

- Branch `perf/sensor-para-no-primeiro-fail`, um commit por incremento.
- `KAIZEN_LOG.md` com a tabela antes/depois; a gaveta com o P2(b) marcado FEITO e o número medido;
  a linha do CLAUDE.md sobre o catálogo ganha a regra "sob `SDD_MUTANT` o sensor para no primeiro
  FAIL".
- PR, esperar **todos** os revisores, consertar numa leva, carimbar **uma vez**, merge com o ok do
  humano.

## 7. Riscos

| Risco | Direção | Quem pega |
|---|---|---|
| Um sensor chama `fail()` num controle negativo | seguro: fica vermelho no kit intacto | o controle do catálogo (HARNESS-BROKEN) e a rodada da §5, passo 2 |
| O controle, agora sob carga, dá vermelho por tempo | seguro: HARNESS-BROKEN falso | as 3 rodadas sob carga da §5 |
| Sensor novo nasce sem a cláusula | desempenho, não veredito | o censo |
| O `SystemExit` no coordination pula uma limpeza fora do `finally` | vazamento de processo ou lock | leitura desta seção, mais o `pgrep` depois da amostra diferencial |
| O mapa de três colunas quebra um leitor antigo | desempenho | a probe 2 da §3.5 |
