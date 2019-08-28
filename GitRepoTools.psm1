function Get-FilesFromRepo {
  [cmdletbinding()]
  Param(
      [string]$GitHubUserName,
      [string]$Repository = '',
      [string]$PathInRepo = '',
      [string]$Destination = 'D:\Allfiles',
      [string]$FilesToRetrive = ''
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  if ($Repository -eq '') {
    $AllRepos = (Invoke-RestMethod -Uri "https://api.github.com/users/$GitHubUserName/repos").URL
    $RepoNames = Split-Path -Path $AllRepos -Leaf 
    Write-Host 'Which Repo'
    $count = 0
    Foreach ($Repo in $RepoNames) {
      $count++
      Write-Host "$count - $Repo"
    }
    [int]$choice = Read-Host -Prompt "Choose which repo"
    $choice = $choice - 1
    $Repository = $RepoNames[$choice]
  }

  $URI = "https://api.github.com/repos/$GitHubUserName/$Repository/contents/$PathInRepo"
  $WebData = Invoke-WebRequest -Uri $($URI)
  $WebContent = $WebData.Content | ConvertFrom-Json
  $DownloadURLS = ($WebContent | Where-Object {$_.type -eq "file"}).download_url | Where-Object {$_ -match $FilesToRetrive}
  if ((Test-Path $Destination) -eq $false) {
      try {New-Item -Path $Destination -ItemType Directory -ErrorAction Stop > $null} 
      catch {Write-Warning "Could not create path '$Destination'!"}
  }
  foreach ($DownloadURL in $DownloadURLS) {
      $DestinationFilePath = Join-Path $Destination (Split-Path $DownloadURL -Leaf)
      try {Invoke-WebRequest -Uri $DownloadURL -OutFile $DestinationFilePath -ErrorAction Stop -Verbose}
      catch {Write-Warning "Unable to download '$($DownloadURL.path)'"}
  }
}