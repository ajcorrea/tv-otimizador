# Changelog

Versões seguem [SemVer](https://semver.org/lang/pt-BR/) (`MAJOR.MINOR.PATCH`). Cada compilação também tem um número de build `AAAAMMDD.N`, exibido na splash, no título e em Configurações > Sobre.

## [1.4.1] - 2026-10-22
- Correção: falha "O nome do diretório é inválido" ao instalar o Android SDK (sdkmanager agora roda com pasta de trabalho válida e sem pipe do cmd; licenças gravadas antes). Mensagens do cmd sem acentos quebrados e saída completa de cada etapa na aba Log.

## [1.4.0] - 2026-10-22
- Nova aba **Free My TV** para instalar a tela inicial leve e sem anúncios do projeto [Free My TV](https://freemytv.io/pt/) (simbasjungles):
  - **Android TV / Google TV:** baixa o código mais recente, compila com as suas opções (chave TMDB, cidade com busca automática de coordenadas, país, idioma, temperatura, moeda, serviços a esconder, Assistente, animações) usando o próprio `build.sh` do projeto, instala pelo ADB, libera a execução em segundo plano nas TVs TCL e abre o app. Botões para abrir e desinstalar (com o passo de voltar ao modo *Original*).
  - **Ferramentas de compilação** (JDK 17, Android SDK com build-tools/platform 34 e Git Bash) baixadas e instaladas pelo app, das fontes oficiais, na pasta escolhida; Git for Windows e SDKs já instalados são reaproveitados. A chave de assinatura fica em `%APPDATA%\TV-Otimizador\freemytv` para as atualizações.
  - **TV LG (webOS):** instala e remove o [FreeMyTvWebOS](https://github.com/danielthejoker18/FreeMyTvWebOS) pelo Developer Mode da LG, usando o OpenSSH do Windows (sem Python e sem root).
  - **Samsung (Tizen):** instruções e link para o TizenBrew Installer.
- A aba Tela inicial reconhece o Free My TV e indica que ele gerencia a própria tela inicial; ao instalar, o launcher do Google é reativado se o TV Otimizador o tiver desativado.
- Configurações mostra as ferramentas de compilação e o Cliente OpenSSH do Windows.

## [1.3.1] - 2026-10-22
- Botão **Reiniciar TV** no cabeçalho e na janela Tela da TV: reinicia a TV, aguarda o boot e reconecta sozinho.

## [1.3.0] - 2026-10-22
- Splash screen, logo vetorial e ícone do app.
- Nova aba **Configurações**: detecta o ADB e o scrcpy e oferece **Baixar e instalar** (escolhendo a pasta), **Localizar...** e **Abrir pasta**.
- Caminhos das ferramentas, IP e porta da TV salvos em `%APPDATA%\TV-Otimizador\config.json`; histórico movido para `historico.json` na mesma pasta (o antigo é migrado).
- **Tela da TV** agora abre em uma janela separada e redimensionável, com controle remoto e atualização automática.
- Correção: textos pretos (ilegíveis) na aba Tela inicial.
- Créditos, versão e build no cabeçalho e em Configurações > Sobre.
- Versionamento (`VERSION`, `tools/bump-version.ps1`) e CI com validação de sintaxe/XAML e Release automática quando a versão muda.

## [1.2.0] - 2026-10-22
- Aba **Tela inicial**: troca do launcher do Google por Projectivy, FLauncher ou ATV Launcher (com instalação pela Play Store da TV) e volta ao launcher do Google.
- Visualização da tela da TV por captura, com controle remoto (botões e teclado), envio de texto e atalho para o scrcpy.

## [1.1.0] - 2026-10-22
- Itens já aplicados aparecem esmaecidos com ✓ e botão **Restaurar**.
- Detecção de launchers alternativos.

## [1.0.0] - 2026-10-22
- Interface gráfica (WPF): conexão ADB pela rede, nota de saúde, cartões de métricas (RAM, zram, reclaim direto, carga, CPU, armazenamento, cache, tempo ligada).
- Recomendações com caixas de seleção, aplicar/reverter, histórico das alterações, aba de processos, diagnóstico completo e exportação de relatório.
