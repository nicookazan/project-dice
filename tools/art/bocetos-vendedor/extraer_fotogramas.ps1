# Extrae fotogramas (PNG de 1280×720) del video del autor con el reproductor de Windows (no necesita ffmpeg).
# Uso:  powershell -STA -NoProfile -File extraer_fotogramas.ps1 <video.mp4> <carpeta de salida> [cantidad=40]
# Los cuadros quedan equiespaciados en la duración del video (f00.png … fNN.png).
Add-Type -AssemblyName PresentationCore,WindowsBase
$video = $args[0]; $sp = $args[1]; $n = if ($args.Count -gt 2) { [int]$args[2] } else { 40 }
New-Item -ItemType Directory -Force $sp | Out-Null
function Pump($ms){ $end=[DateTime]::Now.AddMilliseconds($ms); while([DateTime]::Now -lt $end){ [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background); Start-Sleep -Milliseconds 10 } }
$mp = New-Object System.Windows.Media.MediaPlayer
$mp.ScrubbingEnabled = $true
$mp.Open([Uri]$video)
Pump 1500
$dur = $mp.NaturalDuration.TimeSpan.TotalSeconds
$w = $mp.NaturalVideoWidth; $h = $mp.NaturalVideoHeight
for ($i = 0; $i -lt $n; $i++) {
  $mp.Position = [TimeSpan]::FromSeconds($dur * $i / $n)
  Pump 500
  $dv = New-Object System.Windows.Media.DrawingVisual
  $dc = $dv.RenderOpen(); $dc.DrawVideo($mp, (New-Object System.Windows.Rect(0, 0, $w, $h))); $dc.Close()
  $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($w, $h, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
  $rtb.Render($dv)
  $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
  $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
  $fs = [IO.File]::Create("$sp\f$('{0:D2}' -f $i).png"); $enc.Save($fs); $fs.Close()
}
