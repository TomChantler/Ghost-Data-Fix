# By Tom Chantler - https://tomssl.com/how-to-upgrade-your-ghost-blog-to-the-latest-version-without-breaking-anything-part-1
param([string]$DataFilePath
    , [bool]$FixMarkdownLinks = $true
    , [bool]$ConvertImageLinksToLowerCase = $false
    , [string]$ImagesDirectory = $null)

Write-Host "About to apply fixes to $DataFilePath" -ForegroundColor Yellow

$fixedDataFilePath = $DataFilePath.Insert($DataFilePath.LastIndexOf("."), $(if ($ConvertImageLinksToLowerCase) { ".imagesfixed" }) + $(if ($FixMarkdownLinks) { ".markdownfixed" }))
if ($fixedDataFilePath -eq $DataFilePath) {
    return
}
$patternForMarkdownLinks = "(?<linkpart>\[[^\]}]*\]*)\s*\((?<scheme>https?:\/\/)?(?<address>[^\[\""]*?)(?:[\\])?(?<target>""\s*target\s*=\s*\\*\""\s*_.*?)\)"
$patternForImageLinks = [Regex]"(/content\S+?\.(jpg|png|gif|svg))"
[IO.Directory]::SetCurrentDirectory((Convert-Path (Get-Location -PSProvider FileSystem)))
$data = (Get-Content $DataFilePath -Encoding UTF8) -Join [Environment]::NewLine
if ($ConvertImageLinksToLowerCase) { 
    $data = $patternForImageLinks.Replace($data, { $args[0].Value.ToLower() })
    Write-Host 'Fixed Image Links' -ForegroundColor Yellow
}
if ($FixMarkdownLinks) { 
    $data = $data -replace $patternForMarkdownLinks, '${linkpart}(${scheme}${address})'
    Write-Host 'Fixed Markdown "target ="_blank trick' -ForegroundColor Yellow
}
if (Test-Path $ImagesDirectory -PathType Container) {
    Get-ChildItem $ImagesDirectory -recurse | Where-Object { -Not $_.PSIsContainer } | Rename-Item -NewName { $_.FullName.ToLower() }
    Write-Host "Renamed all files in $ImagesDirectory directory to lower case" -ForegroundColor Yellow
} 
if ($PSVersionTable.PSVersion.Major -ge 6){
Set-Content -Path $fixedDataFilePath -Value $data -Encoding UTF8NoBOM
} else {
    [IO.File]::WriteAllText($fixedDataFilePath, $data)
}
Write-Host Done -ForegroundColor Green