# TextureResizer.ps1
# Resizes image files to common texture sizes.
# Requires Windows 10/11 — uses built-in System.Drawing and Windows.Forms.

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

[System.Windows.Forms.Application]::EnableVisualStyles()

$imageExtensions = @(".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff")

# Shared state for the form
$state = [PSCustomObject]@{
    SourceFolder  = $PSScriptRoot
    SourceFiles   = [string[]]@()
    UseAllFiles   = $true
}

function Get-SizeLabel ([int]$px) {
    if ($px -ge 1024) { return "$([int]($px / 1024))K" }
    return "${px}"
}

function Get-DefaultOutputPath ([string]$sizeLabel) {
    if ($state.UseAllFiles) {
        $base = $state.SourceFolder
    } elseif ($state.SourceFiles.Count -gt 0) {
        $base = Split-Path $state.SourceFiles[0] -Parent
    } else {
        $base = $PSScriptRoot
    }
    return Join-Path $base $sizeLabel
}

function Show-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text            = "TextureResizer"
    $form.Width           = 440
    $form.Height          = 370
    $form.StartPosition   = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox     = $false

    # ── FILES section ────────────────────────────────────────────
    $lblFilesHeader = New-Object System.Windows.Forms.Label
    $lblFilesHeader.Text      = "FILES"
    $lblFilesHeader.Location  = New-Object System.Drawing.Point(20, 16)
    $lblFilesHeader.AutoSize  = $true
    $lblFilesHeader.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $lblFilesHeader.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblFilesHeader)

    $rbAllFiles = New-Object System.Windows.Forms.RadioButton
    $rbAllFiles.Text     = "All files in a folder"
    $rbAllFiles.Location = New-Object System.Drawing.Point(20, 34)
    $rbAllFiles.AutoSize = $true
    $rbAllFiles.Checked  = $true
    $form.Controls.Add($rbAllFiles)

    $lblFolderPath = New-Object System.Windows.Forms.Label
    $lblFolderPath.Text      = $PSScriptRoot
    $lblFolderPath.Location  = New-Object System.Drawing.Point(40, 56)
    $lblFolderPath.Width     = 270
    $lblFolderPath.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblFolderPath)

    $btnChooseFolder = New-Object System.Windows.Forms.Button
    $btnChooseFolder.Text     = "Choose..."
    $btnChooseFolder.Location = New-Object System.Drawing.Point(318, 52)
    $btnChooseFolder.Width    = 80
    $btnChooseFolder.Height   = 24
    $form.Controls.Add($btnChooseFolder)

    $rbIndividual = New-Object System.Windows.Forms.RadioButton
    $rbIndividual.Text     = "Individual files"
    $rbIndividual.Location = New-Object System.Drawing.Point(20, 84)
    $rbIndividual.AutoSize = $true
    $form.Controls.Add($rbIndividual)

    $lblFilesChosen = New-Object System.Windows.Forms.Label
    $lblFilesChosen.Text      = "No files selected"
    $lblFilesChosen.Location  = New-Object System.Drawing.Point(40, 106)
    $lblFilesChosen.Width     = 270
    $lblFilesChosen.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblFilesChosen)

    $btnChooseFiles = New-Object System.Windows.Forms.Button
    $btnChooseFiles.Text     = "Choose..."
    $btnChooseFiles.Location = New-Object System.Drawing.Point(318, 102)
    $btnChooseFiles.Width    = 80
    $btnChooseFiles.Height   = 24
    $form.Controls.Add($btnChooseFiles)

    # ── Divider ──────────────────────────────────────────────────
    $div1 = New-Object System.Windows.Forms.Label
    $div1.BorderStyle = "Fixed3D"
    $div1.Location    = New-Object System.Drawing.Point(20, 138)
    $div1.Width       = 378
    $div1.Height      = 2
    $form.Controls.Add($div1)

    # ── OUTPUT SIZE section ───────────────────────────────────────
    $lblSizeHeader = New-Object System.Windows.Forms.Label
    $lblSizeHeader.Text      = "OUTPUT SIZE"
    $lblSizeHeader.Location  = New-Object System.Drawing.Point(20, 150)
    $lblSizeHeader.AutoSize  = $true
    $lblSizeHeader.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $lblSizeHeader.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblSizeHeader)

    $sizeDropdown = New-Object System.Windows.Forms.ComboBox
    $sizeDropdown.Location      = New-Object System.Drawing.Point(20, 168)
    $sizeDropdown.Width         = 180
    $sizeDropdown.DropDownStyle = "DropDownList"
    $sizeDropdown.Items.AddRange(@("2K (2048)", "1K (1024)", "512", "Custom"))
    $sizeDropdown.SelectedIndex = 0
    $form.Controls.Add($sizeDropdown)

    $txtCustomSize = New-Object System.Windows.Forms.TextBox
    $txtCustomSize.Location  = New-Object System.Drawing.Point(210, 168)
    $txtCustomSize.Width     = 60
    $txtCustomSize.MaxLength = 4
    $txtCustomSize.Visible   = $false
    $form.Controls.Add($txtCustomSize)

    $lblCustomHint = New-Object System.Windows.Forms.Label
    $lblCustomHint.Text     = "px  (64 - 8192)"
    $lblCustomHint.Location = New-Object System.Drawing.Point(278, 172)
    $lblCustomHint.AutoSize = $true
    $lblCustomHint.Visible  = $false
    $form.Controls.Add($lblCustomHint)

    # ── Divider ──────────────────────────────────────────────────
    $div2 = New-Object System.Windows.Forms.Label
    $div2.BorderStyle = "Fixed3D"
    $div2.Location    = New-Object System.Drawing.Point(20, 205)
    $div2.Width       = 378
    $div2.Height      = 2
    $form.Controls.Add($div2)

    # ── SAVE TO section ───────────────────────────────────────────
    $lblSaveHeader = New-Object System.Windows.Forms.Label
    $lblSaveHeader.Text      = "SAVE TO"
    $lblSaveHeader.Location  = New-Object System.Drawing.Point(20, 217)
    $lblSaveHeader.AutoSize  = $true
    $lblSaveHeader.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $lblSaveHeader.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblSaveHeader)

    $txtOutputPath = New-Object System.Windows.Forms.TextBox
    $txtOutputPath.Location = New-Object System.Drawing.Point(20, 235)
    $txtOutputPath.Width    = 290
    $form.Controls.Add($txtOutputPath)

    $btnBrowseOutput = New-Object System.Windows.Forms.Button
    $btnBrowseOutput.Text     = "Browse..."
    $btnBrowseOutput.Location = New-Object System.Drawing.Point(318, 233)
    $btnBrowseOutput.Width    = 80
    $btnBrowseOutput.Height   = 24
    $form.Controls.Add($btnBrowseOutput)

    $btnResize = New-Object System.Windows.Forms.Button
    $btnResize.Text         = "Resize"
    $btnResize.Location     = New-Object System.Drawing.Point(318, 280)
    $btnResize.Width        = 80
    $btnResize.Height       = 30
    $btnResize.DialogResult = "OK"
    $form.AcceptButton      = $btnResize
    $form.Controls.Add($btnResize)

    # ── Helper: refresh the output path box ──────────────────────
    function Sync-OutputPath {
        $label = switch ($sizeDropdown.SelectedItem) {
            "2K (2048)" { "2K"     }
            "1K (1024)" { "1K"     }
            "512"       { "512"    }
            "Custom"    { "Custom" }
        }
        $txtOutputPath.Text = Get-DefaultOutputPath $label
    }

    # ── Event handlers ────────────────────────────────────────────
    $btnChooseFolder.Add_Click({
        $rbAllFiles.Checked = $true
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.SelectedPath = $state.SourceFolder
        if ($dlg.ShowDialog() -eq "OK") {
            $state.SourceFolder   = $dlg.SelectedPath
            $lblFolderPath.Text   = $dlg.SelectedPath
            Sync-OutputPath
        }
    })

    $btnChooseFiles.Add_Click({
        $rbIndividual.Checked = $true
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title            = "Select textures to resize"
        $dlg.Filter           = "Images (*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff)|*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff"
        $dlg.Multiselect      = $true
        $dlg.InitialDirectory = $PSScriptRoot
        if ($dlg.ShowDialog() -eq "OK") {
            $state.SourceFiles      = $dlg.FileNames
            $lblFilesChosen.Text    = "$($dlg.FileNames.Count) file(s) selected"
            Sync-OutputPath
        }
    })

    $rbAllFiles.Add_CheckedChanged({
        $state.UseAllFiles = $rbAllFiles.Checked
        Sync-OutputPath
    })

    $rbIndividual.Add_CheckedChanged({
        $state.UseAllFiles = $rbAllFiles.Checked
        Sync-OutputPath
    })

    $sizeDropdown.Add_SelectedIndexChanged({
        $isCustom              = ($sizeDropdown.SelectedItem -eq "Custom")
        $txtCustomSize.Visible = $isCustom
        $lblCustomHint.Visible = $isCustom
        if ($isCustom) { $txtCustomSize.Focus() }
        Sync-OutputPath
    })

    $txtCustomSize.Add_KeyPress({
        param($sender, $e)
        $digit = [char]::IsDigit($e.KeyChar)
        $back  = ($e.KeyChar -eq [char][System.Windows.Forms.Keys]::Back)
        if (-not $digit -and -not $back) { $e.Handled = $true }
    })

    $txtCustomSize.Add_Leave({
        $n = 0
        if ([int]::TryParse($txtCustomSize.Text, [ref]$n)) {
            if ($n -lt 64)   { $txtCustomSize.Text = "64" }
            if ($n -gt 8192) { $txtCustomSize.Text = "8192" }
        }
    })

    $btnBrowseOutput.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.ShowNewFolderButton = $true
        $dlg.SelectedPath = if (Test-Path $txtOutputPath.Text) { $txtOutputPath.Text } else { $PSScriptRoot }
        if ($dlg.ShowDialog() -eq "OK") { $txtOutputPath.Text = $dlg.SelectedPath }
    })

    # Populate output path before showing
    Sync-OutputPath

    if ($form.ShowDialog() -ne "OK") { exit }

    # Return selections as a plain object
    return [PSCustomObject]@{
        UseAllFiles  = $rbAllFiles.Checked
        SizeItem     = $sizeDropdown.SelectedItem
        CustomSizeTx = $txtCustomSize.Text
        OutputPath   = $txtOutputPath.Text.Trim()
    }
}

function Show-SizeForm {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = "TextureResizer - Choose Size"
    $dlg.Width           = 260
    $dlg.Height          = 190
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox     = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text     = "Resize to:"
    $lbl.Location = New-Object System.Drawing.Point(20, 20)
    $lbl.AutoSize = $true
    $dlg.Controls.Add($lbl)

    $sizes = @("2K (2048)", "1K (1024)", "512")
    $radios = @()
    $y = 45
    foreach ($s in $sizes) {
        $rb          = New-Object System.Windows.Forms.RadioButton
        $rb.Text     = $s
        $rb.Location = New-Object System.Drawing.Point(30, $y)
        $rb.AutoSize = $true
        if ($y -eq 45) { $rb.Checked = $true }
        $dlg.Controls.Add($rb)
        $radios += $rb
        $y += 28
    }

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text         = "Resize"
    $btn.Location     = New-Object System.Drawing.Point(154, 118)
    $btn.Width        = 75
    $btn.Height       = 28
    $btn.DialogResult = "OK"
    $dlg.AcceptButton = $btn
    $dlg.Controls.Add($btn)

    if ($dlg.ShowDialog() -ne "OK") { exit }

    return ($radios | Where-Object { $_.Checked }).Text
}

# ── Collect inputs ────────────────────────────────────────────
$isDragDrop = $args.Count -gt 0

if ($isDragDrop) {
    $dragFiles = [System.Collections.Generic.List[string]]::new()
    foreach ($arg in $args) {
        if (Test-Path $arg -PathType Leaf) {
            if ($imageExtensions -contains [System.IO.Path]::GetExtension($arg).ToLower()) {
                $dragFiles.Add($arg)
            }
        } elseif (Test-Path $arg -PathType Container) {
            Get-ChildItem -Path $arg -File |
                Where-Object { $imageExtensions -contains $_.Extension.ToLower() } |
                ForEach-Object { $dragFiles.Add($_.FullName) }
        }
    }
    if ($dragFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No valid image files found.", "TextureResizer", "OK", "Warning") | Out-Null
        exit
    }
    $inputFiles = $dragFiles.ToArray()

    $sizeItem = Show-SizeForm
    $targetPx = switch ($sizeItem) {
        "2K (2048)" { 2048 }
        "1K (1024)" { 1024 }
        "512"       { 512  }
    }
    $sizeLabel = switch ($targetPx) {
        2048 { "2K"  }
        1024 { "1K"  }
        512  { "512" }
    }
    # Each file saves to a subfolder beside its own source folder
    $outputDir = $null
} else {
    $result = Show-MainForm

    if ($result.UseAllFiles) {
        $inputFiles = Get-ChildItem -Path $state.SourceFolder -File |
                      Where-Object { $imageExtensions -contains $_.Extension.ToLower() } |
                      Select-Object -ExpandProperty FullName
    } else {
        $inputFiles = $state.SourceFiles
    }

    if (-not $inputFiles) {
        [System.Windows.Forms.MessageBox]::Show("No valid image files found.", "TextureResizer", "OK", "Warning") | Out-Null
        exit
    }

    $targetPx = switch ($result.SizeItem) {
        "2K (2048)" { 2048 }
        "1K (1024)" { 1024 }
        "512"       { 512  }
        "Custom"    {
            $n = 0
            if (-not [int]::TryParse($result.CustomSizeTx, [ref]$n) -or $n -lt 64 -or $n -gt 8192) {
                [System.Windows.Forms.MessageBox]::Show("Please enter a size between 64 and 8192.", "TextureResizer", "OK", "Warning") | Out-Null
                exit
            }
            $n
        }
    }
    $sizeLabel = switch ($targetPx) {
        2048 { "2K"  }
        1024 { "1K"  }
        512  { "512" }
        default { "${targetPx}px" }
    }

    $outputDir = $result.OutputPath
    if (-not $outputDir) { $outputDir = $PSScriptRoot }
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
}

# ── Resize ────────────────────────────────────────────────────
$successCount = 0
$errors       = [System.Collections.Generic.List[string]]::new()

foreach ($filePath in $inputFiles) {
    try {
        $sourceImage  = [System.Drawing.Image]::FromFile($filePath)
        $outputBitmap = New-Object System.Drawing.Bitmap($targetPx, $targetPx)
        $graphics     = [System.Drawing.Graphics]::FromImage($outputBitmap)

        $graphics.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        $graphics.DrawImage($sourceImage, 0, 0, $targetPx, $targetPx)

        $baseName  = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $extension = [System.IO.Path]::GetExtension($filePath)

        # Drag-drop: each file saves beside its own source folder
        $saveDir = if ($isDragDrop) {
            Join-Path (Split-Path $filePath -Parent) $sizeLabel
        } else {
            $outputDir
        }
        if (-not (Test-Path $saveDir)) { New-Item -ItemType Directory -Path $saveDir | Out-Null }

        $outPath   = Join-Path $saveDir ($baseName + $extension)

        $imageFormat = switch ($extension.ToLower()) {
            ".jpg"  { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".jpeg" { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".bmp"  { [System.Drawing.Imaging.ImageFormat]::Bmp  }
            ".tif"  { [System.Drawing.Imaging.ImageFormat]::Tiff }
            ".tiff" { [System.Drawing.Imaging.ImageFormat]::Tiff }
            default { [System.Drawing.Imaging.ImageFormat]::Png  }
        }

        $outputBitmap.Save($outPath, $imageFormat)

        $graphics.Dispose()
        $outputBitmap.Dispose()
        $sourceImage.Dispose()

        $successCount++
    } catch {
        $errors.Add("$([System.IO.Path]::GetFileName($filePath)): $_")
    }
}

# ── Summary ───────────────────────────────────────────────────
$summary = "Done! $successCount file(s) resized to ${targetPx}x${targetPx}."
if ($errors.Count -gt 0) {
    $summary += "`n`nErrors:`n" + ($errors -join "`n")
    [System.Windows.Forms.MessageBox]::Show($summary, "TextureResizer", "OK", "Warning") | Out-Null
} else {
    [System.Windows.Forms.MessageBox]::Show($summary, "TextureResizer", "OK", "Information") | Out-Null
}

$openDir = if ($isDragDrop) {
    Join-Path (Split-Path $inputFiles[0] -Parent) $sizeLabel
} else {
    $outputDir
}
Start-Process explorer.exe $openDir
