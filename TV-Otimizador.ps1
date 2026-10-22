<#
  TV Otimizador — análise e otimização de Android TV via ADB pela rede
  Interface gráfica WPF. Tudo é reversível: pacotes são só desativados (disable-user), nunca desinstalados.

  Autor:   Alexandre Jeronimo Correa <ajcorrea@gmail.com> — github.com/ajcorrea
  Projeto: https://github.com/ajcorrea/tv-otimizador
  Licença: MIT

  Uso: TV-Otimizador.cmd (duplo clique)
       ou: powershell -ExecutionPolicy Bypass -STA -File .\TV-Otimizador.ps1
  ADB e scrcpy podem ser baixados e instalados pela aba Configurações.
#>

# ---------------------------------------------------------------- versão (atualizada por tools/bump-version.ps1)
$script:AppNome    = 'TV Otimizador'
$script:AppVersion = '1.3.0'
$script:AppBuild   = '20261022.5'
$script:AppAutor   = 'Alexandre Jeronimo Correa'
$script:AppEmail   = 'ajcorrea@gmail.com'
$script:AppGitHub  = 'https://github.com/ajcorrea'
$script:AppRepo    = 'https://github.com/ajcorrea/tv-otimizador'

# ---------------------------------------------------------------- STA / assemblies
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`""
    exit
}
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

function DoEvents {
    $f = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [Action]{ $f.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($f)
}

# ---------------------------------------------------------------- logo (vetorial)
$script:LogoXaml = @'
<Viewbox xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Stretch="Uniform">
  <Canvas Width="100" Height="100">
    <Ellipse Canvas.Left="4" Canvas.Top="6" Width="92" Height="82" Opacity="0.35">
      <Ellipse.Fill>
        <RadialGradientBrush><GradientStop Color="#5B8DEF" Offset="0"/><GradientStop Color="#005B8DEF" Offset="1"/></RadialGradientBrush>
      </Ellipse.Fill>
    </Ellipse>
    <Rectangle Canvas.Left="6" Canvas.Top="14" Width="88" Height="60" RadiusX="12" RadiusY="12">
      <Rectangle.Fill>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#2F6FED" Offset="0"/><GradientStop Color="#8E5CF7" Offset="1"/></LinearGradientBrush>
      </Rectangle.Fill>
    </Rectangle>
    <Rectangle Canvas.Left="11.5" Canvas.Top="19.5" Width="77" Height="49" RadiusX="7" RadiusY="7" Fill="#0F131A"/>
    <Path Stroke="#263042" StrokeThickness="6" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Data="M 34.4,61 A 18,18 0 1 1 65.6,61"/>
    <Path StrokeThickness="6" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Data="M 34.4,61 A 18,18 0 0 1 59,36.4">
      <Path.Stroke>
        <LinearGradientBrush StartPoint="0,1" EndPoint="1,0"><GradientStop Color="#FFB020" Offset="0"/><GradientStop Color="#3DDC84" Offset="1"/></LinearGradientBrush>
      </Path.Stroke>
    </Path>
    <Line X1="50" Y1="52" X2="58" Y2="39" Stroke="#FFFFFF" StrokeThickness="3" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
    <Ellipse Canvas.Left="46" Canvas.Top="48" Width="8" Height="8" Fill="#FFFFFF"/>
    <Rectangle Canvas.Left="44" Canvas.Top="74" Width="12" Height="7" Fill="#3A465B"/>
    <Rectangle Canvas.Left="30" Canvas.Top="81" Width="40" Height="5" RadiusX="2.5" RadiusY="2.5" Fill="#4A5670"/>
  </Canvas>
</Viewbox>
'@
function New-Logo([double]$tam) {
    $v = [Windows.Markup.XamlReader]::Parse($script:LogoXaml)
    $v.Width = $tam; $v.Height = $tam
    return $v
}
function Get-LogoIcon([int]$px = 64) {
    $v = New-Logo $px
    $sz = New-Object System.Windows.Size($px, $px)
    $v.Measure($sz); $v.Arrange((New-Object System.Windows.Rect($sz))); $v.UpdateLayout()
    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($px, $px, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb.Render($v); $rtb.Freeze()
    return $rtb
}

# ---------------------------------------------------------------- splash
[xml]$splashXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TV Otimizador" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" Topmost="True" Width="580" Height="370" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
  <Border CornerRadius="20" Margin="18" BorderBrush="#2A3445" BorderThickness="1">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#18202D" Offset="0"/><GradientStop Color="#0C1016" Offset="1"/></LinearGradientBrush>
    </Border.Background>
    <Border.Effect><DropShadowEffect BlurRadius="26" ShadowDepth="0" Opacity="0.65" Color="#000000"/></Border.Effect>
    <Grid Margin="30,24">
      <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
        <ContentControl x:Name="splashLogo" Width="124" Height="124"/>
        <StackPanel Margin="22,0,0,0" VerticalAlignment="Center">
          <TextBlock Text="TV Otimizador" FontSize="36" FontWeight="Bold" Foreground="#FFFFFF"/>
          <TextBlock Text="Análise e otimização de Android TV via ADB" Foreground="#AEB6C6" FontSize="14" Margin="0,2,0,0"/>
          <TextBlock x:Name="splashVersao" Foreground="#5B8DEF" FontSize="12" Margin="0,12,0,0"/>
        </StackPanel>
      </StackPanel>
      <StackPanel Grid.Row="1">
        <ProgressBar IsIndeterminate="True" Height="3" Background="#1B2230" Foreground="#2F6FED" BorderThickness="0"/>
        <DockPanel Margin="0,8,0,0">
          <TextBlock x:Name="splashCred" DockPanel.Dock="Right" Foreground="#6B7385" FontSize="11"/>
          <TextBlock x:Name="splashStatus" Text="Iniciando..." Foreground="#8A93A6" FontSize="11"/>
        </DockPanel>
      </StackPanel>
    </Grid>
  </Border>
</Window>
'@
$script:Splash = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $splashXaml))
$script:SplashSw = [Diagnostics.Stopwatch]::StartNew()
$script:Splash.FindName('splashLogo').Content = New-Logo 124
$script:Splash.FindName('splashVersao').Text = "Versão $($script:AppVersion)  ·  build $($script:AppBuild)"
$script:Splash.FindName('splashCred').Text = "© $(Get-Date -Format yyyy) $($script:AppAutor)  ·  github.com/ajcorrea"
try { $script:LogoIcon = Get-LogoIcon 64; $script:Splash.Icon = $script:LogoIcon } catch {}
$script:Splash.Show()
DoEvents
function Set-Splash([string]$t) { if ($script:Splash) { $script:Splash.FindName('splashStatus').Text = $t; DoEvents } }
Set-Splash 'Carregando componentes...'

if (-not ('TvItemV2' -as [type])) {
Add-Type -TypeDefinition @"
using System.ComponentModel;
public class TvItemV2 : INotifyPropertyChanged {
    public event PropertyChangedEventHandler PropertyChanged;
    void N(string p) { if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(p)); }
    bool _sel;
    public bool Selecionado { get { return _sel; } set { if (_sel != value) { _sel = value; N("Selecionado"); N("Acao"); } } }
    public bool Editavel { get; set; }
    public bool Avancado { get; set; }
    public bool OneShot { get; set; }
    public bool Sugerido { get; set; }
    bool _apl;
    public bool AplicadoAgora { get { return _apl; } set { if (_apl != value) { _apl = value; N("AplicadoAgora"); N("JaAplicado"); N("MostraCheck"); N("Acao"); } } }
    public bool JaAplicado { get { return _apl && Editavel && !OneShot; } }
    public bool MostraCheck { get { return !JaAplicado; } }
    public int CatOrdem { get; set; }
    public string Tipo { get; set; }
    public string Id { get; set; }
    public string Nome { get; set; }
    public string Categoria { get; set; }
    public string Descricao { get; set; }
    public string Risco { get; set; }
    string _est;
    public string Estado { get { return _est; } set { _est = value; N("Estado"); } }
    public string Ram { get; set; }
    public string Cache { get; set; }
    public string SugestaoTexto { get { return Sugerido ? "\u2605 Sugerido" : ""; } }
    public string Acao { get {
        if (!Editavel) return Tipo == "pkg" ? "Protegido" : "Indispon\u00edvel";
        if (OneShot) return _sel ? "Executar" : "";
        if (_sel && !AplicadoAgora) return Tipo == "pkg" ? "Desativar" : "Aplicar";
        if (!_sel && AplicadoAgora) return Tipo == "pkg" ? "Reativar" : "Desfazer";
        return "";
    } }
}
"@
}

# ---------------------------------------------------------------- catálogo de pacotes
# R = risco | S = sugerir desativar | X = protegido (nunca mexer)
$script:Catalogo = @(
  # --- TCL
  @{P='com.tcl.waterfall.overseas'; C='TCL'; N='TCL Channel (vitrine TCL)'; R='Baixo'; S=$true;  D='Vitrine de conteúdo e recomendações da TCL na home. Costuma acumular centenas de MB de cache.'}
  @{P='com.tcl.channelplus';        C='TCL'; N='TCL Channel+';              R='Baixo'; S=$true;  D='Canais gratuitos com anúncios (FAST) da TCL.'}
  @{P='com.tcl.esticker';           C='TCL'; N='Selos promocionais';        R='Baixo'; S=$true;  D='Adesivos/selos de vitrine de loja.'}
  @{P='com.tcl.hotelmenu';          C='TCL'; N='Modo hotel';                R='Baixo'; S=$true;  D='Menu do modo hotel (uso comercial).'}
  @{P='com.tcl.t_solo';             C='TCL'; N='T-Solo (conteúdo TCL)';     R='Baixo'; S=$true;  D='Serviço de conteúdo/recomendações da TCL. Sem documentação pública.'}
  @{P='com.tcl.notereminder';       C='TCL'; N='Lembretes TCL';             R='Baixo'; S=$true;  D='Lembretes de programação da TCL.'}
  @{P='com.tcl.usercenter';         C='TCL'; N='Conta TCL';                 R='Baixo'; S=$true;  D='Login/perfil na nuvem da TCL. Só é útil se você usa conta TCL.'}
  @{P='com.tcl.messagebox';         C='TCL'; N='Mensagens TCL';             R='Baixo'; S=$true;  D='Caixa de avisos e promoções da TCL.'}
  @{P='com.tcl.assistant';          C='TCL'; N='Assistente TCL';            R='Baixo'; S=$true;  D='Assistente/atalhos de voz próprios da TCL.'}
  @{P='com.tcl.micmanager';         C='TCL'; N='Microfone embutido da TV';  R='Médio'; S=$true;  D='Gerencia o microfone far-field da TV (escuta sem o controle). Desativar corta essa escuta.'}
  @{P='com.tcl.smartalexa';         C='TCL'; N='Alexa embutida';            R='Baixo'; S=$true;  D='Integração com a Alexa.'}
  @{P='com.tcl.MultiScreenInteraction_TV'; C='TCL'; N='T-Cast';             R='Baixo'; S=$false; D='Enviar mídia/espelhar pelo app TCL no celular. O Chromecast continua funcionando.'}
  @{P='com.tcl.miracast';           C='TCL'; N='Miracast';                  R='Baixo'; S=$false; D='Espelhamento de tela Miracast (notebooks Windows, alguns Android).'}
  @{P='com.tcl.gallery';            C='TCL'; N='Galeria TCL';               R='Baixo'; S=$false; D='Galeria de fotos/vídeos de pendrive. O Media Center continua.'}
  @{P='com.tcl.ui_mediaCenter';     C='TCL'; N='Media Center (USB)';        R='Baixo'; S=$false; D='Reprodutor de mídia de pendrive/HD externo.'}
  @{P='com.tcl.ttvs';               C='TCL'; N='TTVS (serviço TCL)';        R='Médio'; S=$false; D='Serviço residente da TCL, sem documentação pública. Teste: desative, use um dia, reverta se algo parar.'}
  @{P='com.tcl.ttvs.core';          C='TCL'; N='TTVS core';                 R='Médio'; S=$false; D='Parte do TTVS (ver acima).'}
  @{P='com.tcl.ttvs.container';     C='TCL'; N='TTVS container';            R='Médio'; S=$false; D='Parte do TTVS (ver acima).'}
  @{P='com.tcl.guard';              C='TCL'; N='TCL Guard';                 R='Alto';  S=$false; D='Serviço de proteção/limpeza da TCL. Gera picos de CPU, mas pode estar ligado a outras funções do sistema.'}
  @{P='com.tcl.partnercustomizer';  C='TCL'; N='Partner Customizer';        R='Alto';  S=$false; D='Aplica as personalizações da TCL no launcher do Google. Pode alterar a home.'}
  # --- Google
  @{P='com.google.android.katniss';  C='Google'; N='Google Assistente / "Ok Google"'; R='Médio'; S=$true; D='Escuta "Ok Google", busca por voz e Assistente. Desativar libera ~30 MB; o botão de microfone do controle deixa de funcionar.'}
  @{P='com.google.android.videos';   C='Google'; N='Google Play Filmes';     R='Baixo'; S=$true;  D='Serviço descontinuado.'}
  @{P='com.google.android.play.games'; C='Google'; N='Play Games';          R='Baixo'; S=$true;  D='Perfil de jogos do Google.'}
  @{P='com.google.android.feedback'; C='Google'; N='Feedback do Google';     R='Baixo'; S=$true;  D='Envio de relatórios de feedback.'}
  @{P='android.autoinstalls.config.google.gtvpai'; C='Google'; N='Instalação automática de apps'; R='Baixo'; S=$true; D='Play Auto Installs: instala apps de parceiros automaticamente.'}
  @{P='com.google.android.syncadapters.calendar'; C='Google'; N='Sincronização da Agenda'; R='Baixo'; S=$true; D='Sincroniza a Google Agenda na TV (sem uso prático).'}
  @{P='com.google.android.youtube.tvmusic'; C='Google'; N='YouTube Music';  R='Baixo'; S=$false; D='Desative se não usa.'}
  @{P='com.google.android.marvin.talkback'; C='Google'; N='TalkBack';       R='Baixo'; S=$false; D='Leitor de tela (acessibilidade).'}
  @{P='com.google.android.apps.tv.dreamx'; C='Google'; N='Protetor de tela Ambient'; R='Médio'; S=$false; D='Protetor de tela com fotos/informações do Google.'}
  @{P='com.google.android.apps.mediashell'; C='Google'; N='Chromecast integrado'; R='Médio'; S=$false; D='Receptor do Chromecast. Desative só se nunca transmite do celular.'}
  @{P='com.google.android.apps.nbu.smartconnect.tv'; C='Google'; N='Smart Connect'; R='Médio'; S=$false; D='Conexão do celular com a TV (Google). Função exata não documentada.'}
  @{P='com.google.android.tts';      C='Google'; N='Síntese de voz';         R='Médio'; S=$false; D='Voz do Google para leitura de tela e Assistente.'}
  # --- Sistema Android
  @{P='com.android.printspooler';    C='Sistema Android'; N='Impressão';     R='Baixo'; S=$true; D='Serviço de impressão.'}
  @{P='com.android.wallpaper.livepicker'; C='Sistema Android'; N='Papel de parede animado'; R='Baixo'; S=$true; D='Seletor de papel de parede animado.'}
  @{P='com.android.dynsystem';       C='Sistema Android'; N='Sistema dinâmico (GSI)'; R='Baixo'; S=$true; D='Instalação de imagens de sistema de teste.'}
  @{P='com.android.deskclock';       C='Sistema Android'; N='Relógio';       R='Baixo'; S=$false; D='Relógio/alarmes do Android.'}
  # --- Streaming
  @{P='com.netflix.ninja';           C='Apps de streaming'; N='Netflix';     R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='com.amazon.amazonvideo.livingroom'; C='Apps de streaming'; N='Prime Video'; R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='com.disney.disneyplus';       C='Apps de streaming'; N='Disney+';     R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='com.disney.starplus';         C='Apps de streaming'; N='Star+';       R='Baixo'; S=$true;  D='O Star+ foi incorporado ao Disney+; o app ficou obsoleto.'}
  @{P='com.hbo.hbonow';              C='Apps de streaming'; N='HBO Max (app antigo)'; R='Baixo'; S=$true; D='App antigo, substituído pelo app atual da HBO Max (com.wbd.stream).'}
  @{P='com.wbd.stream';              C='Apps de streaming'; N='HBO Max';     R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='com.globo.globotv';           C='Apps de streaming'; N='Globoplay';   R='Baixo'; S=$false; D='Desative só se não usa. Costuma acumular muito cache.'}
  @{P='com.google.android.youtube.tv'; C='Apps de streaming'; N='YouTube';   R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='com.apple.atve.androidtv.appletv'; C='Apps de streaming'; N='Apple TV'; R='Baixo'; S=$false; D='Desative só se não usa.'}
  @{P='au.com.stan.and';             C='Apps de streaming'; N='Stan (Austrália)'; R='Baixo'; S=$true; D='Serviço australiano, indisponível no Brasil.'}
  @{P='tv.wuaki.apptv';              C='Apps de streaming'; N='Rakuten TV';  R='Baixo'; S=$true;  D='Serviço sem catálogo no Brasil.'}
  @{P='com.tvwebbrowser.v22';        C='Apps de streaming'; N='Navegador TV'; R='Baixo'; S=$false; D='Navegador web.'}
  # --- Protegidos (aparecem só com "mostrar todos")
  @{P='com.tcl.tv';         X=$true; N='TV / sintonizador / entradas'}
  @{P='com.tcl.tvinput';    X=$true; N='Entradas de TV TCL'}
  @{P='com.tcl.settings';   X=$true; N='Configurações TCL'}
  @{P='com.tcl.system.server'; X=$true; N='Serviços de sistema TCL'}
  @{P='com.tcl.autopair';   X=$true; N='Pareamento do controle'}
  @{P='com.tcl.initsetup';  X=$true; N='Configuração inicial'}
  @{P='com.tcl.dashboard';  X=$true; N='Painel rápido TCL'}
  @{P='com.tcl.tv.tclhome_passive'; X=$true; N='Home TCL (passivo)'}
  @{P='com.tcl.providers.config'; X=$true; N='Configuração TCL'}
  @{P='com.tcl.inputmethod.international'; X=$true; N='Teclado TCL'}
  @{P='com.tcl.keyhelp';    X=$true; N='Teclas do controle'}
  @{P='com.tcl.factory.view'; X=$true; N='Menu de fábrica'}
  @{P='com.tcl.suspension'; X=$true; N='Serviço de standby TCL'}
  @{P='com.tcl.android.webview'; X=$true; N='WebView TCL'}
  @{P='com.tvos';           X=$true; N='TV OS TCL'}
  @{P='com.google.android.apps.tv.launcherx'; X=$true; N='Tela inicial (launcher)'}
  @{P='com.google.android.gms'; X=$true; N='Google Play Services'}
  @{P='com.google.android.gsf'; X=$true; N='Google Services Framework'}
  @{P='com.android.vending'; X=$true; N='Play Store'}
  @{P='com.google.android.webview'; X=$true; N='Android WebView'}
  @{P='com.google.android.tv.remote.service'; X=$true; N='Controle remoto Android TV'}
  @{P='com.google.android.inputmethod.latin'; X=$true; N='Teclado Gboard'}
  @{P='com.android.systemui'; X=$true; N='Interface do sistema'}
  @{P='com.android.tv.settings'; X=$true; N='Configurações'}
  @{P='com.android.providers.tv'; X=$true; N='Provedor de canais'}
  @{P='com.android.bluetooth'; X=$true; N='Bluetooth'}
  @{P='android';            X=$true; N='Framework Android'}
)
$script:CatOrdem = @{ 'Ajustes do sistema'=0; 'Tela inicial (launcher)'=1; 'TCL'=2; 'Google'=3; 'Sistema Android'=4; 'Apps de streaming'=5; 'Apps instalados'=6; 'Protegidos (não mexer)'=7; 'Outros pacotes do sistema'=8 }

# launchers alternativos conhecidos (ordem = preferência)
$script:LauncherGoogle = 'com.google.android.apps.tv.launcherx'
$script:LauncherGoogleComp = 'com.google.android.apps.tv.launcherx/.home.HomeActivity'
$script:LaunchersAlt = [ordered]@{
    'com.spocky.projengmenu'      = 'Projectivy Launcher'
    'me.efesser.flauncher'        = 'FLauncher'
    'ca.dstudio.atvlauncher.free' = 'ATV Launcher'
    'ca.dstudio.atvlauncher.pro'  = 'ATV Launcher Pro'
    'com.wolf.firelauncher'       = 'Wolf Launcher'
}
# os que aparecem na aba mesmo sem estarem instalados (com botão de instalar pela Play Store)
$script:LaunchersSugeridos = @(
    @{ P = 'com.spocky.projengmenu'; N = 'Projectivy Launcher'; D = 'Recomendado. Sem anúncios, grade de apps personalizável, esconde apps pré-instalados, atalhos para as entradas HDMI.' }
    @{ P = 'me.efesser.flauncher';   N = 'FLauncher';           D = 'Código aberto e o mais leve: grade simples de apps com papel de parede, sem recomendações.' }
    @{ P = 'ca.dstudio.atvlauncher.free'; N = 'ATV Launcher';   D = 'Simples e leve, com blocos de apps configuráveis. Atualizado com menos frequência.' }
)
# telas "home" do sistema que não contam como launcher alternativo
$script:HomesSistema = @('com.google.android.apps.tv.launcherx', 'com.android.tv.settings', 'com.google.android.tungsten.setupwraith', 'com.android.settings', 'android')

# ---------------------------------------------------------------- XAML
$script:EstilosXaml = @'
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Background" Value="#2A3445"/>
      <Setter Property="Padding" Value="16,8"/>
      <Setter Property="Margin" Value="8,0,0,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.85"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <BooleanToVisibilityConverter x:Key="B2V"/>
    <Style x:Key="Dim" TargetType="FrameworkElement">
      <Style.Triggers>
        <DataTrigger Binding="{Binding JaAplicado}" Value="True"><Setter Property="Opacity" Value="0.4"/></DataTrigger>
      </Style.Triggers>
    </Style>
    <Style x:Key="BtnMini" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Padding" Value="10,3"/>
      <Setter Property="Margin" Value="0"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Background" Value="#2F6FED"/>
    </Style>
    <Style x:Key="BtnRc" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Margin" Value="3"/>
      <Setter Property="Padding" Value="0"/>
      <Setter Property="Height" Value="40"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Focusable" Value="False"/>
    </Style>
    <Style x:Key="BtnPrim" TargetType="Button" BasedOn="{StaticResource Btn}"><Setter Property="Background" Value="#2F6FED"/></Style>
    <Style x:Key="BtnOk" TargetType="Button" BasedOn="{StaticResource Btn}"><Setter Property="Background" Value="#1F9D57"/></Style>
    <Style x:Key="BtnWarn" TargetType="Button" BasedOn="{StaticResource Btn}"><Setter Property="Background" Value="#7A3434"/></Style>
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="#1B2230"/>
      <Setter Property="Foreground" Value="#E6E9EF"/>
      <Setter Property="BorderBrush" Value="#2A3445"/>
      <Setter Property="CaretBrush" Value="#E6E9EF"/>
      <Setter Property="Padding" Value="6,4"/>
    </Style>
    <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#C3CAD6"/></Style>
    <Style TargetType="TabItem">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabItem">
            <Border x:Name="tb" Padding="16,8" Margin="0,0,4,0" Background="Transparent" BorderThickness="0,0,0,3" BorderBrush="Transparent">
              <ContentPresenter ContentSource="Header" TextBlock.Foreground="#8A93A6" TextBlock.FontWeight="SemiBold" x:Name="cp"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="tb" Property="BorderBrush" Value="#2F6FED"/>
                <Setter TargetName="cp" Property="TextBlock.Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="#1B2230"/>
      <Setter Property="Foreground" Value="#AEB6C6"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="8,8"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="BorderBrush" Value="#2A3445"/>
    </Style>
    <Style TargetType="DataGridCell">
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="#E6E9EF"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#24324A"/>
          <Setter Property="Foreground" Value="#FFFFFF"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="DataGrid">
      <Setter Property="Background" Value="#121821"/>
      <Setter Property="RowBackground" Value="#161C26"/>
      <Setter Property="AlternatingRowBackground" Value="#131922"/>
      <Setter Property="Foreground" Value="#E6E9EF"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="GridLinesVisibility" Value="None"/>
      <Setter Property="HeadersVisibility" Value="Column"/>
      <Setter Property="AutoGenerateColumns" Value="False"/>
      <Setter Property="CanUserAddRows" Value="False"/>
      <Setter Property="CanUserDeleteRows" Value="False"/>
      <Setter Property="SelectionMode" Value="Single"/>
    </Style>
    <Style x:Key="Mono" TargetType="TextBox" BasedOn="{StaticResource {x:Type TextBox}}">
      <Setter Property="FontFamily" Value="Consolas"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="IsReadOnly" Value="True"/>
      <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
      <Setter Property="HorizontalScrollBarVisibility" Value="Auto"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="12"/>
      <Setter Property="Background" Value="#121821"/>
    </Style>
'@

$xamlTxt = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="__TITULO__" Height="880" Width="1300" MinHeight="660" MinWidth="1040"
        Background="#0F131A" Foreground="#E6E9EF" FontFamily="Segoe UI" FontSize="13"
        WindowStartupLocation="CenterScreen">
  <Window.Resources>
__ESTILOS__
  </Window.Resources>

  <Grid Margin="18">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- cabeçalho -->
    <DockPanel Grid.Row="0">
      <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock Text="IP da TV" VerticalAlignment="Center" Foreground="#8A93A6" Margin="0,0,6,0"/>
        <TextBox x:Name="txtIp" Width="130" VerticalContentAlignment="Center"/>
        <TextBlock Text="Porta" VerticalAlignment="Center" Foreground="#8A93A6" Margin="12,0,6,0"/>
        <TextBox x:Name="txtPorta" Width="60" Text="5555" VerticalContentAlignment="Center"/>
        <Button x:Name="btnTela" Style="{StaticResource Btn}" Content="Ver tela da TV" Margin="12,0,0,0"/>
        <Button x:Name="btnAnalisar" Style="{StaticResource BtnPrim}" Content="Conectar e analisar"/>
      </StackPanel>
      <StackPanel Orientation="Horizontal">
        <ContentControl x:Name="logoHeader" Width="54" Height="54" VerticalAlignment="Center"/>
        <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
          <StackPanel Orientation="Horizontal">
            <TextBlock Text="TV Otimizador" FontSize="24" FontWeight="Bold"/>
            <TextBlock x:Name="txtVersao" Foreground="#5B8DEF" FontSize="12" VerticalAlignment="Bottom" Margin="10,0,0,5"/>
          </StackPanel>
          <TextBlock x:Name="txtDevice" Text="Informe o IP da TV e clique em Conectar e analisar" Foreground="#8A93A6" Margin="0,2,0,0"/>
        </StackPanel>
      </StackPanel>
    </DockPanel>

    <!-- status -->
    <StackPanel Grid.Row="1" Margin="0,12,0,10">
      <TextBlock x:Name="txtStatus" Text="Pronto." Foreground="#AEB6C6"/>
      <ProgressBar x:Name="pb" Height="4" Margin="0,6,0,0" Background="#1B2230" BorderThickness="0" Foreground="#2F6FED"/>
    </StackPanel>

    <!-- painel de saúde -->
    <Grid Grid.Row="2" Margin="0,0,0,12">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="230"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <Border Background="#161C26" CornerRadius="12" Margin="0,0,12,10" Padding="16">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
          <Grid Width="140" Height="140">
            <Ellipse Stroke="#232C3B" StrokeThickness="12"/>
            <Ellipse x:Name="ringScore" Stroke="#5B8DEF" StrokeThickness="12" StrokeDashArray="0 100" RenderTransformOrigin="0.5,0.5">
              <Ellipse.RenderTransform><RotateTransform Angle="-90"/></Ellipse.RenderTransform>
            </Ellipse>
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
              <TextBlock x:Name="txtScore" Text="--" FontSize="42" FontWeight="Bold" HorizontalAlignment="Center"/>
              <TextBlock Text="de 100" Foreground="#8A93A6" HorizontalAlignment="Center"/>
            </StackPanel>
          </Grid>
          <TextBlock x:Name="txtScoreLabel" Text="Saúde da TV" FontSize="16" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,10,0,0"/>
        </StackPanel>
      </Border>
      <WrapPanel x:Name="pnlCards" Grid.Column="1"/>
    </Grid>

    <!-- abas -->
    <TabControl x:Name="tabs" Grid.Row="3" Background="Transparent" Foreground="#E6E9EF" BorderThickness="0" Padding="0,8,0,0">
      <TabItem Header="Recomendações">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <DockPanel Margin="0,0,0,8">
            <StackPanel Orientation="Horizontal">
              <Button x:Name="btnSugeridos" Style="{StaticResource Btn}" Content="Marcar sugeridos" Margin="0"/>
              <Button x:Name="btnEstadoAtual" Style="{StaticResource Btn}" Content="Voltar ao estado atual"/>
              <CheckBox x:Name="chkTodos" Content="Mostrar pacotes protegidos e desconhecidos" VerticalAlignment="Center" Margin="16,0,0,0"/>
            </StackPanel>
          </DockPanel>
          <DataGrid x:Name="dgItens" Grid.Row="1">
            <DataGrid.GroupStyle>
              <GroupStyle>
                <GroupStyle.ContainerStyle>
                  <Style TargetType="{x:Type GroupItem}">
                    <Setter Property="Template">
                      <Setter.Value>
                        <ControlTemplate TargetType="{x:Type GroupItem}">
                          <StackPanel>
                            <Border Background="#1B2230" Padding="10,6" Margin="0,6,0,0" CornerRadius="6">
                              <StackPanel Orientation="Horizontal">
                                <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="14" Foreground="#FFFFFF"/>
                                <TextBlock Text="{Binding ItemCount, StringFormat='  ·  {0} itens'}" Foreground="#8A93A6" VerticalAlignment="Center"/>
                              </StackPanel>
                            </Border>
                            <ItemsPresenter/>
                          </StackPanel>
                        </ControlTemplate>
                      </Setter.Value>
                    </Setter>
                  </Style>
                </GroupStyle.ContainerStyle>
              </GroupStyle>
            </DataGrid.GroupStyle>
            <DataGrid.Columns>
              <DataGridTemplateColumn Header="" Width="42">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate>
                    <Grid>
                      <CheckBox IsChecked="{Binding Selecionado, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsEnabled="{Binding Editavel}" HorizontalAlignment="Center" VerticalAlignment="Center"
                                Visibility="{Binding MostraCheck, Converter={StaticResource B2V}}"/>
                      <TextBlock Text="✓" Foreground="#3DDC84" FontWeight="Bold" FontSize="16" HorizontalAlignment="Center" VerticalAlignment="Center"
                                 Visibility="{Binding JaAplicado, Converter={StaticResource B2V}}" ToolTip="Já aplicado"/>
                    </Grid>
                  </DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Item" Width="270" SortMemberPath="Nome">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate>
                    <StackPanel Margin="4,6" Style="{StaticResource Dim}">
                      <TextBlock Text="{Binding Nome}" FontWeight="SemiBold" TextWrapping="Wrap"/>
                      <TextBlock Text="{Binding Id}" FontSize="11" Foreground="#7F8AA0" TextWrapping="Wrap"/>
                    </StackPanel>
                  </DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Sugestão" Width="95" SortMemberPath="Sugerido">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate><TextBlock Text="{Binding SugestaoTexto}" Foreground="#FFC857" FontWeight="SemiBold" VerticalAlignment="Center" Margin="4,0" Style="{StaticResource Dim}"/></DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Risco" Width="80" SortMemberPath="Risco">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate>
                    <Grid Style="{StaticResource Dim}">
                    <Border CornerRadius="10" Padding="8,2" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="4,0">
                      <Border.Style>
                        <Style TargetType="Border">
                          <Setter Property="Background" Value="#2A3445"/>
                          <Style.Triggers>
                            <DataTrigger Binding="{Binding Risco}" Value="Baixo"><Setter Property="Background" Value="#1F5E3A"/></DataTrigger>
                            <DataTrigger Binding="{Binding Risco}" Value="Médio"><Setter Property="Background" Value="#6B5414"/></DataTrigger>
                            <DataTrigger Binding="{Binding Risco}" Value="Alto"><Setter Property="Background" Value="#6E2A2A"/></DataTrigger>
                          </Style.Triggers>
                        </Style>
                      </Border.Style>
                      <TextBlock Text="{Binding Risco}" FontSize="11" Foreground="#FFFFFF"/>
                    </Border>
                    </Grid>
                  </DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Estado atual" Width="130" SortMemberPath="Estado">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate><TextBlock Text="{Binding Estado}" VerticalAlignment="Center" TextWrapping="Wrap" Margin="4,0" Style="{StaticResource Dim}"/></DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="RAM" Width="70" SortMemberPath="Ram">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate><TextBlock Text="{Binding Ram}" VerticalAlignment="Center" Margin="4,0" Style="{StaticResource Dim}"/></DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Cache" Width="75" SortMemberPath="Cache">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate><TextBlock Text="{Binding Cache}" VerticalAlignment="Center" Margin="4,0" Style="{StaticResource Dim}"/></DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Ação" Width="100" SortMemberPath="Acao">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate>
                    <Grid>
                    <Button Content="Restaurar" Tag="restaurar" Style="{StaticResource BtnMini}" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="4,0"
                            ToolTip="Desfaz esta alteração na TV agora" Visibility="{Binding JaAplicado, Converter={StaticResource B2V}}"/>
                    <TextBlock Text="{Binding Acao}" FontWeight="Bold" VerticalAlignment="Center" Margin="4,0" Visibility="{Binding MostraCheck, Converter={StaticResource B2V}}">
                      <TextBlock.Style>
                        <Style TargetType="TextBlock">
                          <Setter Property="Foreground" Value="#E6E9EF"/>
                          <Style.Triggers>
                            <DataTrigger Binding="{Binding Acao}" Value="Desativar"><Setter Property="Foreground" Value="#FF8A65"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Reativar"><Setter Property="Foreground" Value="#64B5F6"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Aplicar"><Setter Property="Foreground" Value="#3DDC84"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Desfazer"><Setter Property="Foreground" Value="#64B5F6"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Executar"><Setter Property="Foreground" Value="#3DDC84"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Protegido"><Setter Property="Foreground" Value="#6B7385"/></DataTrigger>
                            <DataTrigger Binding="{Binding Acao}" Value="Indisponível"><Setter Property="Foreground" Value="#6B7385"/></DataTrigger>
                          </Style.Triggers>
                        </Style>
                      </TextBlock.Style>
                    </TextBlock>
                    </Grid>
                  </DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
              <DataGridTemplateColumn Header="Descrição" Width="*">
                <DataGridTemplateColumn.CellTemplate>
                  <DataTemplate><TextBlock Text="{Binding Descricao}" TextWrapping="Wrap" Foreground="#C3CAD6" Margin="4,6" VerticalAlignment="Center" Style="{StaticResource Dim}"/></DataTemplate>
                </DataGridTemplateColumn.CellTemplate>
              </DataGridTemplateColumn>
            </DataGrid.Columns>
          </DataGrid>
        </Grid>
      </TabItem>
      <TabItem x:Name="tabLauncher" Header="Tela inicial">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel x:Name="pnlLauncher" Margin="0,4,8,0">
            <TextBlock Text="Conecte e analise a TV para ver as opções de tela inicial." Foreground="#8A93A6" Margin="4,8"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>
      <TabItem Header="Processos">
        <DataGrid x:Name="dgProc" IsReadOnly="True">
          <DataGrid.Columns>
            <DataGridTextColumn Header="Processo" Binding="{Binding Processo}" Width="*"/>
            <DataGridTextColumn Header="Identificado como" Binding="{Binding Nome}" Width="260"/>
            <DataGridTextColumn Header="RAM (MB)" Binding="{Binding RamMB}" Width="100"/>
            <DataGridTextColumn Header="CPU (%)" Binding="{Binding Cpu}" Width="90"/>
          </DataGrid.Columns>
        </DataGrid>
      </TabItem>
      <TabItem Header="Diagnóstico">
        <TextBox x:Name="txtDiag" Style="{StaticResource Mono}"/>
      </TabItem>
      <TabItem Header="Log">
        <TextBox x:Name="txtLog" Style="{StaticResource Mono}"/>
      </TabItem>
      <TabItem x:Name="tabConfig" Header="Configurações">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel x:Name="pnlConfig" Margin="0,4,8,8"/>
        </ScrollViewer>
      </TabItem>
    </TabControl>

    <!-- rodapé -->
    <DockPanel Grid.Row="4" Margin="0,12,0,0">
      <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
        <Button x:Name="btnExportar" Style="{StaticResource Btn}" Content="Exportar relatório"/>
        <Button x:Name="btnReverter" Style="{StaticResource BtnWarn}" Content="Reverter tudo"/>
        <Button x:Name="btnAplicar" Style="{StaticResource BtnOk}" Content="Aplicar alterações"/>
      </StackPanel>
      <TextBlock x:Name="txtMudancas" Text="Nenhuma alteração selecionada." VerticalAlignment="Center" Foreground="#AEB6C6"/>
    </DockPanel>
  </Grid>
</Window>
'@
[xml]$xaml = $xamlTxt.Replace('__ESTILOS__', $script:EstilosXaml).Replace('__TITULO__', "TV Otimizador $($script:AppVersion)")

$script:TelaXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tela da TV — TV Otimizador" Width="1400" Height="860" MinWidth="900" MinHeight="600"
        Background="#0F131A" Foreground="#E6E9EF" FontFamily="Segoe UI" FontSize="13" WindowStartupLocation="CenterScreen">
  <Window.Resources>
__ESTILOS__
  </Window.Resources>
  <Grid Margin="14">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition Width="Auto"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Border Background="#000000" CornerRadius="8" Margin="0,0,14,0">
      <Grid>
        <Image x:Name="imgTela" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality" Margin="4"/>
        <TextBlock x:Name="txtTelaVazia" Text="Capturando a tela da TV..." Foreground="#6B7385" FontSize="16"
                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Grid>
    </Border>
    <StackPanel Grid.Column="1" Width="262">
      <Button x:Name="btnTelaAtualizar" Style="{StaticResource BtnPrim}" Content="Atualizar tela" Margin="0"/>
      <CheckBox x:Name="chkTelaAuto" Content="Atualizar automaticamente" Margin="0,10,0,0" IsChecked="True"/>

      <TextBlock Text="Controle remoto" FontWeight="SemiBold" Margin="0,18,0,6"/>
      <Grid Width="186" HorizontalAlignment="Center">
        <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
        <Grid.RowDefinitions><RowDefinition/><RowDefinition/><RowDefinition/></Grid.RowDefinitions>
        <Button Grid.Row="0" Grid.Column="1" Style="{StaticResource BtnRc}" Content="▲" Tag="key:19"/>
        <Button Grid.Row="1" Grid.Column="0" Style="{StaticResource BtnRc}" Content="◀" Tag="key:21"/>
        <Button Grid.Row="1" Grid.Column="1" Style="{StaticResource BtnRc}" Content="OK" Tag="key:23" Background="#2F6FED"/>
        <Button Grid.Row="1" Grid.Column="2" Style="{StaticResource BtnRc}" Content="▶" Tag="key:22"/>
        <Button Grid.Row="2" Grid.Column="1" Style="{StaticResource BtnRc}" Content="▼" Tag="key:20"/>
      </Grid>
      <UniformGrid Columns="3" Margin="0,8,0,0">
        <Button Style="{StaticResource BtnRc}" Content="↩ Voltar" Tag="key:4"/>
        <Button Style="{StaticResource BtnRc}" Content="⌂ Home" Tag="key:3"/>
        <Button Style="{StaticResource BtnRc}" Content="☰ Menu" Tag="key:82"/>
        <Button Style="{StaticResource BtnRc}" Content="Vol −" Tag="key:25"/>
        <Button Style="{StaticResource BtnRc}" Content="Mudo" Tag="key:164"/>
        <Button Style="{StaticResource BtnRc}" Content="Vol +" Tag="key:24"/>
        <Button Style="{StaticResource BtnRc}" Content="⏯" Tag="key:85"/>
        <Button Style="{StaticResource BtnRc}" Content="Config." Tag="cmd:settings"/>
        <Button Style="{StaticResource BtnRc}" Content="Apps" Tag="cmd:apps"/>
      </UniformGrid>

      <TextBlock Text="Digitar na TV" FontWeight="SemiBold" Margin="0,18,0,6"/>
      <DockPanel>
        <Button x:Name="btnEnviarTexto" DockPanel.Dock="Right" Style="{StaticResource Btn}" Content="Enviar" Padding="12,6"/>
        <TextBox x:Name="txtEnviar" VerticalContentAlignment="Center"/>
      </DockPanel>

      <Button x:Name="btnScrcpy" Style="{StaticResource BtnOk}" Content="Abrir tela ao vivo (scrcpy)" Margin="0,22,0,0"/>
      <TextBlock Foreground="#8A93A6" FontSize="11" TextWrapping="Wrap" Margin="0,14,0,0"
                 Text="Teclado: setas, Enter = OK, Esc/Backspace = Voltar, Home, PgUp/PgDn = volume, Espaço = play/pausa.&#10;&#10;Vídeos com proteção (Netflix, Globoplay, Disney+...) aparecem pretos na captura; menus e apps aparecem normalmente."/>
    </StackPanel>
    <TextBlock x:Name="txtTelaInfo" Grid.Row="1" Grid.ColumnSpan="2" Foreground="#8A93A6" FontSize="11" Margin="2,8,0,0"/>
  </Grid>
</Window>
'@

Set-Splash 'Montando a interface...'
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach ($n in 'tabs','tabLauncher','tabConfig','pnlLauncher','pnlConfig','logoHeader','txtVersao','btnTela',
               'txtIp','txtPorta','btnAnalisar','txtDevice','txtStatus','pb','ringScore','txtScore','txtScoreLabel','pnlCards',
               'btnSugeridos','btnEstadoAtual','chkTodos','dgItens','dgProc','txtDiag','txtLog','btnExportar','btnReverter','btnAplicar','txtMudancas') {
    Set-Variable -Name $n -Value $win.FindName($n) -Scope Script
}

# ---------------------------------------------------------------- utilitários
$script:Cores = @{ 0='#3DDC84'; 1='#FFB020'; 2='#FF5C5C' }
$script:Brush = New-Object System.Windows.Media.BrushConverter
function Get-Brush([string]$hex) { $script:Brush.ConvertFromString($hex) }

function Wait-UI([int]$ms) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $ms) { DoEvents; Start-Sleep -Milliseconds 30 }
}
function Log([string]$msg) {
    $txtLog.AppendText(("[{0}] {1}`r`n" -f (Get-Date -Format 'HH:mm:ss'), $msg))
    $txtLog.ScrollToEnd()
}
function Set-Status([string]$msg) { $txtStatus.Text = $msg; DoEvents }
function Set-Busy([bool]$busy, [string]$msg = $null) {
    $pb.IsIndeterminate = $busy
    foreach ($b in $btnAnalisar, $btnAplicar, $btnReverter, $btnSugeridos, $btnEstadoAtual, $btnExportar, $btnTela) { $b.IsEnabled = -not $busy }
    $pnlConfig.IsEnabled = -not $busy
    if ($msg) { Set-Status $msg }
}
function Show-Msg([string]$msg, [string]$titulo = 'TV Otimizador', [string]$icone = 'Information') {
    [System.Windows.MessageBox]::Show($win, $msg, $titulo, 'OK', $icone) | Out-Null
}

# ---------------------------------------------------------------- configuração (em %APPDATA%\TV-Otimizador)
$script:CfgDir = Join-Path $env:APPDATA 'TV-Otimizador'
$script:CfgFile = Join-Path $script:CfgDir 'config.json'
function Get-Config {
    $c = @{ ip = ''; porta = '5555'; adbPath = ''; scrcpyPath = '' }
    if (Test-Path $script:CfgFile) {
        try {
            $j = Get-Content $script:CfgFile -Raw | ConvertFrom-Json
            foreach ($k in @($c.Keys)) { if ($j.$k) { $c[$k] = [string]$j.$k } }
        } catch {}
    }
    return $c
}
function Save-Config {
    try {
        if (-not (Test-Path $script:CfgDir)) { New-Item -ItemType Directory -Path $script:CfgDir -Force | Out-Null }
        $script:Cfg | ConvertTo-Json | Set-Content -Path $script:CfgFile -Encoding UTF8
    } catch {}
}
$script:Cfg = Get-Config

# ---------------------------------------------------------------- dependências (adb / scrcpy)
function Find-Deps {
    $script:AdbExe = $null; $script:ScrcpyExe = $null
    foreach ($c in @($script:Cfg.adbPath, (Join-Path $PSScriptRoot 'adb.exe'), (Join-Path $PSScriptRoot 'platform-tools\adb.exe'), (Join-Path (Get-Location) 'adb.exe'))) {
        if ($c -and (Test-Path $c)) { $script:AdbExe = (Resolve-Path $c).Path; break }
    }
    if (-not $script:AdbExe) { $g = Get-Command adb -ErrorAction SilentlyContinue; if ($g) { $script:AdbExe = $g.Source } }
    foreach ($c in @($script:Cfg.scrcpyPath, (Join-Path $PSScriptRoot 'scrcpy.exe'))) {
        if ($c -and (Test-Path $c)) { $script:ScrcpyExe = (Resolve-Path $c).Path; break }
    }
    if (-not $script:ScrcpyExe -and $PSScriptRoot) {
        $f = Get-ChildItem -Path $PSScriptRoot -Filter 'scrcpy.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($f) { $script:ScrcpyExe = $f.FullName }
    }
    if (-not $script:ScrcpyExe) { $g = Get-Command scrcpy -ErrorAction SilentlyContinue; if ($g) { $script:ScrcpyExe = $g.Source } }
}

function Invoke-Exe([string]$exe, [string]$argumentos, [int]$timeoutSec = 60) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $argumentos
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [Text.Encoding]::UTF8
    $p = [Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync()
    $err = $p.StandardError.ReadToEndAsync()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not $p.HasExited) {
        DoEvents; Start-Sleep -Milliseconds 40
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { try { $p.Kill() } catch {} ; break }
    }
    while (-not ($out.IsCompleted -and $err.IsCompleted)) { DoEvents; Start-Sleep -Milliseconds 20 }
    return ($out.Result + $err.Result)
}
function Invoke-Adb([string]$argumentos, [int]$timeoutSec = 60) {
    if (-not $script:AdbExe) { throw 'adb.exe não encontrado. Instale pela aba Configurações.' }
    Invoke-Exe $script:AdbExe $argumentos $timeoutSec
}
function Get-ExeVersao([string]$exe, [string]$arg) {
    try {
        $linhas = Split-Linhas (Invoke-Exe $exe $arg 8)
        $l = $linhas | Where-Object { $_ -match '^(Version\s|scrcpy\s)' } | Select-Object -First 1
        if (-not $l) { $l = $linhas | Select-Object -First 1 }
        return (($l -split '<')[0]).Trim()
    } catch { return '' }
}
function Invoke-Tv([string]$cmd, [int]$timeoutSec = 60) {
    Invoke-Adb ('-s {0} shell "{1}"' -f $script:Alvo, $cmd) $timeoutSec
}
function Split-Linhas([string]$t) { if (-not $t) { return @() } ; return @($t -split "\r?\n") }
function MB($kb) { [math]::Round($kb / 1024, 0) }
function Fmt-MB($mb) { if ($mb -ge 1024) { '{0:N1} GB' -f ($mb / 1024) } else { '{0:N0} MB' -f $mb } }

# ---------------------------------------------------------------- histórico (o que o app mudou)
$script:HistFile = Join-Path $script:CfgDir 'historico.json'
$histAntigo = Join-Path $PSScriptRoot 'tv-otimizador-historico.json'
if ((Test-Path $histAntigo) -and -not (Test-Path $script:HistFile)) {
    try { New-Item -ItemType Directory -Path $script:CfgDir -Force | Out-Null; Copy-Item $histAntigo $script:HistFile } catch {}
}
function Get-Hist {
    $h = @{ pacotes = @(); cacheproc = $false; anim = $false; launcher = '' }
    if (Test-Path $script:HistFile) {
        try {
            $j = Get-Content $script:HistFile -Raw | ConvertFrom-Json
            if ($j.pacotes) { $h.pacotes = @($j.pacotes) }
            $h.cacheproc = [bool]$j.cacheproc; $h.anim = [bool]$j.anim
            if ($j.launcher) { $h.launcher = [string]$j.launcher }
        } catch {}
    }
    return $h
}
function Save-Hist($h) {
    if (-not (Test-Path $script:CfgDir)) { New-Item -ItemType Directory -Path $script:CfgDir -Force | Out-Null }
    $h | ConvertTo-Json | Set-Content -Path $script:HistFile -Encoding UTF8
}

# ---------------------------------------------------------------- avaliação
function Get-Nivel([double]$v, [double]$bom, [double]$ruim, [switch]$Maior) {
    # $Maior: valores maiores são melhores
    if ($Maior) { if ($v -ge $bom) { 0 } elseif ($v -ge $ruim) { 1 } else { 2 } }
    else        { if ($v -lt $bom) { 0 } elseif ($v -lt $ruim) { 1 } else { 2 } }
}
function New-Card([string]$titulo, [string]$valor, [double]$barra, [int]$nivel, [string]$dica) {
    $cor = Get-Brush $script:Cores[$nivel]
    $b = New-Object System.Windows.Controls.Border
    $b.Width = 245; $b.Height = 118; $b.Margin = '0,0,10,10'; $b.Padding = '14,12'
    $b.CornerRadius = 12; $b.Background = Get-Brush '#161C26'
    $sp = New-Object System.Windows.Controls.StackPanel
    $t1 = New-Object System.Windows.Controls.TextBlock; $t1.Text = $titulo; $t1.Foreground = Get-Brush '#8A93A6'; $t1.FontSize = 12
    $t2 = New-Object System.Windows.Controls.TextBlock; $t2.Text = $valor; $t2.FontSize = 22; $t2.FontWeight = 'Bold'; $t2.Foreground = $cor; $t2.Margin = '0,2,0,6'
    $pg = New-Object System.Windows.Controls.ProgressBar; $pg.Height = 6; $pg.Value = [math]::Max(0, [math]::Min(100, $barra))
    $pg.Foreground = $cor; $pg.Background = Get-Brush '#232C3B'; $pg.BorderThickness = 0
    $t3 = New-Object System.Windows.Controls.TextBlock; $t3.Text = $dica; $t3.FontSize = 11; $t3.Foreground = Get-Brush '#AEB6C6'
    $t3.TextWrapping = 'Wrap'; $t3.Margin = '0,6,0,0'
    foreach ($e in $t1, $t2, $pg, $t3) { [void]$sp.Children.Add($e) }
    $b.Child = $sp
    [void]$pnlCards.Children.Add($b)
}
function Set-Score([int]$score) {
    $nivel = if ($score -ge 75) { 0 } elseif ($score -ge 50) { 1 } else { 2 }
    $label = if ($score -ge 85) { 'Ótima' } elseif ($score -ge 70) { 'Boa' } elseif ($score -ge 50) { 'Regular' } else { 'Ruim' }
    $txtScore.Text = $score
    $txtScoreLabel.Text = "Saúde: $label"
    $ringScore.Stroke = Get-Brush $script:Cores[$nivel]
    $circ = [math]::PI * (140 - 12) / 12      # circunferência em unidades de StrokeThickness
    $dc = New-Object System.Windows.Media.DoubleCollection
    $dc.Add($circ * $score / 100); $dc.Add(1000)
    $ringScore.StrokeDashArray = $dc
}

# ---------------------------------------------------------------- conexão
function Connect-Tv {
    $script:Alvo = '{0}:{1}' -f $txtIp.Text.Trim(), $txtPorta.Text.Trim()
    if ((Invoke-Adb "-s $($script:Alvo) get-state" 6).Trim() -eq 'device') { return $true }
    Log ("adb connect: " + (Invoke-Adb "connect $($script:Alvo)" 15).Trim())
    $st = ''
    for ($i = 0; $i -lt 45; $i++) {
        $st = (Invoke-Adb "-s $($script:Alvo) get-state" 6).Trim()
        if ($st -eq 'device') { return $true }
        if ($i -eq 0 -and $st -match 'offline|refused|failed|cannot') { Invoke-Adb "connect $($script:Alvo)" 10 | Out-Null }
        Set-Status "Aguardando a TV... confirme 'Permitir depuração' na tela e marque 'Sempre permitir'."
        Wait-UI 1500
    }
    Log "Sem conexão: $st"
    return $false
}

# ---------------------------------------------------------------- análise
function Start-Analise {
    if (-not $script:AdbExe) {
        $tabs.SelectedItem = $tabConfig
        Show-Msg 'O ADB ainda não está instalado. Na aba Configurações, clique em "Baixar e instalar" no item ADB.' 'ADB não encontrado' 'Warning'
        return
    }
    if (-not $txtIp.Text.Trim()) { Show-Msg 'Informe o IP da TV (Configurações da TV > Rede > Status).'; $txtIp.Focus() | Out-Null; return }
    $script:Cfg.ip = $txtIp.Text.Trim(); $script:Cfg.porta = $txtPorta.Text.Trim(); Save-Config
    Set-Busy $true "Conectando em $($txtIp.Text.Trim())..."
    $script:Raw = [ordered]@{}
    try {
        if (-not @(Connect-Tv)[-1]) { throw "A TV não respondeu ou não autorizou a conexão. Verifique se ela está ligada e com a depuração de rede/ADB ativada." }

        Set-Status 'Lendo informações do sistema...'
        $info = Split-Linhas (Invoke-Tv 'getprop ro.product.manufacturer; getprop ro.product.model; getprop ro.product.device; getprop ro.board.platform; getprop ro.build.version.release; cat /proc/uptime; cat /proc/loadavg; grep -c processor /proc/cpuinfo')
        $script:Raw['Sistema'] = $info -join "`n"

        Set-Status 'Lendo memória...'
        $mem = Invoke-Tv "cat /proc/meminfo; grep -E 'pgsteal|pswp' /proc/vmstat"
        $script:Raw['Memória (kernel)'] = $mem

        Set-Status 'Medindo CPU (4 segundos)...'
        $top = Invoke-Tv 'top -b -n 2 -d 2 -m 20 -o PID,%CPU,RES,ARGS' 30
        $script:Raw['CPU (top)'] = $top

        Set-Status 'Medindo RAM por processo (pode levar ~20 s)...'
        $dmem = Invoke-Tv 'dumpsys meminfo' 120
        $script:Raw['dumpsys meminfo'] = $dmem

        Set-Status 'Lendo armazenamento e caches...'
        $disk = Invoke-Tv 'dumpsys diskstats' 60
        $script:Raw['dumpsys diskstats'] = $disk

        Set-Status 'Listando pacotes...'
        $pk = Invoke-Tv 'pm list packages -s; echo @@3; pm list packages -3; echo @@d; pm list packages -d' 60
        $script:Raw['Pacotes'] = $pk

        Set-Status 'Procurando launchers...'
        $homes = Invoke-Tv 'cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME; echo @@atual; cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' 30
        $script:Raw['Telas iniciais (HOME)'] = $homes

        Set-Status 'Lendo configurações...'
        $cfg = Split-Linhas (Invoke-Tv 'settings get global window_animation_scale; settings get global activity_manager_constants')
        $script:Raw['Configurações'] = $cfg -join "`n"

        Set-Status 'Avaliando...'
        Build-Resultado $info $mem $top $dmem $disk $pk $cfg $homes
        Set-Status ("Análise concluída às {0}. Revise as recomendações e clique em 'Aplicar alterações'." -f (Get-Date -Format 'HH:mm'))
        Log 'Análise concluída.'
    } catch {
        Set-Status "Erro: $($_.Exception.Message)"
        Log "ERRO: $($_.Exception.Message)"
        Show-Msg $_.Exception.Message 'Erro' 'Error'
    } finally {
        Set-Busy $false
    }
}

function Build-Resultado($info, $mem, $top, $dmem, $disk, $pk, $cfg, $homes) {
    # --- sistema
    $info = @($info) + @('', '', '', '', '', '', '', '')
    $fab = $info[0].Trim(); $modelo = $info[1].Trim(); $dev = $info[2].Trim(); $plat = $info[3].Trim(); $andr = $info[4].Trim()
    $upH = [double]((($info[5] -split '\s+')[0]) -replace ',', '.') / 3600
    $load1 = [double]((($info[6] -split '\s+')[0]) -replace ',', '.')
    $cores = [int]($info[7].Trim()); if ($cores -lt 1) { $cores = 4 }
    $txtDevice.Text = "$fab $modelo ($dev) · Android $andr · $plat · $cores núcleos · $($script:Alvo)"

    # --- memória
    $mi = @{}; $vm = @{ direct = 0.0; kswapd = 0.0; pswpout = 0.0 }
    foreach ($l in (Split-Linhas $mem)) {
        if ($l -match '^([\w\(\)]+):\s+(\d+)\s*kB') { $mi[$matches[1]] = [double]$matches[2] }
        elseif ($l -match '^pgsteal_direct\w*\s+(\d+)') { $vm.direct += [double]$matches[1] }
        elseif ($l -match '^pgsteal_kswapd\w*\s+(\d+)') { $vm.kswapd += [double]$matches[1] }
        elseif ($l -match '^pswpout\s+(\d+)') { $vm.pswpout = [double]$matches[1] }
    }
    $totMB = MB $mi['MemTotal']; $availMB = MB $mi['MemAvailable']; $cmaMB = MB $mi['CmaTotal']
    $availPct = if ($mi['MemTotal']) { $mi['MemAvailable'] / $mi['MemTotal'] * 100 } else { 0 }
    $swTot = $mi['SwapTotal']; $swUsed = $mi['SwapTotal'] - $mi['SwapFree']
    $swPct = if ($swTot) { $swUsed / $swTot * 100 } else { 0 }
    $recl = $vm.direct + $vm.kswapd
    $directPct = if ($recl -gt 10000) { $vm.direct / $recl * 100 } else { 0 }
    $swapGB = $vm.pswpout * 4 / 1024 / 1024

    # --- CPU (segunda amostra do top)
    $blocos = $top -split 'Tasks:'
    $ult = $blocos[-1]
    $cpuUso = 0.0; $cpuPid = @{}; $cpuLista = @()
    if ($ult -match '(\d+)%cpu.*?(\d+)%idle') { $cpuUso = (([double]$matches[1] - [double]$matches[2]) / [double]$matches[1]) * 100 }
    foreach ($l in (Split-Linhas $ult)) {
        if ($l -match '^\s*(\d+)\s+([\d.]+)\s+(\S+)\s+(.+?)\s*$') {
            $cpuPid[$matches[1]] = [double]$matches[2]
            $cpuLista += [pscustomobject]@{ Pid = $matches[1]; Cpu = [double]$matches[2]; Nome = $matches[4] }
        }
    }

    # --- PSS por processo
    $procs = @(); $pkgRam = @{}; $sec = $false
    foreach ($l in (Split-Linhas $dmem)) {
        if ($l -match 'Total PSS by process') { $sec = $true; continue }
        if ($sec -and $l -match 'Total PSS by OOM') { break }
        if ($sec -and $l -match '^\s*([\d,\.]+)K:\s+(.+?)\s+\(pid\s+(\d+)') {
            $kb = [double]($matches[1] -replace '[,\.]', '')
            $nome = $matches[2]; $procId = $matches[3]
            $base = ($nome -split ':')[0]
            $pkgRam[$base] = $pkgRam[$base] + $kb
            $procs += [pscustomobject]@{ Processo = $nome; Pid = $procId; Base = $base; RamKB = $kb }
        }
    }

    # --- disco e caches
    $cacheMap = @{}; $cacheTotMB = 0.0; $dataFreePct = 100.0; $dataFreeGB = 0.0
    foreach ($l in (Split-Linhas $disk)) {
        if ($l -match '^Data-Free:\s*(\d+)K\s*/\s*(\d+)K') { $dataFreeGB = [double]$matches[1] / 1MB; $dataFreePct = [double]$matches[1] / [double]$matches[2] * 100 }
        elseif ($l -match '^Package Names:\s*(\[.*\])') { $pn = $matches[1] | ConvertFrom-Json }
        elseif ($l -match '^Cache Sizes:\s*(\[.*\])') { $cs = $matches[1] | ConvertFrom-Json }
    }
    if ($pn -and $cs -and $pn.Count -eq $cs.Count) {
        for ($i = 0; $i -lt $pn.Count; $i++) { $mbc = [double]$cs[$i] / 1MB; $cacheMap[$pn[$i]] = $mbc; $cacheTotMB += $mbc }
    }

    # --- pacotes
    $sys = @(); $terc = @(); $desat = @{}; $modo = 's'
    foreach ($l in (Split-Linhas $pk)) {
        $l = $l.Trim()
        if ($l -eq '@@3') { $modo = '3'; continue }
        if ($l -eq '@@d') { $modo = 'd'; continue }
        if ($l -notmatch '^package:(.+)$') { continue }
        $p = $matches[1]
        switch ($modo) { 's' { $sys += $p } '3' { $terc += $p } 'd' { $desat[$p] = $true } }
    }
    $instalados = @{}; foreach ($p in $sys) { $instalados[$p] = 's' }; foreach ($p in $terc) { $instalados[$p] = '3' }

    # --- configurações
    $anim = if ($cfg.Count -gt 0) { $cfg[0].Trim() } else { 'null' }
    $amc = if ($cfg.Count -gt 1) { $cfg[1].Trim() } else { 'null' }
    $cacheProcAtual = 32
    if ($amc -match 'max_cached_processes=(\d+)') { $cacheProcAtual = [int]$matches[1] }

    # ================= cards e nota
    $pnlCards.Children.Clear()
    $n = @{}
    $n.ram   = Get-Nivel $availPct 30 15 -Maior
    $n.swap  = Get-Nivel $swPct 30 60
    $n.trav  = Get-Nivel $directPct 20 50
    $n.load  = Get-Nivel ($load1 / $cores) 1.5 3
    $n.cpu   = Get-Nivel $cpuUso 40 75
    $n.disco = Get-Nivel $dataFreePct 25 10 -Maior
    $n.cache = Get-Nivel $cacheTotMB 300 1000
    $n.up    = Get-Nivel $upH 24 72
    $dias = [math]::Floor($upH / 24); $horas = [math]::Floor($upH % 24)

    New-Card 'Memória livre' "$availMB MB" (100 - $availPct) $n.ram "de $totMB MB · $cmaMB MB reservados para vídeo"
    New-Card 'Swap (zram) em uso' ('{0:N0}%' -f $swPct) $swPct $n.swap ('{0} de {1} MB comprimidos' -f (MB $swUsed), (MB $swTot))
    New-Card 'Travadas por falta de memória' ('{0:N0}%' -f $directPct) $directPct $n.trav 'da memória é liberada travando o app em uso (ideal < 20%)'
    New-Card 'Carga do sistema' ('{0:N1}' -f $load1) ($load1 / $cores / 4 * 100) $n.load "$cores núcleos · processos esperando CPU ou memória"
    New-Card 'Uso de CPU' ('{0:N0}%' -f $cpuUso) $cpuUso $n.cpu 'medido com a TV parada'
    New-Card 'Armazenamento livre' ('{0:N1} GB' -f $dataFreeGB) (100 - $dataFreePct) $n.disco ('{0:N0}% livre na partição de dados' -f $dataFreePct)
    New-Card 'Cache dos apps' (Fmt-MB $cacheTotMB) ($cacheTotMB / 1500 * 100) $n.cache 'pode ser limpo sem perder dados'
    New-Card 'Tempo ligada' ("{0}d {1}h" -f $dias, $horas) ($upH / 72 * 100) $n.up ('{0:N0} GB já passaram pela swap' -f $swapGB)

    $pesos = @{ ram = 15; swap = 15; trav = 20; load = 15; cpu = 10; disco = 10; cache = 5; up = 10 }
    $pts = @{ 0 = 100; 1 = 55; 2 = 15 }
    $soma = 0; foreach ($k in $pesos.Keys) { $soma += $pesos[$k] * $pts[$n[$k]] }
    Set-Score ([int][math]::Round($soma / 100))

    # ================= itens
    $itens = New-Object 'System.Collections.ObjectModel.ObservableCollection[TvItemV2]'
    $hist = Get-Hist

    # ajustes do sistema
    $sugCache = ($n.trav -ge 1) -or ($n.swap -ge 1)
    $itens.Add([TvItemV2]@{ Tipo = 'tweak'; Id = 'cacheproc'; Nome = 'Limitar processos em cache (32 → 10)'; Categoria = 'Ajustes do sistema'
        Descricao = 'Reduz quantos apps ficam abertos em segundo plano. Diminui a troca na zram e as travadas; apps reabrem um pouco mais devagar.'
        Risco = 'Baixo'; Sugerido = $sugCache; AplicadoAgora = ($cacheProcAtual -lt 32); Estado = "Atual: $cacheProcAtual"; Editavel = $true })
    $animAtual = if ($anim -eq 'null' -or -not $anim) { '1.0' } else { $anim }
    $itens.Add([TvItemV2]@{ Tipo = 'tweak'; Id = 'anim'; Nome = 'Animações em 0,5x'; Categoria = 'Ajustes do sistema'
        Descricao = 'Deixa as transições de tela mais curtas (o sistema parece mais ágil). Desmarcado = 1x.'
        Risco = 'Baixo'; Sugerido = $false; AplicadoAgora = ($animAtual -eq '0.5'); Estado = "Atual: ${animAtual}x"; Editavel = $true })
    $itens.Add([TvItemV2]@{ Tipo = 'tweak'; Id = 'trim'; Nome = ('Limpar cache de todos os apps ({0})' -f (Fmt-MB $cacheTotMB)); Categoria = 'Ajustes do sistema'
        Descricao = 'Apaga arquivos temporários. Não apaga logins nem configurações.'; OneShot = $true
        Risco = 'Baixo'; Sugerido = ($cacheTotMB -ge 300); Estado = (Fmt-MB $cacheTotMB); Editavel = $true })
    $itens.Add([TvItemV2]@{ Tipo = 'tweak'; Id = 'reboot'; Nome = 'Reiniciar a TV ao final'; Categoria = 'Ajustes do sistema'
        Descricao = 'Esvazia a zram e começa do zero. Recomendado após mudanças e quando a TV está ligada há mais de 1 dia.'; OneShot = $true
        Risco = 'Baixo'; Sugerido = ($upH -ge 24); Estado = ("Ligada há {0}d {1}h" -f $dias, $horas); Editavel = $true })

    # tela inicial (launcher) -> aba própria
    $partes = $homes -split '@@atual'
    $homeAtual = $null
    foreach ($l in (Split-Linhas $partes[-1])) { if ($l.Trim() -match '^[\w\.]+/[\w\.\$]+$') { $homeAtual = $l.Trim() } }
    $instHome = [ordered]@{}
    foreach ($l in (Split-Linhas $partes[0])) {
        if ($l.Trim() -match '^([\w\.]+)/([\w\.\$]+)$') {
            $hp = $matches[1]
            if ($script:HomesSistema -notcontains $hp -and $hp -notlike 'com.tcl.*' -and -not $instHome.Contains($hp)) { $instHome[$hp] = $l.Trim() }
        }
    }
    $script:LauncherInfo = @{
        Atual            = $homeAtual
        GoogleDesativado = [bool]$desat[$script:LauncherGoogle]
        GoogleRamMB      = $(if ($pkgRam.ContainsKey($script:LauncherGoogle)) { $pkgRam[$script:LauncherGoogle] / 1024 } else { 0 })
        Instalados       = $instHome
    }
    Update-LauncherTab

    # pacotes do catálogo
    $vistos = @{}
    foreach ($c in $script:Catalogo) {
        $p = $c.P
        if (-not $instalados.ContainsKey($p)) { continue }
        $vistos[$p] = $true
        $prot = [bool]$c.X
        $cat = if ($prot) { 'Protegidos (não mexer)' } else { $c.C }
        $desc = if ($prot) { 'Essencial para a TV funcionar. Não pode ser alterado por aqui.' } else { $c.D }
        $itens.Add((New-PkgItem $p $c.N $cat $desc $(if ($prot) { '—' } else { $c.R }) ([bool]$c.S) $prot $prot $desat $pkgRam $cacheMap))
    }
    # apps instalados pelo usuário fora do catálogo
    foreach ($p in $terc) {
        if ($vistos[$p]) { continue }; $vistos[$p] = $true
        $itens.Add((New-PkgItem $p $p 'Apps instalados' 'App instalado pelo usuário.' 'Baixo' $false $false $false $desat $pkgRam $cacheMap))
    }
    # pacotes de sistema desconhecidos (avançado)
    foreach ($p in $sys) {
        if ($vistos[$p]) { continue }
        $itens.Add((New-PkgItem $p $p 'Outros pacotes do sistema' 'Sem descrição. Não mexa sem saber o que é.' 'Alto' $false $false $true $desat $pkgRam $cacheMap))
    }

    foreach ($it in $itens) {
        $it.CatOrdem = $script:CatOrdem[$it.Categoria]
        $it.Selecionado = if ($it.OneShot) { $it.Sugerido } else { $it.AplicadoAgora -or ($it.Sugerido -and $it.Editavel) }
        $it.add_PropertyChanged({ Update-Resumo })
    }
    $script:Itens = $itens
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itens)
    $view.GroupDescriptions.Clear(); $view.SortDescriptions.Clear()
    [void]$view.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription 'Categoria'))
    [void]$view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription 'CatOrdem', 'Ascending'))
    [void]$view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription 'JaAplicado', 'Ascending'))
    [void]$view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription 'Sugerido', 'Descending'))
    [void]$view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription 'Nome', 'Ascending'))
    $view.Filter = [Predicate[object]]{ param($o) $chkTodos.IsChecked -or -not $o.Avancado }
    $dgItens.ItemsSource = $view
    Update-Resumo

    # ================= processos
    $nomes = @{}; foreach ($c in $script:Catalogo) { $nomes[$c.P] = $c.N }
    $lista = @()
    $pidsPss = @{}
    foreach ($pr in $procs) {
        $pidsPss[$pr.Pid] = $true
        $lista += [pscustomobject]@{ Processo = $pr.Processo; Nome = $nomes[$pr.Base]; RamMB = [math]::Round($pr.RamKB / 1024, 1)
                                     Cpu = $(if ($cpuPid.ContainsKey($pr.Pid)) { $cpuPid[$pr.Pid] } else { 0.0 }) }
    }
    foreach ($c in $cpuLista) {
        if (-not $pidsPss[$c.Pid] -and $c.Cpu -ge 1) { $lista += [pscustomobject]@{ Processo = $c.Nome; Nome = '(kernel/nativo)'; RamMB = $null; Cpu = $c.Cpu } }
    }
    $dgProc.ItemsSource = @($lista | Sort-Object RamMB -Descending)

    # ================= relatório texto
    $sb = New-Object System.Text.StringBuilder
    $niv = @{ 0 = 'OK'; 1 = 'ATENÇÃO'; 2 = 'RUIM' }
    [void]$sb.AppendLine("TV Otimizador — diagnóstico de $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
    [void]$sb.AppendLine($txtDevice.Text)
    [void]$sb.AppendLine("Nota de saúde: $($txtScore.Text)/100 ($($txtScoreLabel.Text))")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('[{0,-7}] Memória livre ........ {1} MB de {2} MB ({3:N0}%) · CMA {4} MB' -f $niv[$n.ram], $availMB, $totMB, $availPct, $cmaMB))
    [void]$sb.AppendLine(('[{0,-7}] Swap (zram) .......... {1:N0}% em uso' -f $niv[$n.swap], $swPct))
    [void]$sb.AppendLine(('[{0,-7}] Reclaim direto ....... {1:N0}% (pgsteal_direct {2:N0} / kswapd {3:N0})' -f $niv[$n.trav], $directPct, $vm.direct, $vm.kswapd))
    [void]$sb.AppendLine(('[{0,-7}] Load average ......... {1:N2} em {2} núcleos' -f $niv[$n.load], $load1, $cores))
    [void]$sb.AppendLine(('[{0,-7}] CPU .................. {1:N0}%' -f $niv[$n.cpu], $cpuUso))
    [void]$sb.AppendLine(('[{0,-7}] Armazenamento ........ {1:N1} GB livres ({2:N0}%)' -f $niv[$n.disco], $dataFreeGB, $dataFreePct))
    [void]$sb.AppendLine(('[{0,-7}] Cache dos apps ....... {1}' -f $niv[$n.cache], (Fmt-MB $cacheTotMB)))
    [void]$sb.AppendLine(('[{0,-7}] Tempo ligada ......... {1}d {2}h · {3:N0} GB trocados com a swap' -f $niv[$n.up], $dias, $horas, $swapGB))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Maiores consumidores de RAM:')
    foreach ($pr in ($procs | Sort-Object RamKB -Descending | Select-Object -First 15)) {
        [void]$sb.AppendLine(('  {0,8:N0} MB  {1}' -f ($pr.RamKB / 1024), $pr.Processo))
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Maiores caches:')
    foreach ($kv in ($cacheMap.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10)) {
        [void]$sb.AppendLine(('  {0,8:N0} MB  {1}' -f $kv.Value, $kv.Key))
    }
    foreach ($k in $script:Raw.Keys) {
        [void]$sb.AppendLine(''); [void]$sb.AppendLine("==================== $k ====================")
        [void]$sb.AppendLine($script:Raw[$k])
    }
    $txtDiag.Text = $sb.ToString()
}

function New-PkgItem($p, $nome, $cat, $desc, $risco, $sug, $prot, $avanc, $desat, $pkgRam, $cacheMap) {
    $isDis = [bool]$desat[$p]
    $ramMB = if ($pkgRam.ContainsKey($p)) { $pkgRam[$p] / 1024 } else { 0 }
    $estado = if ($isDis) { 'Desativado' } elseif ($ramMB -gt 0) { 'Ativo · rodando' } else { 'Ativo' }
    $cache = if ($cacheMap.ContainsKey($p) -and $cacheMap[$p] -ge 1) { Fmt-MB $cacheMap[$p] } else { '' }
    [TvItemV2]@{ Tipo = 'pkg'; Id = $p; Nome = $nome; Categoria = $cat; Descricao = $desc; Risco = $risco
               Sugerido = ($sug -and -not $isDis); AplicadoAgora = $isDis; Estado = $estado
               Ram = $(if ($ramMB -gt 0) { '{0:N0} MB' -f $ramMB } else { '' }); Cache = $cache
               Editavel = (-not $prot); Avancado = $avanc }
}

function Get-Mudancas { @($script:Itens | Where-Object { $_.Acao -in 'Desativar', 'Reativar', 'Aplicar', 'Desfazer', 'Executar' }) }
function Update-Resumo {
    if (-not $script:Itens) { return }
    $m = Get-Mudancas
    $apl = @($script:Itens | Where-Object { $_.JaAplicado }).Count
    $sufixo = if ($apl) { "   ($apl já aplicados)" } else { '' }
    if (-not $m.Count) { $txtMudancas.Text = 'Nenhuma alteração selecionada.' + $sufixo; return }
    $g = $m | Group-Object Acao | ForEach-Object { '{0} {1}' -f $_.Count, $_.Name.ToLower() }
    $txtMudancas.Text = 'Alterações selecionadas: ' + ($g -join '  ·  ') + $sufixo
}

# ---------------------------------------------------------------- aba: tela inicial
function Get-NomeLauncher([string]$comp) {
    if (-not $comp) { return 'desconhecido' }
    $pk = ($comp -split '/')[0]
    if ($pk -eq $script:LauncherGoogle) { return 'Launcher do Google' }
    if ($script:LaunchersAlt.Contains($pk)) { return $script:LaunchersAlt[$pk] }
    return $pk
}
function New-Bloco([string]$titulo, [string]$sub, [string]$desc, $botoes, [string]$destaque = $null, $painel = $null) {
    if (-not $painel) { $painel = $pnlLauncher }
    $b = New-Object System.Windows.Controls.Border
    $b.Background = Get-Brush '#161C26'; $b.CornerRadius = 10; $b.Padding = '16,12'; $b.Margin = '0,0,0,10'
    if ($destaque) { $b.BorderBrush = Get-Brush $destaque; $b.BorderThickness = '2,0,0,0' }
    $dp = New-Object System.Windows.Controls.DockPanel
    $sb = New-Object System.Windows.Controls.StackPanel; $sb.Orientation = 'Horizontal'; $sb.VerticalAlignment = 'Center'
    [System.Windows.Controls.DockPanel]::SetDock($sb, 'Right')
    foreach ($bt in $botoes) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $bt.Texto; $btn.Tag = $bt.Tag; $btn.IsEnabled = ($bt.Tag -ne $null)
        $btn.Style = $win.FindResource($(if ($bt.Estilo) { $bt.Estilo } else { 'Btn' }))
        [void]$sb.Children.Add($btn)
    }
    [void]$dp.Children.Add($sb)
    $st = New-Object System.Windows.Controls.StackPanel
    $t1 = New-Object System.Windows.Controls.TextBlock; $t1.Text = $titulo; $t1.FontSize = 15; $t1.FontWeight = 'SemiBold'; $t1.Foreground = Get-Brush '#F2F4F8'
    [void]$st.Children.Add($t1)
    if ($sub) { $t2 = New-Object System.Windows.Controls.TextBlock; $t2.Text = $sub; $t2.Foreground = Get-Brush '#8A93A6'; $t2.FontSize = 12; $t2.Margin = '0,2,0,0'; [void]$st.Children.Add($t2) }
    if ($desc) { $t3 = New-Object System.Windows.Controls.TextBlock; $t3.Text = $desc; $t3.Foreground = Get-Brush '#C3CAD6'; $t3.TextWrapping = 'Wrap'; $t3.Margin = '0,6,16,0'; [void]$st.Children.Add($t3) }
    [void]$dp.Children.Add($st)
    $b.Child = $dp
    [void]$painel.Children.Add($b)
}
function Add-Titulo($painel, [string]$txt) {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $txt; $t.FontSize = 14; $t.FontWeight = 'Bold'; $t.Foreground = Get-Brush '#F2F4F8'; $t.Margin = '2,10,0,8'
    [void]$painel.Children.Add($t)
}
function Update-LauncherTab {
    $pnlLauncher.Children.Clear()
    $L = $script:LauncherInfo
    if (-not $L) { return }
    $nomeAtual = Get-NomeLauncher $L.Atual
    $usandoGoogle = (-not $L.GoogleDesativado)
    $ramTxt = if ($L.GoogleRamMB -gt 0) { '{0:N0} MB de RAM' -f $L.GoogleRamMB } else { 'não está carregado' }

    $sub = if ($usandoGoogle) { "O launcher do Google está ativo e usando $ramTxt." } else { 'O launcher do Google está desativado. A TV usa um launcher alternativo.' }
    $bt = if ($usandoGoogle) { @(@{ Texto = 'Em uso'; Tag = $null }) } else { @(@{ Texto = 'Voltar ao launcher do Google'; Tag = 'google'; Estilo = 'BtnWarn' }) }
    New-Bloco "Tela inicial atual: $nomeAtual" $sub ("No Android TV 11 o botão Home sempre abre o launcher do Google enquanto ele estiver ativo. " +
        "Para trocar de verdade, este app define o novo launcher como Home e desativa o do Google, o que libera RAM e acaba com os picos de CPU das recomendações. " +
        "Você perde a busca e as fileiras de recomendação da home do Google; apps, Play Store e configurações continuam funcionando.") $bt '#2F6FED'

    Add-Titulo $pnlLauncher 'Launchers alternativos'

    $mostrados = @{}
    foreach ($c in $script:LaunchersSugeridos) {
        $mostrados[$c.P] = $true
        if ($L.Instalados.Contains($c.P)) {
            $comp = $L.Instalados[$c.P]
            $emUso = (-not $usandoGoogle) -and ($L.Atual -eq $comp)
            if ($emUso) { New-Bloco $c.N 'Instalado · em uso' $c.D @(@{ Texto = '✓ Em uso'; Tag = $null }) '#3DDC84' }
            else { New-Bloco $c.N 'Instalado' $c.D @(@{ Texto = 'Usar como tela inicial'; Tag = "usar:$comp"; Estilo = 'BtnOk' }) }
        } else {
            New-Bloco $c.N 'Não instalado' $c.D @(@{ Texto = 'Instalar (abre a Play Store na TV)'; Tag = "play:$($c.P)"; Estilo = 'BtnPrim' })
        }
    }
    foreach ($k in $L.Instalados.Keys) {
        if ($mostrados[$k]) { continue }
        $comp = $L.Instalados[$k]
        $emUso = (-not $usandoGoogle) -and ($L.Atual -eq $comp)
        $nm = Get-NomeLauncher $comp
        if ($emUso) { New-Bloco $nm 'Instalado · em uso' $comp @(@{ Texto = '✓ Em uso'; Tag = $null }) '#3DDC84' }
        else { New-Bloco $nm 'Instalado' $comp @(@{ Texto = 'Usar como tela inicial'; Tag = "usar:$comp"; Estilo = 'BtnOk' }) }
    }
}
function Invoke-LauncherAcao([string]$tag) {
    if (-not $tag) { return }
    $hist = Get-Hist
    if ($tag -like 'play:*') {
        $pk = $tag.Substring(5)
        Set-Busy $true 'Abrindo a Play Store na TV...'
        try {
            if (-not @(Connect-Tv)[-1]) { throw 'TV sem conexão.' }
            Invoke-Tv "am start -a android.intent.action.VIEW -d market://details?id=$pk" | Out-Null
            Log "Play Store aberta na TV: $pk"
        } catch { Show-Msg $_.Exception.Message 'Erro' 'Error'; return } finally { Set-Busy $false }
        Open-TelaWindow
        Set-Status 'Play Store aberta na TV. Instale pelo controle (ou pela aba "Tela da TV") e depois clique em "Conectar e analisar".'
        return
    }
    if ($tag -like 'usar:*') {
        $comp = $tag.Substring(5)
        $nm = Get-NomeLauncher $comp
        $r = [System.Windows.MessageBox]::Show($win, "Usar o $nm como tela inicial e desativar o launcher do Google?`n`nDá para voltar a qualquer momento com 'Voltar ao launcher do Google' ou 'Reverter tudo'.", 'Trocar launcher', 'YesNo', 'Question')
        if ($r -ne 'Yes') { return }
        Set-Busy $true "Trocando para o $nm..."
        try {
            if (-not @(Connect-Tv)[-1]) { throw 'TV sem conexão.' }
            Log ("Home -> ${comp}: " + (Invoke-Tv "cmd package set-home-activity $comp").Trim())
            $o = (Invoke-Tv "pm disable-user --user 0 $($script:LauncherGoogle)").Trim()
            Log "Desativar launcher do Google: $o"
            Invoke-Tv 'am start -a android.intent.action.MAIN -c android.intent.category.HOME' | Out-Null
            if ($o -match 'disabled') { $hist.launcher = $comp; Save-Hist $hist }
        } catch { Log "ERRO: $($_.Exception.Message)"; Show-Msg $_.Exception.Message 'Erro' 'Error' } finally { Set-Busy $false }
        Start-Analise
        return
    }
    if ($tag -eq 'google') {
        $r = [System.Windows.MessageBox]::Show($win, 'Reativar o launcher do Google e voltar a usá-lo como tela inicial?', 'Restaurar launcher', 'YesNo', 'Question')
        if ($r -ne 'Yes') { return }
        Set-Busy $true 'Restaurando o launcher do Google...'
        try {
            if (-not @(Connect-Tv)[-1]) { throw 'TV sem conexão.' }
            Log ('Reativar launcher do Google: ' + (Invoke-Tv "pm enable $($script:LauncherGoogle)").Trim())
            Log ('Home -> launcher do Google: ' + (Invoke-Tv "cmd package set-home-activity $($script:LauncherGoogleComp)").Trim())
            Invoke-Tv 'am start -a android.intent.action.MAIN -c android.intent.category.HOME' | Out-Null
            $hist.launcher = ''; Save-Hist $hist
        } catch { Log "ERRO: $($_.Exception.Message)"; Show-Msg $_.Exception.Message 'Erro' 'Error' } finally { Set-Busy $false }
        Start-Analise
    }
}

# ---------------------------------------------------------------- aba: tela da TV
function Invoke-AdbBytes([string]$argumentos, [int]$timeoutSec = 20) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:AdbExe; $psi.Arguments = $argumentos
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
    $p = [Diagnostics.Process]::Start($psi)
    $ms = New-Object System.IO.MemoryStream
    $cp = $p.StandardOutput.BaseStream.CopyToAsync($ms)
    $err = $p.StandardError.ReadToEndAsync()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not $cp.IsCompleted) {
        DoEvents; Start-Sleep -Milliseconds 15
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { try { $p.Kill() } catch {} ; break }
    }
    while (-not $err.IsCompleted) { DoEvents; Start-Sleep -Milliseconds 10 }
    return , $ms.ToArray()
}
$script:Capturando = $false
$script:RefreshPendente = $false
function Update-Tela {
    if (-not $script:AdbExe -or -not $script:TelaWin) { return }
    if ($script:Capturando) { $script:RefreshPendente = $true; return }
    $script:Capturando = $true
    try {
        do {
            $script:RefreshPendente = $false
            if (-not $script:Alvo -or (Invoke-Adb "-s $($script:Alvo) get-state" 5).Trim() -ne 'device') {
                $txtTelaInfo.Text = 'Conectando...'
                if (-not @(Connect-Tv)[-1]) { $txtTelaInfo.Text = 'TV sem conexão. Verifique o IP e se a TV está ligada.'; return }
            }
            $sw = [Diagnostics.Stopwatch]::StartNew()
            $bytes = Invoke-AdbBytes "-s $($script:Alvo) exec-out screencap -p" 20
            if ($bytes.Length -lt 100 -or $bytes[0] -ne 0x89 -or $bytes[1] -ne 0x50) {
                $txtTelaInfo.Text = 'Não foi possível capturar a tela (a TV pode estar em standby).'
                return
            }
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.StreamSource = New-Object System.IO.MemoryStream(, $bytes)
            $bmp.DecodePixelWidth = 1280
            $bmp.EndInit(); $bmp.Freeze()
            $imgTela.Source = $bmp
            $txtTelaVazia.Visibility = 'Collapsed'
            $txtTelaInfo.Text = ('Atualizada às {0} · {1:N0} KB · {2:N1} s' -f (Get-Date -Format 'HH:mm:ss'), ($bytes.Length / 1KB), $sw.Elapsed.TotalSeconds)
        } while ($script:RefreshPendente)
    } catch {
        $txtTelaInfo.Text = "Erro na captura: $($_.Exception.Message)"
    } finally { $script:Capturando = $false }
}
function Send-Tecla([string]$codigo) {
    if (-not $script:Alvo) { if (-not @(Connect-Tv)[-1]) { return } }
    Invoke-Tv "input keyevent $codigo" 10 | Out-Null
    Wait-UI 350
    Update-Tela
}
function Send-Comando([string]$cmd) {
    if (-not $script:Alvo) { if (-not @(Connect-Tv)[-1]) { return } }
    switch ($cmd) {
        'settings' { Invoke-Tv 'am start -a android.settings.SETTINGS' | Out-Null }
        'apps'     { Invoke-Tv 'am start -a android.settings.APPLICATION_SETTINGS' | Out-Null }
    }
    Wait-UI 800
    Update-Tela
}
function Send-Texto {
    $t = $txtEnviar.Text
    if (-not $t) { return }
    $t = ($t -replace '["''`\\$]', '') -replace ' ', '%s'
    Invoke-Tv "input text '$t'" 15 | Out-Null
    $txtEnviar.Text = ''
    Wait-UI 300
    Update-Tela
}
function Open-Scrcpy {
    if (-not $script:ScrcpyExe) {
        $r = [System.Windows.MessageBox]::Show("O scrcpy não está instalado.`n`nEle mostra a tela da TV ao vivo e permite controlar com mouse e teclado (gratuito, código aberto).`n`nBaixar e instalar agora?", 'scrcpy', 'YesNo', 'Question')
        if ($r -ne 'Yes') { return }
        if (-not (Install-Dep 'scrcpy')) { return }
    }
    if (-not $script:Alvo) { if (-not @(Connect-Tv)[-1]) { Show-Msg 'TV sem conexão.'; return } }
    if ($chkTelaAuto) { $chkTelaAuto.IsChecked = $false; $script:TimerTela.Stop() }
    $env:ADB = $script:AdbExe     # usa o mesmo adb deste app (evita conflito de versões)
    Start-Process -FilePath $script:ScrcpyExe -WorkingDirectory (Split-Path $script:ScrcpyExe) -ArgumentList @('-s', $script:Alvo, '--max-size', '1280', '--video-bit-rate', '4M', '--no-audio', '--window-title', 'TV')
    Log "scrcpy aberto: $($script:ScrcpyExe)"
}

# ---------------------------------------------------------------- janela "Tela da TV"
$script:TelaWin = $null
$script:TimerTela = New-Object System.Windows.Threading.DispatcherTimer
$script:TimerTela.Interval = [TimeSpan]::FromMilliseconds(1500)
$script:TimerTela.Add_Tick({
    if (-not $script:TelaWin -or $pb.IsIndeterminate -or $script:Capturando) { return }
    Update-Tela
})
function Open-TelaWindow {
    if (-not $script:AdbExe) { $tabs.SelectedItem = $tabConfig; Show-Msg 'Instale o ADB na aba Configurações primeiro.'; return }
    if (-not $txtIp.Text.Trim()) { Show-Msg 'Informe o IP da TV.'; return }
    if ($script:TelaWin) { $script:TelaWin.Activate() | Out-Null; return }
    $w = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$script:TelaXaml.Replace('__ESTILOS__', $script:EstilosXaml))))
    foreach ($n in 'imgTela','txtTelaVazia','btnTelaAtualizar','chkTelaAuto','txtTelaInfo','btnEnviarTexto','txtEnviar','btnScrcpy') {
        Set-Variable -Name $n -Value $w.FindName($n) -Scope Script
    }
    if ($script:LogoIcon) { $w.Icon = $script:LogoIcon }
    $w.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
        param($sender, $e)
        $b = $e.OriginalSource
        if ($b -isnot [System.Windows.Controls.Button]) { return }
        $tag = [string]$b.Tag
        if ($tag -like 'key:*') { $e.Handled = $true; Send-Tecla $tag.Substring(4) }
        elseif ($tag -like 'cmd:*') { $e.Handled = $true; Send-Comando $tag.Substring(4) }
    })
    $btnTelaAtualizar.Add_Click({ Update-Tela })
    $btnEnviarTexto.Add_Click({ Send-Texto })
    $txtEnviar.Add_KeyDown({ if ($_.Key -eq 'Return') { Send-Texto; $_.Handled = $true } })
    $btnScrcpy.Add_Click({ Open-Scrcpy })
    $chkTelaAuto.Add_Click({ if ($chkTelaAuto.IsChecked) { $script:TimerTela.Start(); Update-Tela } else { $script:TimerTela.Stop() } })
    $w.Add_PreviewKeyDown({
        param($sender, $e)
        if ($e.OriginalSource -is [System.Windows.Controls.TextBox]) { return }
        $mapa = @{ 'Up' = 19; 'Down' = 20; 'Left' = 21; 'Right' = 22; 'Return' = 23; 'Escape' = 4; 'Back' = 4; 'Home' = 3; 'PageUp' = 24; 'PageDown' = 25; 'Space' = 85 }
        $k = $e.Key.ToString()
        if ($mapa.ContainsKey($k)) { $e.Handled = $true; Send-Tecla ([string]$mapa[$k]) }
    })
    $w.Add_Closed({ $script:TimerTela.Stop(); $script:TelaWin = $null })
    $script:TelaWin = $w
    $w.Show()
    Update-Tela
    if ($chkTelaAuto.IsChecked) { $script:TimerTela.Start() }
}

# ---------------------------------------------------------------- aba: configurações
function Install-Dep([string]$qual) {
    $nome = if ($qual -eq 'adb') { 'ADB (Android Platform Tools)' } else { 'scrcpy' }
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    $fb.Description = "Escolha a pasta onde instalar o $nome. Será criada uma subpasta dentro dela."
    $fb.ShowNewFolderButton = $true
    $fb.SelectedPath = $(if ($PSScriptRoot) { $PSScriptRoot } else { [Environment]::GetFolderPath('MyDocuments') })
    if ($fb.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $false }
    $dest = $fb.SelectedPath
    $tmp = $null; $ok = $false
    Set-Busy $true "Preparando o download do $nome..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $total = 0; $ver = ''
        if ($qual -eq 'adb') {
            $url = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
        } else {
            $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/Genymobile/scrcpy/releases/latest' -Headers @{ 'User-Agent' = 'TV-Otimizador' }
            $asset = $rel.assets | Where-Object { $_.name -like 'scrcpy-win64-*.zip' } | Select-Object -First 1
            if (-not $asset) { throw 'Não encontrei o pacote do scrcpy para Windows 64 bits na última versão.' }
            $url = $asset.browser_download_url; $total = [double]$asset.size; $ver = $rel.tag_name
        }
        $tmp = Join-Path $env:TEMP ('tvotm_' + [IO.Path]::GetFileName($url))
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', 'TV-Otimizador')
        $task = $wc.DownloadFileTaskAsync($url, $tmp)
        $pb.IsIndeterminate = ($total -le 0)
        while (-not $task.IsCompleted) {
            DoEvents; Start-Sleep -Milliseconds 120
            $mb = if (Test-Path $tmp) { (Get-Item $tmp).Length / 1MB } else { 0 }
            if ($total -gt 0) { $pb.Value = [math]::Min(100, $mb * 1MB / $total * 100); $txtStatus.Text = ('Baixando {0} {1}... {2:N1} de {3:N1} MB' -f $nome, $ver, $mb, ($total / 1MB)) }
            else { $txtStatus.Text = ('Baixando {0}... {1:N1} MB' -f $nome, $mb) }
        }
        if ($task.IsFaulted) { throw $task.Exception.InnerException }
        $pb.IsIndeterminate = $true
        Set-Status "Descompactando em $dest..."
        if ($qual -eq 'adb' -and $script:AdbExe) { try { Invoke-Exe $script:AdbExe 'kill-server' 10 | Out-Null } catch {} }
        Expand-Archive -Path $tmp -DestinationPath $dest -Force
        $alvoExe = if ($qual -eq 'adb') { 'adb.exe' } else { 'scrcpy.exe' }
        $achado = Get-ChildItem -Path $dest -Filter $alvoExe -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($qual -eq 'adb') { $p = Join-Path $dest 'platform-tools\adb.exe'; if (Test-Path $p) { $achado = Get-Item $p } }
        else { $d = Get-ChildItem -Path $dest -Directory -Filter "scrcpy-win64-$ver" -ErrorAction SilentlyContinue | Select-Object -First 1
               if ($d -and (Test-Path (Join-Path $d.FullName 'scrcpy.exe'))) { $achado = Get-Item (Join-Path $d.FullName 'scrcpy.exe') } }
        if (-not $achado) { throw "Descompactei, mas não encontrei o $alvoExe em $dest." }
        if ($qual -eq 'adb') { $script:Cfg.adbPath = $achado.FullName } else { $script:Cfg.scrcpyPath = $achado.FullName }
        Save-Config
        Find-Deps
        Log "$nome instalado em $($achado.FullName)"
        Set-Status "$nome instalado em $($achado.DirectoryName)"
        $ok = $true
    } catch {
        Log "ERRO ao instalar $($nome): $($_.Exception.Message)"
        Show-Msg "Não foi possível instalar o $($nome):`n`n$($_.Exception.Message)`n`nVerifique a internet e se você tem permissão para gravar em $dest." 'Erro' 'Error'
    } finally {
        if ($tmp -and (Test-Path $tmp)) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        Set-Busy $false
        Update-ConfigTab
    }
    if ($ok) { Show-Msg "$nome instalado com sucesso.`n`n$($script:Cfg[$(if ($qual -eq 'adb') { 'adbPath' } else { 'scrcpyPath' })])" }
    return $ok
}
function Select-Dep([string]$qual) {
    $alvoExe = if ($qual -eq 'adb') { 'adb.exe' } else { 'scrcpy.exe' }
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "$alvoExe|$alvoExe"; $dlg.Title = "Localize o $alvoExe"
    if ($dlg.ShowDialog($win)) {
        if ($qual -eq 'adb') { $script:Cfg.adbPath = $dlg.FileName } else { $script:Cfg.scrcpyPath = $dlg.FileName }
        Save-Config; Find-Deps; Update-ConfigTab
    }
}
function Add-Sobre {
    $b = New-Object System.Windows.Controls.Border
    $b.Background = Get-Brush '#161C26'; $b.CornerRadius = 10; $b.Padding = '18,16'; $b.Margin = '0,0,0,10'
    $g = New-Object System.Windows.Controls.StackPanel; $g.Orientation = 'Horizontal'
    $logo = New-Logo 84; $logo.VerticalAlignment = 'Top'
    [void]$g.Children.Add($logo)
    $st = New-Object System.Windows.Controls.StackPanel; $st.Margin = '18,0,0,0'
    $t = New-Object System.Windows.Controls.TextBlock; $t.Text = $script:AppNome; $t.FontSize = 20; $t.FontWeight = 'Bold'; $t.Foreground = Get-Brush '#FFFFFF'
    [void]$st.Children.Add($t)
    $v = New-Object System.Windows.Controls.TextBlock; $v.Text = "Versão $($script:AppVersion)  ·  build $($script:AppBuild)"; $v.Foreground = Get-Brush '#5B8DEF'; $v.Margin = '0,2,0,10'
    [void]$st.Children.Add($v)
    $linhas = @(
        @{ T = 'Desenvolvido por '; L = $script:AppAutor; U = $null }
        @{ T = 'E-mail: '; L = $script:AppEmail; U = "mailto:$($script:AppEmail)" }
        @{ T = 'GitHub: '; L = 'github.com/ajcorrea'; U = $script:AppGitHub }
        @{ T = 'Projeto: '; L = ($script:AppRepo -replace '^https://', ''); U = $script:AppRepo }
    )
    foreach ($l in $linhas) {
        $tb = New-Object System.Windows.Controls.TextBlock; $tb.Foreground = Get-Brush '#C3CAD6'; $tb.Margin = '0,1,0,1'
        [void]$tb.Inlines.Add($l.T)
        if ($l.U) {
            $h = New-Object System.Windows.Documents.Hyperlink
            [void]$h.Inlines.Add($l.L)
            $h.NavigateUri = [Uri]$l.U
            $h.Foreground = Get-Brush '#64B5F6'
            $h.Add_RequestNavigate({ param($s2, $e2) Start-Process $e2.Uri.AbsoluteUri; $e2.Handled = $true })
            [void]$tb.Inlines.Add($h)
        } else {
            $r = New-Object System.Windows.Documents.Run($l.L); $r.FontWeight = 'SemiBold'; $r.Foreground = Get-Brush '#FFFFFF'
            [void]$tb.Inlines.Add($r)
        }
        [void]$st.Children.Add($tb)
    }
    $lic = New-Object System.Windows.Controls.TextBlock
    $lic.Text = 'Software livre sob a licença MIT: use, modifique e compartilhe à vontade. Contribuições são bem-vindas no GitHub.'
    $lic.Foreground = Get-Brush '#8A93A6'; $lic.TextWrapping = 'Wrap'; $lic.Margin = '0,10,0,0'; $lic.FontSize = 12
    [void]$st.Children.Add($lic)
    [void]$g.Children.Add($st)
    $b.Child = $g
    [void]$pnlConfig.Children.Add($b)
}
function Update-ConfigTab {
    $pnlConfig.Children.Clear()
    Add-Titulo $pnlConfig 'Ferramentas necessárias'
    if ($script:AdbExe) {
        $v = Get-ExeVersao $script:AdbExe 'version'
        New-Bloco 'ADB (Android Platform Tools)' "Instalado  ·  $v" ("Pasta: $(Split-Path $script:AdbExe)`nObrigatório: é por ele que o app conversa com a TV pela rede.") @(
            @{ Texto = 'Abrir pasta'; Tag = 'dep:adb:pasta' }, @{ Texto = 'Localizar...'; Tag = 'dep:adb:localizar' }, @{ Texto = 'Atualizar'; Tag = 'dep:adb:instalar'; Estilo = 'BtnPrim' }) '#3DDC84' $pnlConfig
    } else {
        New-Bloco 'ADB (Android Platform Tools)' 'Não encontrado' 'Obrigatório: é por ele que o app conversa com a TV pela rede. O download é feito direto do site do Google (~7 MB).' @(
            @{ Texto = 'Localizar...'; Tag = 'dep:adb:localizar' }, @{ Texto = 'Baixar e instalar'; Tag = 'dep:adb:instalar'; Estilo = 'BtnOk' }) '#FFB020' $pnlConfig
    }
    if ($script:ScrcpyExe) {
        $v = Get-ExeVersao $script:ScrcpyExe '--version'
        New-Bloco 'scrcpy (tela ao vivo)' "Instalado  ·  $v" ("Pasta: $(Split-Path $script:ScrcpyExe)`nOpcional: mostra a tela da TV ao vivo e permite controlar com mouse e teclado.") @(
            @{ Texto = 'Abrir pasta'; Tag = 'dep:scrcpy:pasta' }, @{ Texto = 'Localizar...'; Tag = 'dep:scrcpy:localizar' }, @{ Texto = 'Atualizar'; Tag = 'dep:scrcpy:instalar'; Estilo = 'BtnPrim' }) '#3DDC84' $pnlConfig
    } else {
        New-Bloco 'scrcpy (tela ao vivo)' 'Não encontrado' 'Opcional: mostra a tela da TV ao vivo e permite controlar com mouse e teclado. O download é feito da página oficial do projeto no GitHub (~40 MB).' @(
            @{ Texto = 'Localizar...'; Tag = 'dep:scrcpy:localizar' }, @{ Texto = 'Baixar e instalar'; Tag = 'dep:scrcpy:instalar'; Estilo = 'BtnOk' }) '#5B8DEF' $pnlConfig
    }
    Add-Titulo $pnlConfig 'Dados do app'
    New-Bloco 'Configurações e histórico' $script:CfgDir 'Guarda o IP da TV, os caminhos das ferramentas e o histórico do que este app alterou na TV (usado pelo "Reverter tudo").' @(
        @{ Texto = 'Abrir pasta'; Tag = 'cfg:pasta' }) $null $pnlConfig
    Add-Titulo $pnlConfig 'Sobre'
    Add-Sobre
}
function Invoke-ConfigAcao([string]$tag) {
    if (-not $tag) { return }
    $p = $tag -split ':'
    switch ($p[0]) {
        'dep' {
            $exe = if ($p[1] -eq 'adb') { $script:AdbExe } else { $script:ScrcpyExe }
            switch ($p[2]) {
                'instalar'  { Install-Dep $p[1] | Out-Null }
                'localizar' { Select-Dep $p[1] }
                'pasta'     { if ($exe) { Start-Process explorer.exe (Split-Path $exe) } }
            }
        }
        'cfg' { if (-not (Test-Path $script:CfgDir)) { New-Item -ItemType Directory -Path $script:CfgDir -Force | Out-Null }; Start-Process explorer.exe $script:CfgDir }
    }
}

# ---------------------------------------------------------------- aplicar / reverter
# executa UMA ação na TV e atualiza o histórico. $acao: Desativar | Reativar | Aplicar | Desfazer | Executar
function Invoke-Acao($it, [string]$acao, $hist) {
    $desfaz = $acao -in 'Reativar', 'Desfazer'
    if ($it.Tipo -eq 'pkg') {
        if (-not $desfaz) {
            $o = (Invoke-Tv "pm disable-user --user 0 $($it.Id)").Trim()
            Log "Desativar $($it.Id): $o"
            if ($o -match 'disabled') { $hist.pacotes = @(@($hist.pacotes) + $it.Id | Select-Object -Unique); return $true }
            return $false
        }
        $o = (Invoke-Tv "pm enable $($it.Id)").Trim()
        Log "Reativar $($it.Id): $o"
        $hist.pacotes = @($hist.pacotes | Where-Object { $_ -ne $it.Id })
        return ($o -match 'enabled')
    }
    switch ($it.Id) {
        'cacheproc' {
            if (-not $desfaz) { Invoke-Tv 'settings put global activity_manager_constants max_cached_processes=10' | Out-Null; $hist.cacheproc = $true; Log 'Limite de processos em cache: 10' }
            else { Invoke-Tv 'settings delete global activity_manager_constants' | Out-Null; $hist.cacheproc = $false; Log 'Limite de processos em cache: padrão' }
        }
        'anim' {
            $v = if (-not $desfaz) { '0.5' } else { '1.0' }
            Invoke-Tv "settings put global window_animation_scale $v; settings put global transition_animation_scale $v; settings put global animator_duration_scale $v" | Out-Null
            $hist.anim = ($v -eq '0.5'); Log "Animações: ${v}x"
        }
        'launcher' {
            if (-not $desfaz) {
                if (-not $script:AltLauncher) { Log 'Nenhum launcher alternativo encontrado.'; return $false }
                Log ('Home -> ' + $script:AltLauncher + ': ' + (Invoke-Tv "cmd package set-home-activity $($script:AltLauncher)").Trim())
                $o = (Invoke-Tv "pm disable-user --user 0 $($script:LauncherGoogle)").Trim()
                Log "Desativar launcher do Google: $o"
                Invoke-Tv 'am start -a android.intent.action.MAIN -c android.intent.category.HOME' | Out-Null
                $hist.launcher = $script:AltLauncher
                return ($o -match 'disabled')
            } else {
                $o = (Invoke-Tv "pm enable $($script:LauncherGoogle)").Trim()
                Log "Reativar launcher do Google: $o"
                Log ('Home -> launcher do Google: ' + (Invoke-Tv "cmd package set-home-activity $($script:LauncherGoogleComp)").Trim())
                Invoke-Tv 'am start -a android.intent.action.MAIN -c android.intent.category.HOME' | Out-Null
                $hist.launcher = ''
                return ($o -match 'enabled')
            }
        }
        'playstore' { Invoke-Tv 'am start -a android.intent.action.VIEW -d market://details?id=com.spocky.projengmenu' | Out-Null; Log 'Play Store aberta na TV (Projectivy Launcher).' }
        'trim' { Set-Status 'Limpando caches...'; Invoke-Tv 'pm trim-caches 64G' 120 | Out-Null; Log 'Cache dos apps limpo.' }
    }
    return $true
}

# botão "Restaurar" de um item já aplicado: desfaz só ele, na hora
function Invoke-Restaurar($it) {
    if (-not $it -or -not $it.JaAplicado) { return }
    $r = [System.Windows.MessageBox]::Show($win, "Restaurar '$($it.Nome)' na TV agora?", 'Restaurar', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }
    Set-Busy $true "Restaurando $($it.Nome)..."
    try {
        $hist = Get-Hist
        $acao = if ($it.Tipo -eq 'pkg') { 'Reativar' } else { 'Desfazer' }
        $ok = @(Invoke-Acao $it $acao $hist)[-1]
        Save-Hist $hist
        if ($ok -ne $false) {
            $it.AplicadoAgora = $false
            $it.Selecionado = $false
            $it.Estado = 'Restaurado'
            Set-Status "'$($it.Nome)' restaurado."
        } else {
            Set-Status "Não foi possível restaurar '$($it.Nome)'. Veja a aba Log."
        }
    } catch { Log "ERRO: $($_.Exception.Message)"; Show-Msg $_.Exception.Message 'Erro' 'Error' }
    finally { Set-Busy $false; Update-Resumo }
}
function Invoke-Aplicar {
    if (-not $script:Itens) { Show-Msg 'Faça a análise primeiro.'; return }
    $m = Get-Mudancas
    if (-not $m.Count) { Show-Msg 'Nenhuma alteração selecionada.'; return }
    $txt = ($m | ForEach-Object { '• {0}: {1}' -f $_.Acao, $_.Nome }) -join "`n"
    $r = [System.Windows.MessageBox]::Show($win, "Aplicar estas alterações na TV?`n`n$txt`n`nTudo pode ser desfeito depois com 'Reverter tudo'.", 'Confirmar', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }

    Set-Busy $true 'Aplicando...'
    $hist = Get-Hist
    $reboot = $false
    try {
        $ordem = @($m | Where-Object { $_.Tipo -eq 'pkg' }) + @($m | Where-Object { $_.Tipo -eq 'tweak' -and $_.Id -ne 'reboot' })
        foreach ($it in $ordem) { Invoke-Acao $it $it.Acao $hist | Out-Null }
        if ($m | Where-Object { $_.Id -eq 'reboot' }) { $reboot = $true }
        Save-Hist $hist
        if ($reboot) {
            Log 'Reiniciando a TV...'
            Invoke-Adb "-s $($script:Alvo) reboot" 20 | Out-Null
            Set-Status 'TV reiniciando. Aguarde ~1 minuto e clique em "Conectar e analisar" para ver o resultado.'
            Show-Msg 'Alterações aplicadas. A TV está reiniciando; em ~1 minuto clique em "Conectar e analisar".'
            return
        }
    } catch {
        Log "ERRO: $($_.Exception.Message)"; Show-Msg $_.Exception.Message 'Erro' 'Error'
    } finally { Set-Busy $false }
    if (-not $reboot) { Start-Analise }
}

function Invoke-Reverter {
    $hist = Get-Hist
    if (-not $hist.pacotes.Count -and -not $hist.cacheproc -and -not $hist.anim -and -not $hist.launcher) { Show-Msg 'Não há alterações feitas por este app para reverter.'; return }
    if (-not $script:Alvo) { $script:Alvo = '{0}:{1}' -f $txtIp.Text.Trim(), $txtPorta.Text.Trim() }
    $lst = @($hist.pacotes) -join "`n"
    $r = [System.Windows.MessageBox]::Show($win, "Reativar tudo o que este app desativou e voltar os ajustes ao padrão?`n`n$lst", 'Reverter tudo', 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    Set-Busy $true 'Revertendo...'
    try {
        Invoke-Adb "connect $($script:Alvo)" 10 | Out-Null
        foreach ($p in $hist.pacotes) { Log ("Reativar ${p}: " + (Invoke-Tv "pm enable $p").Trim()) }
        if ($hist.cacheproc) { Invoke-Tv 'settings delete global activity_manager_constants' | Out-Null; Log 'Limite de processos: padrão' }
        if ($hist.launcher) {
            Log ('Reativar launcher do Google: ' + (Invoke-Tv "pm enable $($script:LauncherGoogle)").Trim())
            Invoke-Tv "cmd package set-home-activity $($script:LauncherGoogleComp)" | Out-Null
        }
        if ($hist.anim) { Invoke-Tv 'settings put global window_animation_scale 1.0; settings put global transition_animation_scale 1.0; settings put global animator_duration_scale 1.0' | Out-Null; Log 'Animações: 1x' }
        Save-Hist @{ pacotes = @(); cacheproc = $false; anim = $false; launcher = '' }
    } catch { Log "ERRO: $($_.Exception.Message)"; Show-Msg $_.Exception.Message 'Erro' 'Error' }
    finally { Set-Busy $false }
    Start-Analise
}

function Invoke-Exportar {
    if (-not $txtDiag.Text) { Show-Msg 'Faça a análise primeiro.'; return }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'diagnostico-tv_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmm')
    $dlg.Filter = 'Texto (*.txt)|*.txt'
    if ($dlg.ShowDialog($win)) {
        ($txtDiag.Text + "`r`n`r`n==================== LOG ====================`r`n" + $txtLog.Text) | Set-Content -Path $dlg.FileName -Encoding UTF8
        Set-Status "Relatório salvo em $($dlg.FileName)"
    }
}

# ---------------------------------------------------------------- eventos
$btnAnalisar.Add_Click({ Start-Analise })
$btnAplicar.Add_Click({ Invoke-Aplicar })
$btnReverter.Add_Click({ Invoke-Reverter })
$btnExportar.Add_Click({ Invoke-Exportar })
$btnSugeridos.Add_Click({
    foreach ($it in $script:Itens) { if ($it.Editavel) { $it.Selecionado = if ($it.OneShot) { $it.Sugerido } else { $it.AplicadoAgora -or $it.Sugerido } } }
})
$btnEstadoAtual.Add_Click({
    foreach ($it in $script:Itens) { if ($it.Editavel) { $it.Selecionado = if ($it.OneShot) { $false } else { $it.AplicadoAgora } } }
})
$dgItens.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button] -and $b.Tag -eq 'restaurar') { $e.Handled = $true; Invoke-Restaurar $b.DataContext }
})
$pnlLauncher.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button]) { $e.Handled = $true; Invoke-LauncherAcao ([string]$b.Tag) }
})
$pnlConfig.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button]) { $e.Handled = $true; Invoke-ConfigAcao ([string]$b.Tag) }
})
$btnTela.Add_Click({ Open-TelaWindow })
$win.Add_Closing({
    $script:TimerTela.Stop()
    if ($script:TelaWin) { $script:TelaWin.Close() }
    if ($txtIp.Text.Trim()) { $script:Cfg.ip = $txtIp.Text.Trim(); $script:Cfg.porta = $txtPorta.Text.Trim() }
    Save-Config
})
$chkTodos.Add_Click({ if ($dgItens.ItemsSource) { $dgItens.ItemsSource.Refresh() } })
$txtIp.Add_KeyDown({ if ($_.Key -eq 'Return') { Start-Analise } })

# ---------------------------------------------------------------- inicialização
Set-Splash 'Verificando ferramentas (ADB e scrcpy)...'
Find-Deps
$txtVersao.Text = "v$($script:AppVersion)  ·  build $($script:AppBuild)  ·  por $($script:AppAutor)"
$logoHeader.Content = New-Logo 54
if ($script:LogoIcon) { $win.Icon = $script:LogoIcon }
$txtIp.Text = $script:Cfg.ip
if ($script:Cfg.porta) { $txtPorta.Text = $script:Cfg.porta }
Set-Splash 'Preparando configurações...'
Update-ConfigTab
if ($script:AdbExe) { Log "adb: $($script:AdbExe)" } else { Log 'adb não encontrado.' }
if ($script:ScrcpyExe) { Log "scrcpy: $($script:ScrcpyExe)" }
Set-Splash $(if ($script:AdbExe) { 'Pronto.' } else { 'ADB não encontrado: instale pela aba Configurações.' })
while ($script:SplashSw.ElapsedMilliseconds -lt 2200) { DoEvents; Start-Sleep -Milliseconds 30 }
$script:Splash.Close(); $script:Splash = $null

$win.Add_ContentRendered({
    if (-not $script:AdbExe) {
        $tabs.SelectedItem = $tabConfig
        $txtStatus.Text = 'Primeiro uso: instale o ADB clicando em "Baixar e instalar".'
    } elseif (-not $txtIp.Text) {
        $txtIp.Focus() | Out-Null
        $txtStatus.Text = 'Informe o IP da TV (Configurações da TV > Rede > Status) e clique em "Conectar e analisar".'
    }
})
[void]$win.ShowDialog()
