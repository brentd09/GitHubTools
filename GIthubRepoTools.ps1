function Get-RepoFile {
  Param (
    $GitHubUserName = 'MSSA-AU',
    $RepoName = 'ClassInfo'
  )
  $RepoInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$($GitHubUserName)/$($RepoName)"
  $RepoFiles = Invoke-RestMethod -Uri "https://api.github.com/repos/$($GitHubUserName)/$($RepoName)/git/trees/$($RepoInfo.default_branch)?recursive=1"
  $File = Invoke-RestMethod -Uri ' https://api.github.com/repos/MSSA-AU/ClassInfo/git/blobs/2af0efe1b26d1a18e6bd7a825d6cde81cfde2e47'
  return $file

}

([System.Convert]::FromBase64String((Get-RepoFile).content) | ForEach-Object {[char]$_} ) -join '' -replace '"',''

