<#
.SYNOPSIS
    GitHub Repository Automation Script - PowerShell Version
    
.DESCRIPTION
    Reads repository and team information from CSV files and creates them
    in a GitHub Enterprise organization if they don't already exist.
    
.NOTES
    Requires GITHUB_TOKEN and GITHUB_ORGANIZATION environment variables to be set.
#>

# Get GitHub token from environment
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Error "Error: GITHUB_TOKEN environment variable not set"
    exit 1
}

# Get organization name from environment
$organization = $env:GITHUB_ORGANIZATION
if (-not $organization) {
    Write-Error "Error: GITHUB_ORGANIZATION environment variable not set"
    exit 1
}

# Get GitHub API URL from environment (defaults to public GitHub)
$apiUrl = $env:GITHUB_API_URL
if (-not $apiUrl) {
    $apiUrl = "https://api.github.com"
}

# Set up headers for GitHub API
$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Uri,
        [object]$Body = $null
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $headers
        }
        
        if ($Body) {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
            $params['ContentType'] = 'application/json'
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return $null
        }
        throw
    }
}

function Create-Teams {
    try {
        # Read and parse CSV file
        $csvFilePath = Join-Path $PSScriptRoot "csv\teams.csv"
        Write-Host "Reading team data from: $csvFilePath"
        
        if (-not (Test-Path $csvFilePath)) {
            Write-Error "Error: CSV file not found at $csvFilePath"
            exit 1
        }
        
        $teams = Import-Csv -Path $csvFilePath
        Write-Host "Found $($teams.Count) teams to process"
        
        # Process each team
        foreach ($team in $teams) {
            $teamName = $team.name
            if (-not $teamName) {
                Write-Warning "Warning: Team name missing, skipping entry"
                continue
            }
            
            if (-not $team.privacy) {
                Write-Warning "Warning: Team privacy missing, skipping entry"
                continue
            }
            
            if ($team.privacy -ne 'closed' -and $team.privacy -ne 'secret') {
                Write-Warning "Warning: Team privacy must be either 'closed' or 'secret', skipping entry"
                continue
            }
            
            try {
                # Check if team already exists
                $teamSlug = $teamName.ToLower() -replace ' ', '-'
                $existingTeam = Invoke-GitHubApi -Method Get -Uri "$apiUrl/orgs/$organization/teams/$teamSlug"
                
                if ($existingTeam) {
                    Write-Host "✓ Team '$teamName' already exists in $organization"
                    continue
                }
                
                # Team doesn't exist, create it
                Write-Host "Creating team '$teamName' in $organization..."
                
                $teamBody = @{
                    name = $teamName
                    description = $team.description
                    privacy = $team.privacy
                }
                
                $newTeam = Invoke-GitHubApi -Method Post -Uri "$apiUrl/orgs/$organization/teams" -Body $teamBody
                
                # Set group IDP connection if all values are provided
                if ($team.idpGroupId -and $team.idpGroupName -and $team.idpGroupDescription) {
                    $idpBody = @{
                        groups = @(
                            @{
                                group_id = $team.idpGroupId
                                group_name = $team.idpGroupName
                                group_description = $team.idpGroupDescription
                            }
                        )
                    }
                    
                    try {
                        Invoke-GitHubApi -Method Patch -Uri "$apiUrl/orgs/$organization/teams/$teamSlug/team-sync/group-mappings" -Body $idpBody
                    }
                    catch {
                        Write-Warning "Warning: Could not set IDP group mapping: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Warning "Warning: Missing idpGroupId, idpGroupName, or idpGroupDescription, skipping idpGroupMembership"
                }
                
                Write-Host "✓ Team '$teamName' created successfully"
            }
            catch {
                Write-Error "✗ Error processing team '$teamName': $($_.Exception.Message)"
            }
        }
        
        Write-Host "Team processing completed"
    }
    catch {
        Write-Error "Fatal error: $($_.Exception.Message)"
        exit 1
    }
}

function Create-Repositories {
    try {
        # Read and parse CSV file
        $csvFilePath = Join-Path $PSScriptRoot "csv\repos.csv"
        Write-Host "Reading repository data from: $csvFilePath"
        
        if (-not (Test-Path $csvFilePath)) {
            Write-Error "Error: CSV file not found at $csvFilePath"
            exit 1
        }
        
        $repositories = Import-Csv -Path $csvFilePath
        Write-Host "Found $($repositories.Count) repositories to process"
        
        # Process each repository
        foreach ($repo in $repositories) {
            $repoName = if ($repo.name) { $repo.name } else { $repo.repository }
            
            if (-not $repoName) {
                Write-Warning "Warning: Repository name missing, skipping entry"
                continue
            }
            
            try {
                # Check if repository already exists
                $existingRepo = Invoke-GitHubApi -Method Get -Uri "$apiUrl/repos/$organization/$repoName"
                
                if ($existingRepo) {
                    Write-Host "✓ Repository '$repoName' already exists in $organization"
                    continue
                }
                
                # Repository doesn't exist, create it
                Write-Host "Creating repository '$repoName' in $organization..."
                
                $repoBody = @{
                    name = $repoName
                    description = if ($repo.description) { $repo.description } else { '' }
                    private = ($repo.private -eq 'true' -or $repo.private -eq $true)
                    auto_init = ($repo.auto_init -ne 'false')
                    allow_squash_merge = ($repo.allow_squash_merge -ne 'false')
                    allow_merge_commit = ($repo.allow_merge_commit -ne 'false')
                    allow_rebase_merge = ($repo.allow_rebase_merge -ne 'false')
                    delete_branch_on_merge = ($repo.delete_branch_on_merge -eq 'true')
                }
                
                $newRepo = Invoke-GitHubApi -Method Post -Uri "$apiUrl/orgs/$organization/repos" -Body $repoBody
                
                Write-Host "✓ Repository '$repoName' created successfully"
            }
            catch {
                Write-Error "✗ Error processing '$repoName': $($_.Exception.Message)"
            }
        }
        
        Write-Host "Repository processing completed"
    }
    catch {
        Write-Error "Fatal error: $($_.Exception.Message)"
        exit 1
    }
}

function Set-RepoPermissions {
    try {
        $csvFilePath = Join-Path $PSScriptRoot "csv\permissions.csv"
        Write-Host "Reading repo permissions data from: $csvFilePath"
        
        if (-not (Test-Path $csvFilePath)) {
            Write-Error "Error: CSV file not found at $csvFilePath"
            exit 1
        }
        
        $permissions = Import-Csv -Path $csvFilePath
        
        # Valid GitHub permission types for teams
        $validPermissions = @('pull', 'push', 'admin', 'maintain', 'triage')
        
        foreach ($record in $permissions) {
            $repoName = $record.repository
            $teamName = $record.team
            $permission = $record.permission
            
            if (-not $repoName -or -not $teamName -or -not $permission) {
                Write-Warning "Warning: Missing repository, team, or permission, skipping entry"
                continue
            }
            
            # Validate permission type
            if ($validPermissions -notcontains $permission) {
                Write-Warning "Warning: Invalid permission '$permission' for repo '$repoName' and team '$teamName', skipping entry"
                continue
            }
            
            # Validate repository exists
            $repoExists = $false
            try {
                $existingRepo = Invoke-GitHubApi -Method Get -Uri "$apiUrl/repos/$organization/$repoName"
                if ($existingRepo) {
                    $repoExists = $true
                }
            }
            catch {
                Write-Warning "Warning: Repository '$repoName' does not exist, skipping permission entry"
                continue
            }
            
            # Validate team exists
            $teamSlug = $teamName.ToLower() -replace ' ', '-'
            $teamExists = $false
            try {
                $existingTeam = Invoke-GitHubApi -Method Get -Uri "$apiUrl/orgs/$organization/teams/$teamSlug"
                if ($existingTeam) {
                    $teamExists = $true
                }
            }
            catch {
                Write-Warning "Warning: Team '$teamName' does not exist, skipping permission entry"
                continue
            }
            
            # Set permission if both exist
            if ($repoExists -and $teamExists) {
                try {
                    $permissionBody = @{
                        permission = $permission
                    }
                    
                    Invoke-GitHubApi -Method Put -Uri "$apiUrl/orgs/$organization/teams/$teamSlug/repos/$organization/$repoName" -Body $permissionBody
                    Write-Host "✓ Set '$permission' permission for team '$teamName' on repo '$repoName'"
                }
                catch {
                    Write-Error "✗ Error setting permission for team '$teamName' on repo '$repoName': $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host "Repository permissions processing completed"
    }
    catch {
        Write-Error "Fatal error: $($_.Exception.Message)"
        exit 1
    }
}

# Main execution
try {
    Create-Teams
    Create-Repositories
    Set-RepoPermissions
    Write-Host "GitHub automation script completed successfully"
}
catch {
    Write-Error "Script failed: $($_.Exception.Message)"
    exit 1
}
