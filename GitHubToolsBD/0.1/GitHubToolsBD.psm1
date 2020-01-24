function Get-FilesFromRepo {
  <#
  .SYNOPSIS
    This downloads files from a GitHub Repository
  .DESCRIPTION
    This command will copy files from a GitHub Repo and store them in a 
    folder of your choice.
  .EXAMPLE
    Get-FilesFromRepo -GitHubUserName BOB -Repository Webproject -Destination c:\RepoCopy
    This gets the files in the webproject repo from the GitHub user BOB and copies them 
    to the the c:\RepoCopy folder.
  .EXAMPLE
    Get-FilesFromRepo -GitHubUserName BOB -Destination c:\RepoCopy
    This will present the user with a menu of Repositories for the GitHub user BOB and 
    once a repo is selected it will copy file in the repo to the the c:\RepoCopy folder.
  .PARAMETER GitHubUserName
    This is the GitHub user site that will be used to copy the files from
  .PARAMETER Repository
    This is the users repository that willl be used to copy the files from, if this 
    is not specified a menu will show asking to choose the repo from a list.
  .PARAMETER PathInRepo
    If the repo has sub directories you can specify the one you want 
  .PARAMETER Destination
    This is the path that will be used to save the files on the local machine
  .PARAMETER FilesToRetrive
    This a RegEx pattern that will dictate which of the files to retrieve
  .NOTES
    General notes
      Written By: Brent Denny
      Written on: 28 Aug 2019
  #>
  [cmdletbinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUserName,
    [string]$Repository = '',
    [string]$PathInRepo = '',
    [string]$Destination = "$env:TEMP\Git\$GitHubUserName",
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
    do {
      $GoodChoice = $true
      $choice = Read-Host -Prompt "Choose which repo"
      try {
        0 + $choice > $null
        $choice = $choice -as [int]
        if ($choice -gt $RepoNames.Count -or $choice -lt 1) {throw}
      }
      catch {
        $GoodChoice = $false
        continue
      }
      $choice = $choice - 1
      $Repository = $RepoNames[$choice]
    } while ($GoodChoice -eq $false)
  } #END if
  $URI = "https://api.github.com/repos/$GitHubUserName/$Repository/contents/$PathInRepo"
  $WebData = Invoke-WebRequest -Uri $($URI)
  $WebContent = $WebData.Content | ConvertFrom-Json
  $DownloadURLS = ($WebContent | Where-Object {$_.type -eq "file"}).download_url | Where-Object {$_ -match $FilesToRetrive}
  if ((Test-Path $Destination) -eq $false) {
      try {New-Item -Path $Destination -ItemType Directory -ErrorAction Stop > $null} 
      catch {Write-Warning "Could not create path '$Destination'!"}
  } #END if
  foreach ($DownloadURL in $DownloadURLS) {
      $DestinationFilePath = Join-Path $Destination (Split-Path $DownloadURL -Leaf)
      try {Invoke-WebRequest -Uri $DownloadURL -OutFile $DestinationFilePath -ErrorAction Stop -Verbose}
      catch {Write-Warning "Unable to download '$($DownloadURL.path)'"}
  } #END foreach
} #END function


function New-GitHubRepoClone {
  <#
  .SYNOPSIS
    This will clone a GitHub repo onto your current machine
  .DESCRIPTION
    If the repo is not supplied as a parameter, this command will list all public repos
    for the given GitGub user and ask you to select one from a menu. The repo will then 
    be cloned into the TEMP/Git\<RepoName> directory by default unless this is also 
    specified as a parameter.
  .EXAMPLE
    New-GitHubRepoClone 
    This will use the default values for GitHubame and Destination and then present a 
    menu in which you can choose the repository that you wish to clone
  .EXAMPLE
    New-GitHubRepoClone -GitHubUserName BrentD09
    This will use the Brentd09 for GitHubame and use the default location for the Destination 
    and then present a menu in which you can choose the repository that you wish to clone
  .EXAMPLE
    New-GitHubRepoClone -GitHubUserName BrentD09 -Repository PSCourseScripts
    This will use the Brentd09 for GitHubame and will clone the PSCourseScripts repository
    into the default value for the destination.  
  .EXAMPLE
    New-GitHubRepoClone -GitHubUserName BrentD09 -Repository PSCourseScripts -Destination D:\Git\
    This will use the Brentd09 for GitHubame and will clone the PSCourseScripts repository
    into the d:\Git\PSCourseScripts directory
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 24 Jan 2020
  #>
  [cmdletbinding()]
  Param(
    [string]$GitHubUserName = 'BrentD09',
    [string]$Repository = '',
    [string]$Destination = "$env:TEMP\Git\"
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  if ($Repository -eq '') {
    $AllRepos = (Invoke-RestMethod -Uri "https://api.github.com/users/$GitHubUserName/repos").URL
    $RepoNames = Split-Path -Path $AllRepos -Leaf 
    Clear-Host
    Write-Host 'Which Repo'
    $count = 0
    Foreach ($Repo in $RepoNames) {
      $count++
      if ($Count -le 9) {$Spc=' '}
      else {$Spc=''}
      Write-Host "$Spc$count - $Repo"
    }
    do {
      $GoodChoice = $true
      $choice = Read-Host -Prompt "Choose which repo"
      try {
        0 + $choice > $null
        $choice = $choice -as [int]
        if ($choice -gt $RepoNames.Count -or $choice -lt 1) {throw}
      }
      catch {
        $GoodChoice = $false
        continue
      }
      $choice = $choice - 1
      $RepositoryName = $RepoNames[$choice]
    } while ($GoodChoice -eq $false)
  }  
  $Repository = 'https://github.com/' + $GitHubUserName + '/' + $RepositoryName
  $FullDestination = $Destination.TrimEnd('\') + '\' + $RepositoryName
  $ErrorActionPreference = 'Stop'
  try {
    if (Test-Path $FullDestination) {throw}
    git clone $Repository  $FullDestination
  }
  catch {Write-Warning 'Something went wrong with the cloning of the repository'}
}

