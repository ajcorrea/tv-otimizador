<#
  Atualiza a versão do TV Otimizador.

  Versão (SemVer):  MAJOR.MINOR.PATCH  — arquivo VERSION e $script:AppVersion no script
  Build:            AAAAMMDD.N          — $script:AppBuild (N reinicia a cada dia)

  Exemplos:
    .\tools\bump-version.ps1                       # só incrementa o build
    .\tools\bump-version.ps1 -Parte patch -Nota "Corrige captura da tela"
    .\tools\bump-version.ps1 -Parte minor -Nota "Nova aba de rede"
    .\tools\bump-version.ps1 -Parte major

  Depois de um bump de versão:  git commit -am "v1.4.0" ; git push
  (o CI cria a tag v1.4.0 e a Release com o .zip quando a versão ainda não foi publicada)
#>
param(
    [ValidateSet('build', 'patch', 'minor', 'major')]
    [string]$Parte = 'build',
    [string]$Nota = ''
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$arqScript = Join-Path $raiz 'TV-Otimizador.ps1'
$arqVersao = Join-Path $raiz 'VERSION'
$arqLog = Join-Path $raiz 'CHANGELOG.md'
$utf8Bom = New-Object System.Text.UTF8Encoding $true

$v = [version](Get-Content $arqVersao -Raw).Trim()
switch ($Parte) {
    'major' { $nova = [version]::new($v.Major + 1, 0, 0) }
    'minor' { $nova = [version]::new($v.Major, $v.Minor + 1, 0) }
    'patch' { $nova = [version]::new($v.Major, $v.Minor, $v.Build + 1) }
    default { $nova = $v }
}

$txt = [IO.File]::ReadAllText($arqScript)
$hoje = Get-Date -Format 'yyyyMMdd'
$m = [regex]::Match($txt, "AppBuild\s*=\s*'(\d{8})\.(\d+)'")
$n = if ($m.Success -and $m.Groups[1].Value -eq $hoje) { [int]$m.Groups[2].Value + 1 } else { 1 }
$build = "$hoje.$n"

$txt = [regex]::Replace($txt, "(\`$script:AppVersion\s*=\s*)'[^']*'", "`${1}'$nova'")
$txt = [regex]::Replace($txt, "(\`$script:AppBuild\s*=\s*)'[^']*'", "`${1}'$build'")
[IO.File]::WriteAllText($arqScript, $txt, $utf8Bom)
[IO.File]::WriteAllText($arqVersao, "$nova")

if ($nova -ne $v) {
    $log = if (Test-Path $arqLog) { [IO.File]::ReadAllText($arqLog) } else { "# Changelog`r`n" }
    $item = if ($Nota) { "- $Nota" } else { '- (descreva as mudanças)' }
    $secao = "## [$nova] - $(Get-Date -Format 'yyyy-MM-dd')`r`n$item`r`n`r`n"
    $i = $log.IndexOf('## [')
    $log = if ($i -ge 0) { $log.Insert($i, $secao) } else { $log + "`r`n" + $secao }
    [IO.File]::WriteAllText($arqLog, $log, $utf8Bom)
}

Write-Host "Versão: $v -> $nova   Build: $build" -ForegroundColor Green
if ($nova -ne $v) { Write-Host "Próximo passo: git commit -am `"v$nova`"; git push   (o CI publica a Release v$nova)" }
