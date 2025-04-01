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
  for_each    = { for repo in local.repositories : repo.Repository => repo }
  name        = each.value.name
  description = each.value.description
  private     = each.value.private
}

resource "github_team_repository" "team_permissions" {
    for_each    = { for repo in local.repositories : repo.Repository => repo }
    team_id    = repo.value.group
    repository = repo.value.name
    permission  = each.value.type == "project_admin" ? "admin" : "push"
 }