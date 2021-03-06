[CmdletBinding()]
param(
)

$projectCollectionUri = "http://devtfs02/DefaultCollection"
$projectName = "RnD"
$repository = "RnD"
$currentBranch = "develop"
$env:TEAM_AUTHTYPE = "Basic"
$env:TEAM_PAT = "OjVidjN6Mm1wM2ViYnB0ZnNuYmpxaWV2ajNidDJwcW9hM2xudTZmZnRkaXA2anNhem14NHE="
$stagingDirectory = "c:\temp\GitflowBranchGate"
$showIssuesOnBuildSummary = $false

$build = New-Object psobject -Property @{
  BuildId = 0
  SourceBranch = "develop"
  BuildReason = "PullRequest"
  PullRequestId = 7
  RepositoryProvider = "Git"
}

$rules = New-Object psobject -Property @{
  MasterBranch = "master"
  DevelopBranch = "develop"
  HotfixPrefix = "hotfix/*"
  ReleasePrefix = "release/*"
  FeaturePrefix = "feature/*"

  HotfixBranchLimit = 1
  HotfixDaysLimit = 10
  ReleaseBranchLimit = 1
  ReleaseDaysLimit = 10
  FeatureBranchLimit = 50
  FeatureDaysLimit = 45

  HotfixeBranchesMustNotBeBehindMaster = $false
  ReleaseBranchesMustNotBeBehindMaster = $false
  DevelopMustNotBeBehindMaster = $true
  FeatureBranchesMustNotBeBehindMaster = $false
  FeatureBranchesMustNotBeBehindDevelop = $false
  CurrentFeatureMustNotBeBehindDevelop = $false
  MustNotHaveHotfixAndReleaseBranches = $false

  MasterMustNotHaveIncomingPullRequests = $false
  MasterMustNotHaveOutgoingPullRequests = $false

  HotfixBranchesMustNotHaveActivePullRequests = $false
  ReleaseBranchesMustNotHaveActivePullRequests = $false
  BranchNamesMustMatchConventions = $false
}

Write-Output "Project Collection: [$projectCollectionUri]"
Write-Output "Project Name: [$projectName]"
Write-Output "Build Reason: [$($build.BuildId)]"
Write-Output "Build Reason: [$($build.BuildReason)]"
Write-Output "Repository: [$repository]"
Write-Output "Current Branch: [$($Build.SourceBranch)]"
Write-Output "Authentication Type: [$env:TEAM_AUTHTYPE]"
Write-Output "Rules:"
$rules

$scriptLocation = "C:\Dev\GitHub\VSTSTasks\Tasks\GitflowBranchGate\Task"

#Import Required Modules
Import-Module "$scriptLocation\ps_modules\Custom\team.Extentions.psm1" -Force
Import-Module "$scriptLocation\ps_modules\Custom\BranchRules.psm1" -Force

#Check if the master branches exists
$refs = Get-Branches -ProjectCollectionUri $projectCollectionUri -ProjectName $projectName -Repository $repository
$master = $refs | Where-Object { $_.name -eq "refs/heads/$($Rules.MasterBranch)" }
if ($master -eq $null) {
  Write-Error "Could not find remote branch: refs/heads/$($Rules.MasterBranch)"
}

$develop = $refs | Where-Object { $_.name -eq "refs/heads/$($Rules.DevelopBranch)" }
if ($develop -eq $null) {
  Write-Error "Could not find remote branch: refs/heads/$($Rules.DevelopBranch)"
}

#Get All Branches
[System.Object[]]$pullRequests = Get-PullRequests -ProjectCollectionUri $projectCollectionUri -ProjectName $projectName -Repository $repository -StatusFilter Active | ConvertTo-PullRequests
[System.Object[]]$branchesComparedToDevelop = Get-BranchStats -ProjectCollectionUri $projectCollectionUri -ProjectName $projectName -Repository $repository -BaseBranch $Rules.DevelopBranch
[System.Object[]]$branches = Get-BranchStats -ProjectCollectionUri $projectCollectionUri -ProjectName $projectName -Repository $repository -BaseBranch $Rules.MasterBranch | ConvertTo-Branches
$branches = Add-DevelopCompare -Branches $branches -BranchesComparedToDevelop $branchesComparedToDevelop
$branches = Add-PullRequests -Branches $branches -PullRequests $pullRequests
$branches = Invoke-BranchRules -Branches $branches -Build $build -Rules $rules

Write-OutputCurrentBranches -Branches $Branches
Write-OutputPullRequests -PullRequests $pullRequests
Write-OutputWarnings -Branches $Branches

Write-OutputErrors -Branches $Branches