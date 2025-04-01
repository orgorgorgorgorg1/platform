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
  visibility  = "private"
}

resource "github_team_repository" "team_permissions" {
    for_each    = { for repo in local.repositories : repo.id => repo }
    team_id    = each.value.Group
    repository = each.value.Repository
    permission  = each.value.Permission_Level == "PROJECT_ADMIN" ? "admin" : "push"
 }