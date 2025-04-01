provider "github" { 
  token = var.github_token
  owner = var.github_organization
}

# Read and decode the CSV file
locals {
  repositories_csv = file("${path.root}/csv/repos.csv")
  repositories     = csvdecode(local.repositories_csv)
}

# Create a GitHub repository for each row in the CSV
resource "github_repository" "repositories" {
  for_each    = { for repo in local.repositories : repo.id => repo }
  name        = each.value.Repository
  description = "placeholder"
  private     = true
}

resource "github_team_repository" "team_permissions" {
    for_each    = { for repo in local.repositories : repo.id => repo }
    team_id    = repo.value.Group
    repository = repo.value.Repository
    permission  = each.value.Permission_Level == "project_admin" ? "admin" : "push"
 }