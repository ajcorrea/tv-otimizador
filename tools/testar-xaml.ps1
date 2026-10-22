<#
  Valida, no Windows, todos os XAML embutidos no TV-Otimizador.ps1 instanciando-os com o WPF
  (sem abrir janelas). Usado pelo CI; também pode ser rodado localmente:
    powershell -NoProfile -STA -File .\tools\testar-xaml.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$arq = Join-Path (Split-Path $PSScriptRoot -Parent) 'TV-Otimizador.ps1'
$s = [IO.File]::ReadAllText($arq)
$estilos = [regex]::Match($s, "(?s)EstilosXaml = @'\r?\n(.*?)\r?\n'@").Groups[1].Value
if (-not $estilos) { throw 'Bloco de estilos não encontrado.' }
$falhas = 0; $n = 0
foreach ($m in [regex]::Matches($s, "(?s)(\$[\w:]+) = @'\r?\n(.*?)\r?\n'@")) {
    $nome = $m.Groups[1].Value; $x = $m.Groups[2].Value
    if ($x -notmatch '^\s*<(Window|Viewbox)') { continue }
    $x = $x.Replace('__ESTILOS__', $estilos).Replace('__TITULO__', 'teste')
    try { [void][Windows.Markup.XamlReader]::Parse($x); $n++; Write-Host "OK    $nome" -ForegroundColor Green }
    catch { $falhas++; Write-Host "FALHA $nome : $($_.Exception.InnerException.Message) $($_.Exception.Message)" -ForegroundColor Red }
}
foreach ($m in [regex]::Matches($s, "(?s)\[xml\](\$\w+) = @'\r?\n(.*?)\r?\n'@")) {
    try { [void][Windows.Markup.XamlReader]::Parse($m.Groups[2].Value); $n++; Write-Host "OK    $($m.Groups[1].Value)" -ForegroundColor Green }
    catch { $falhas++; Write-Host "FALHA $($m.Groups[1].Value) : $($_.Exception.Message)" -ForegroundColor Red }
}
Write-Host "$n XAML validados, $falhas falha(s)."
if ($falhas -or $n -lt 4) { exit 1 }
