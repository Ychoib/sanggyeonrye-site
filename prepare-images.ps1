param(
  [int]$DefaultLongEdge = 1800,
  [int]$Quality = 88
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$sourceDir = Join-Path $PSScriptRoot "image"
$outputDir = Join-Path $sourceDir "web"

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq "image/jpeg" }

function Set-ImageOrientation {
  param([System.Drawing.Image]$Image)

  $orientationId = 0x0112
  if (-not ($Image.PropertyIdList -contains $orientationId)) {
    return
  }

  $orientation = $Image.GetPropertyItem($orientationId).Value[0]

  switch ($orientation) {
    2 { $Image.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
    3 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
    4 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
    5 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
    6 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
    7 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
    8 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
  }
}

function Save-WebImage {
  param(
    [string]$SourceName,
    [string]$OutputName,
    [int]$LongEdge = $DefaultLongEdge
  )

  $sourcePath = Join-Path $sourceDir $SourceName
  $outputPath = Join-Path $outputDir $OutputName

  if (-not (Test-Path $sourcePath)) {
    throw "Source image not found: $sourcePath"
  }

  $image = [System.Drawing.Image]::FromFile($sourcePath)

  try {
    Set-ImageOrientation -Image $image

    $longSide = [Math]::Max($image.Width, $image.Height)
    $ratio = [Math]::Min($LongEdge / $longSide, 1)
    $targetWidth = [Math]::Max([int][Math]::Round($image.Width * $ratio), 1)
    $targetHeight = [Math]::Max([int][Math]::Round($image.Height * $ratio), 1)

    $bitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)

    try {
      $bitmap.SetResolution(96, 96)
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

      try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($image, 0, 0, $targetWidth, $targetHeight)

        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
          [System.Drawing.Imaging.Encoder]::Quality,
          [long]$Quality
        )

        try {
          $bitmap.Save($outputPath, $jpegCodec, $encoderParams)
        }
        finally {
          $encoderParams.Dispose()
        }
      }
      finally {
        $graphics.Dispose()
      }
    }
    finally {
      $bitmap.Dispose()
    }
  }
  finally {
    $image.Dispose()
  }

  Write-Output "Prepared $OutputName"
}

$images = @(
  @{ Source = "DOO_0220.jpg"; Output = "hero-main.jpg"; LongEdge = 1800 }
  @{ Source = "KakaoTalk_20260313_232730849_06.jpg"; Output = "hero-detail.jpg"; LongEdge = 1200 }
  @{ Source = "KakaoTalk_20260313_232730849_01.jpg"; Output = "hero-side.jpg"; LongEdge = 1400 }
  @{ SourcePattern = "*.jpg"; ExcludeRegex = "^(DOO_|KakaoTalk_)"; Output = "profile-groom.jpg"; LongEdge = 1400 }
  @{ Source = "DOO_0362.jpg"; Output = "profile-bride.jpg"; LongEdge = 1400 }
  @{ Source = "DOO_0198.jpg"; Output = "moment-vow.jpg"; LongEdge = 1800 }
  @{ Source = "DOO_0298.jpg"; Output = "moment-garden.jpg"; LongEdge = 1600 }
  @{ Source = "KakaoTalk_20260313_232730849_04.jpg"; Output = "moment-playful.jpg"; LongEdge = 1600 }
  @{ Source = "KakaoTalk_20260313_232730849_06.jpg"; Output = "moment-detail.jpg"; LongEdge = 1600 }
)

foreach ($item in $images) {
  $sourceName = $item.Source

  if ($item.ContainsKey("SourcePattern")) {
    $sourceName = Get-ChildItem $sourceDir -File -Filter $item.SourcePattern |
      Where-Object { $_.Name -notmatch $item.ExcludeRegex } |
      Select-Object -ExpandProperty Name -First 1

    if (-not $sourceName) {
      throw "Source image not found for pattern: $($item.SourcePattern)"
    }
  }

  Save-WebImage -SourceName $sourceName -OutputName $item.Output -LongEdge $item.LongEdge
}
