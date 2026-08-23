# Empacotamento — macOS

> Build do `.app` do Decima para macOS com assinatura ad-hoc; assinatura Developer ID e notarização documentadas apenas como referência (exigem conta paga do Apple Developer Program — fora do escopo atual).

## Artefatos

| Arquivo | Papel |
|---------|-------|
| `build/macos/Build/Products/Release/Decima.app` | Bundle gerado por `fvm flutter build macos --release` (**não versionado**) |
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = decima`, `PRODUCT_BUNDLE_IDENTIFIER = com.wevasoft.decima` |
| `macos/Runner/DebugProfile.entitlements` | Sandbox + `allow-jit` + `network.server` (Debug/Profile — hot reload e VM Service) |
| `macos/Runner/Release.entitlements` | Apenas `com.apple.security.app-sandbox` |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | PNGs 16–1024 px gerados pelo `flutter_launcher_icons` a partir de `assets/icon/decima_icon_macos.png` (master squircle 824 px centrado em canvas 1024 transparente — `tool/icon/render.mjs`); o Xcode compila o `.icns` no bundle |
| `macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` | Integração Swift Package Manager dos plugins (`window_manager`, `screen_retriever`, `sqflite`, `shared_preferences`, `path_provider`) — gerada no build (**não versionada**) |

## Build

| Comando | Efeito |
|---------|--------|
| `fvm flutter build macos --release` | `.app` release com assinatura ad-hoc (`CODE_SIGN_IDENTITY = "-"`, default do template) |
| `ditto build/macos/Build/Products/Release/Decima.app /Applications/Decima.app` | Instalação local — Launchpad/Spotlight passam a enxergar o app; `lsregister -f /Applications/Decima.app` força o índice na hora |
| `ditto -c -k --keepParent Decima.app decima-<versão>-macos.zip` | Zip preservando metadados/resource forks — formato de distribuição sem conta paga |
| `hdiutil create -volname Decima -srcfolder Decima.app -ov -format UDZO decima.dmg` | `.dmg` simples (alternativa ao zip) |

| Parâmetro | Valor |
|-----------|-------|
| `MACOSX_DEPLOYMENT_TARGET` | `10.15` (Catalina) |
| Assinatura | Ad-hoc (`-`) — válida localmente, sem cadeia de confiança |
| Sandbox | Ativo; dados em `~/Library/Containers/com.wevasoft.decima/` |
| Arquitetura | `arm64` + `x86_64` (universal, default do Flutter) |

## Distribuição com assinatura ad-hoc (caminho atual)

O `.app` ad-hoc roda sem atrito na máquina que o compilou. Baixado da internet, recebe o atributo de quarentena e o Gatekeeper bloqueia com "não pôde ser verificado":

| Passo do usuário | Ação |
|------------------|------|
| 1. Tentar abrir | Diálogo de bloqueio — fechar com "Concluído" (não "Mover para o Lixo") |
| 2. Autorizar | Ajustes do Sistema → Privacidade e Segurança → "Abrir Mesmo Assim" |
| Alternativa via terminal | `xattr -d com.apple.quarantine Decima.app` remove a quarentena |

## Assinatura e notarização (referência — não implementado)

Fluxo para distribuição sem atrito, quando houver conta do Apple Developer Program (US$ 99/ano):

| Passo | Comando/Ação |
|-------|--------------|
| 1. Certificado | Gerar "Developer ID Application" no portal do desenvolvedor e instalar no Keychain |
| 2. Assinar | `codesign --deep --force --options runtime --sign "Developer ID Application: <nome> (<team>)" Decima.app` — hardened runtime é pré-requisito da notarização |
| 3. Empacotar | `ditto -c -k --keepParent Decima.app decima.zip` |
| 4. Notarizar | `xcrun notarytool submit decima.zip --keychain-profile <perfil> --wait` |
| 5. Grampear | `xcrun stapler staple Decima.app` — o veredito passa a valer offline |
| 6. Redistribuir | Recompactar o `.app` grampeado; Gatekeeper abre sem diálogos |

## Segurança e Cibersegurança

| Vetor | Risco | Mitigação adotada |
|-------|-------|-------------------|
| Binário sem cadeia de confiança | Gatekeeper bloqueia e usuário é treinado a contornar avisos (OWASP A08 — falha de integridade) | Distribuir apenas via GitHub Releases com SHA-256 publicado; documentar o desbloqueio oficial (Ajustes → Privacidade e Segurança), não o `xattr` indiscriminado |
| Adulteração do artefato em trânsito | `.app`/`.zip` substituído em download não-oficial | Divulgar o hash junto do release; assinatura ad-hoc ainda garante integridade por página (qualquer byte alterado invalida a execução em Apple Silicon) |
| Escalonamento de privilégio (OWASP A01) | App com acesso amplo ao sistema de arquivos | App Sandbox ativo no Release com **zero** entitlements além do sandbox — menor privilégio |
| Entitlements de debug em produção | `allow-jit`/`network.server` abririam superfície de rede | Separados em `DebugProfile.entitlements`; o Release usa arquivo próprio e mínimo |
| Vazamento de dados na remoção | Histórico permanece após apagar o app | Comportamento intencional; remoção manual em `~/Library/Containers/com.wevasoft.decima/` |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| SDK global ≠ SDK do projeto | `flutter pub get`/`build` com o Flutter global rebaixa o `pubspec.lock` (aconteceu com 3.41.7 vs 3.44.2 do FVM) | Sempre `fvm flutter ...` neste repositório |
| Semáforo nativo permanece com `TitleBarStyle.hidden` | Diferente de Windows/Linux, o macOS mantém close/minimize/zoom sobrepostos ao conteúdo | `AppTitleBar` no macOS não renderiza botões customizados; logo + nome centralizados (`PlatformInfo.isMacOS`) |
| `setMaximizable(false)` no macOS não desabilita o botão verde | Só veta o zoom no delegate (`windowShouldZoom`) | O visual vem do `setResizable(false)` — sem `.resizable` no `styleMask` o zoom fica cinza, convenção de janela fixa |
| Janela pisca no tamanho do template no launch | O runner mostra a janela antes de o Dart aplicar `WindowOptions` | `hiddenWindowAtLaunch()` no `order(_:relativeTo:)` do `MainFlutterWindow` (setup documentado do `window_manager`) |
| `windowButtonVisibility: false` esconderia o semáforo inteiro | Não existe API por botão no `window_manager` | Manter o default `true` no `WindowOptions` |
| Primeiro build adiciona CocoaPods **e** SwiftPM ao projeto | `Podfile`, `Podfile.lock`, includes `Pods-Runner` nos `Flutter-*.xcconfig` e ref no workspace — integração dupla, build mais lento e aviso a cada build | CocoaPods removido (`pod deintegrate` + apagar `Podfile` + reverter xcconfigs/workspace): todos os plugins macOS são Swift Packages e o próprio Flutter recomenda a remoção |
| `.icns` não existe como arquivo no repo | Procurar `app_icon.icns` não encontra nada | O Xcode compila o `AppIcon.appiconset` em `AppIcon.icns` dentro do bundle (`Contents/Resources/`) |
| Ícone full-bleed sai quadrado no Dock | Como Windows/Linux, o macOS **não** aplica máscara — e sem as margens do grid da Apple o ícone ainda fica maior que os vizinhos | `macos.image_path` usa `decima_icon_macos.png`: master squircle a 824 px centrado em canvas 1024 transparente (`tool/icon/render.mjs`) |
| APFS é case-insensitive | `decima.app` e `Decima.app` são a **mesma** entrada de diretório — um `rm` no nome antigo apaga o bundle novo | Após renomear `PRODUCT_NAME`, não "limpar" o nome antigo em `build/` |
| Sandbox muda o caminho dos dados | Banco/preferências não ficam em `~/Library/Application Support/<app>` direto | Ficam no container `~/Library/Containers/com.wevasoft.decima/Data/Library/...` — considerar em backup/debug |
