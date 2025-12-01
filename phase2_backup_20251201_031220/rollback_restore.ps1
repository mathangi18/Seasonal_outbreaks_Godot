param(\D:\Repos\Seasonal_outbreaks_Godot\phase2_backup_20251201_031220 = 'D:\Repos\Seasonal_outbreaks_Godot\phase2_backup_20251201_031220')
Write-Output 'Restoring backup from ' \D:\Repos\Seasonal_outbreaks_Godot\phase2_backup_20251201_031220
Get-ChildItem -LiteralPath \D:\Repos\Seasonal_outbreaks_Godot\phase2_backup_20251201_031220 -Force | ForEach-Object {
  if (\.PSIsContainer) {
    Copy-Item -LiteralPath \.FullName -Destination 'D:\Repos\Seasonal_outbreaks_Godot' -Recurse -Force
  } elseif (\.Extension -eq '.json' -or \.Extension -eq '.txt') {
    Copy-Item -LiteralPath \.FullName -Destination 'D:\Repos\Seasonal_outbreaks_Godot\tools\phase2' -Force
  }
}
Write-Output 'Restore completed. You may need to re-open your editor/IDE.'
