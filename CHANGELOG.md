# Changelog

Versões seguem [SemVer](https://semver.org/lang/pt-BR/) (`MAJOR.MINOR.PATCH`). Cada compilação também tem um número de build `AAAAMMDD.N`, exibido na splash, no título e em Configurações > Sobre.

## [1.3.0] - 2026-10-22
- Splash screen, logo vetorial e ícone do app.
- Nova aba **Configurações**: detecta o ADB e o scrcpy e oferece **Baixar e instalar** (escolhendo a pasta), **Localizar...** e **Abrir pasta**.
- Caminhos das ferramentas, IP e porta da TV salvos em `%APPDATA%\TV-Otimizador\config.json`; histórico movido para `historico.json` na mesma pasta (o antigo é migrado).
- **Tela da TV** agora abre em uma janela separada e redimensionável, com controle remoto e atualização automática.
- Correção: textos pretos (ilegíveis) na aba Tela inicial.
- Créditos, versão e build no cabeçalho e em Configurações > Sobre.
- Versionamento (`VERSION`, `tools/bump-version.ps1`) e CI com validação de sintaxe/XAML e Release automática por tag.

## [1.2.0] - 2026-10-22
- Aba **Tela inicial**: troca do launcher do Google por Projectivy, FLauncher ou ATV Launcher (com instalação pela Play Store da TV) e volta ao launcher do Google.
- Visualização da tela da TV por captura, com controle remoto (botões e teclado), envio de texto e atalho para o scrcpy.

## [1.1.0] - 2026-10-22
- Itens já aplicados aparecem esmaecidos com ✓ e botão **Restaurar**.
- Detecção de launchers alternativos.

## [1.0.0] - 2026-10-22
- Interface gráfica (WPF): conexão ADB pela rede, nota de saúde, cartões de métricas (RAM, zram, reclaim direto, carga, CPU, armazenamento, cache, tempo ligada).
- Recomendações com caixas de seleção, aplicar/reverter, histórico das alterações, aba de processos, diagnóstico completo e exportação de relatório.
