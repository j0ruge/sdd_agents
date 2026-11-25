# Notas de execução — Worker de campanhas com Codex

## Candidato a retrofit de skill

No Ubuntu 24.04, `bin/sdd-codex --preflight` retornou `bwrap: loopback: Failed RTM_NEWADDR:
Operation not permitted`. O journal do kernel confirmou `apparmor="DENIED"` para
`capname="net_admin"` no perfil `unprivileged_userns`, durante a execução de `/usr/bin/bwrap`.
O login e o teste de retomada já passavam.

O pacote oficial `apparmor-profiles` contém `usr/share/apparmor/extra-profiles/bwrap-userns-restrict`.
Após `apt-get download apparmor-profiles` e extração com `dpkg-deb -x`, o perfil compilou com
`apparmor_parser -Q -K <perfil>`. O operador o carregou no kernel com
`sudo apparmor_parser -r -K <perfil>`, sem desativar a proteção global. O preflight então
imprimiu `CLI, login and command sandbox available` e saiu com rc 0.

Para o futuro retrofit, usar o preflight como critério, confirmar a recusa no journal e
preferir o perfil oficial do pacote local. Carregar no kernel vale até o reboot. A autorização
para esse host não é permissão genérica para alterar outras máquinas.
