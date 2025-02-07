provider "github" { 
  token = var.github_token
  organization = var.github_organization
}

resource "github_repository" "example-repo" {
  name = "example-repo"
  description = "New Repository"
}

resource "github_team" "example-team" {
  name        = "example-team"
  description = "My new team for use with Terraform"
  privacy     = "closed"
}

resource "github_team_repository" "example-team-repo" {
  team_id    = "${github_team.example-team.id}"
  repository = "${github_repository.example-repo.name}"
  permission = "push"
}