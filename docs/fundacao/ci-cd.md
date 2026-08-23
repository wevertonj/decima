# CI/CD — GitHub Actions

> Pipeline de integração e entrega contínua: fluxo de branches `dev` → PR → `main`, gates de qualidade (commitlint, format, analyze, testes com cobertura, builds), versionamento automático SemVer com changelog e distribuição via Firebase App Distribution e GitHub Releases.

## Fluxo de Branches

| Branch | Papel | Regras (ruleset) |
|---|---|---|
| `dev` | Branch de trabalho e integração — commits diretos permitidos | `dev-integracao`: bloqueia force-push e deleção |
| `main` | Somente releases — **nenhum commit direto** | `main-protegida`: exige PR + checks `commitlint`, `analyze`, `test`, `build-android`, `build-windows`, `build-linux`; bloqueia force-push/deleção; bypass apenas para deploy keys (bot de release) |

- Branch padrão do repositório: `main` — quem clona ou abre o repositório cai na versão estável. O trabalho do dia a dia é na `dev` (`git switch dev` após o clone)
- Release = merge de PR `dev` → `main`; o versionamento acontece automaticamente após o merge
- Como a `main` é o default, PR aberto pela UI/`gh` já vem com `base: main`: **conferir a base** ao abrir PR de branch de feature, que deve mirar a `dev`

## Workflows

| Arquivo | Gatilho | Função |
|---|---|---|
| `.github/workflows/ci.yml` | PR para `dev`/`main`; push em `dev` | Gates de qualidade + build dev + distribuição do grupo `dev` |
| `.github/workflows/release.yml` | Push em `main` (merge de PR) | Bump SemVer + changelog + tag + builds de release + Firebase `stable` + GitHub Release |
| `.github/actions/setup-flutter/action.yml` | — (ação composta) | Instala o Flutter pinado no `.fvmrc` (com cache) e roda `flutter pub get` |

### Jobs do CI (`ci.yml`)

| Job | O que valida | Ferramenta |
|---|---|---|
| `commitlint` | Mensagens Conventional Commits no range do PR/push | `commitlint_cli` (Dart) + `commitlint.yaml` |
| `analyze` | `dart format --set-exit-if-changed` + `flutter analyze` (zero warnings) | SDK |
| `test` | `flutter test --coverage` + gate de cobertura mínima (`MIN_COVERAGE`, linhas via lcov) | SDK + awk |
| `build-android` | APK release (assinado quando há secrets); push em `dev` distribui ao grupo `dev` do Firebase | Gradle + `firebase-tools` |
| `build-windows` | Bundle Windows + runtime MSVC app-local, zipado como artefato; roda em push na `dev` e PR para `main` | `flutter build windows` |
| `build-linux` | Bundle Linux + `.deb` (`~dev.N`/`~pr.N`) como artefato; mesmo gating do `build-windows` | `flutter build linux` + `tool/deb/build_deb.sh` |

- Builds dev usam `--build-name=<versão>-dev.<run>`; o `versionCode` de **todo** APK do CI (dev e stable) é `minutos desde a epoch Unix` — sequência monotônica única entre branches, sem downgrade ao alternar canal (teto do Android: 2,1 bi; esgota só no ano ~5960)
- PRs de fork rodam **sem secrets**: assinatura cai na chave de debug e nenhuma distribuição acontece (só ocorre em `push`, que fork não dispara)

### Jobs do Release (`release.yml`)

| Job | Função |
|---|---|
| `bump-version` | Roda `tool/bump_version.dart`; com bump: commita `chore(release): vX.Y.Z+B`, cria tag `vX.Y.Z` e push via deploy key |
| `release-android` | APK assinado, renomeado `decima-<semver>-android.apk`, distribuído ao grupo `stable` com notas do `CHANGELOG.md` |
| `release-windows` | `flutter build windows --release` + runtime MSVC + instalador Inno Setup (`tool/installer/decima.iss`) + `.sha256` |
| `release-linux` | `flutter build linux --release` + `tool/deb/build_deb.sh --skip-build` → `decima-<semver>-linux-amd64.deb` + `.sha256` |
| `publish-release` | GitHub Release `vX.Y.Z` com APK, instalador Windows, `.deb` Linux e notas da seção do changelog |

## Motor de Versionamento (`tool/bump_version.dart`)

Portado do hook `pre-push` (decisões D5/D6) dos projetos `runway`/`verbum`/`dosia` — aqui invocado pelo CI, nunca por hook local. Protocolo: `RESULT <antiga> <nova>` ou `NOOP` no stdout; logs no stderr. Testado em `test/tool/bump_version_test.dart`.

| Gatilho no range | Bump | Seção no CHANGELOG |
|---|---|---|
| `BREAKING CHANGE` no corpo ou `tipo!:` | major | ⚠️ Mudanças importantes |
| `feat:` | minor | ✨ Novidades |
| `fix:` / `perf:` | patch | ⚙️ Correções / ⚡ Melhorias |
| `revert:` ou descrição iniciando em `remov`/`delet`/`exclu` | — | 🗑️ Removido |
| Só `chore`/`docs`/`refactor`/`style`/`test`/`ci`/`build` | `NOOP` | omitido |

- Range analisado: última tag `v*` → `HEAD` (fallback: último `chore(release)` → histórico inteiro); merges ignorados
- Decisão D6: o build number `+B` só sobe junto com bump SemVer — merge de `docs`/`chore` na `main` é `NOOP` e **não** publica nada
- Anti-loop: o push do commit de release redispara o workflow, mas o range só com `chore(release)` cai em `NOOP`

## Secrets e Variáveis

| Nome | Tipo | Uso | Origem |
|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | secret | Keystore de upload em base64 | `~/.keystores/decima/decima-release.jks` (máquina do dev — **fazer backup**) |
| `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_PASSWORD` / `ANDROID_KEY_ALIAS` | secret | Credenciais do keystore | idem |
| `FIREBASE_SERVICE_ACCOUNT` | secret | JSON da service account para o App Distribution | Console Firebase → Configurações → Contas de serviço → Gerar chave privada |
| `RELEASE_DEPLOY_KEY` | secret | Chave SSH privada do bot de release (push do `chore(release)` na `main` protegida) | `ssh-keygen -t ed25519`; pública cadastrada como deploy key com escrita |
| `FIREBASE_ANDROID_APP_ID` | variável | App Android no Firebase (`1:…:android:…`) | Projeto `decima-wevasoft` |

## Firebase App Distribution

| Item | Valor |
|---|---|
| Projeto | `decima-wevasoft` |
| App Android | `com.wevasoft.decima` |
| Grupos de testers | `dev` (builds de push na `dev`) e `stable` (releases da `main`) |
| Mecanismo | `npx firebase-tools@14 appdistribution:distribute` com `GOOGLE_APPLICATION_CREDENTIALS` |

- O app **não** usa SDK Firebase — App Distribution só precisa do APK + App ID + service account; não adicionar `google-services.json` nem plugins Gradle por causa disso

## Segurança e Cibersegurança

| Vetor (OWASP CI/CD) | Mitigação aplicada |
|---|---|
| CICD-SEC-1 (fluxo insuficiente) | `main` só recebe código via PR com 6 checks obrigatórios; force-push e deleção bloqueados nas duas branches |
| CICD-SEC-4 (execução de código de terceiros — PR de fork) | Evento `pull_request` (nunca `pull_request_target`): fork roda sem secrets; distribuição e assinatura só em `push`, que fork não dispara |
| CICD-SEC-5 (permissões excessivas) | `permissions: contents: read` no CI; `write` apenas no release; deploy key restrita a este repositório |
| CICD-SEC-6 (higiene de credenciais) | Keystore/SA/deploy key só em GitHub Secrets (write-only); materializados em `$RUNNER_TEMP`, nunca no workspace versionado; `key.properties` e keystores git-ignorados |
| CICD-SEC-8 (integridade de artefatos) | Instalador Windows e `.deb` Linux publicados com `.sha256`; APK assinado com keystore dedicado |
| Supply chain de actions | Apenas actions oficiais (`actions/*`, `subosito/flutter-action`) e `firebase-tools` pinado no major; sem actions de terceiros para deploy |

- **Nunca** logar conteúdo de secrets nos steps (o GitHub mascara, mas transformações como base64 vazam)
- Rotação: comprometeu um secret → revogar na origem (deploy key/SA/keystore) e regravar o secret

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|---|---|---|
| `/.github/` estava no `.gitignore` | Workflows nunca chegariam ao GitHub | Linha removida na adoção do CI — não recolocar |
| `VersionInfoVersion` do Inno exige versão numérica | `-dev.N` quebraria o ISCC | Build dev do Windows sai como `.zip`; instalador só no release |
| Push com `GITHUB_TOKEN` não redispara workflows | Release via token não validaria/encadearia nada | Push do release usa a deploy key `RELEASE_DEPLOY_KEY` (redispara e cai no `NOOP`) |
| Job pulado por `if:` conta como aprovado nos required checks | `build-windows`/`build-linux` não rodam em PR para `dev` sem bloquear merge | Comportamento intencional — não converter em `paths:` (workflow não reportado bloqueia PR para sempre) |
| Versão Debian não aceita `-dev.N` | `dpkg` rejeitaria o pacote dev com a mesma convenção do zip do Windows | Builds do CI usam `~dev.N`/`~pr.N` — o `~` ainda ordena antes da versão final |
| `sqflite_common_ffi` abre `libsqlite3.so` | Testes quebram em runner Linux puro | Job `test` instala `libsqlite3-dev` via apt |
| `MIN_COVERAGE` (85%) vs. baseline 88,4% | Gate reprova se a cobertura cair | Ajustar o valor apenas conscientemente, nunca para "passar" |
| Sem secrets, release build assina com chave de debug | APK de fork/clone não serve para distribuição | Fallback intencional para manter forks buildáveis |
| `versionCode` do CI = minutos da epoch; o `+B` do pubspec é só contador de releases | APK buildado **localmente** usa o `+B` (pequeno) — instalar por cima de um APK do CI é downgrade bloqueado | Para testar local sobre build do CI: `flutter build apk --release --build-number=$(( $(date +%s) / 60 ))` |
| Duas sequências de build number (run_number × pubspec) causavam downgrade dev→stable | Tester precisava desinstalar (perdendo dados) ao trocar de canal | Corrigido com a fonte única por timestamp — não reintroduzir `run_number` como versionCode |
| `path_provider_android` pinado `<2.3.0` | `flutter pub upgrade` cego quebra o build (jni/AGP) | Manter o pin — ver `plano/changelog.md` da migração Kotlin |
| Versão do Flutter no CI vem do `.fvmrc` | Divergência local×CI se atualizar só um lado | Atualizar `.fvmrc` e testar localmente com o mesmo FVM |
| Commit do release é do bot (`github-actions[bot]`) | `git pull` necessário na `dev` após release para receber `chore(release)` | Após merge na `main`: `git checkout dev && git merge main` (ou rebase) |
| Branch padrão é a `main`, mas o trabalho é na `dev` | Clone novo cai na `main`; PR aberto pela UI/`gh` já vem com `base: main` | `git switch dev` após clonar; conferir a base ao abrir PR de feature (`gh pr create --base dev`) |
| Badge de CI aponta para `?branch=dev` | `ci.yml` não roda em push na `main` — badge apontando para `main` ficaria "no status" | Manter o `?branch=dev` no `README.md` mesmo com a `main` como default |
