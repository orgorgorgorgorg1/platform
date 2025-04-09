# Read and decode the CSV file
locals {
  teams_csv = file("${path.root}/csv/teams.csv")
  teams     = csvdecode(local.teams_csv)
}

resource "github_team" "teams" {
  for_each    = { for team in local.teams : team.name => team }
  name        = each.value.name
  description = each.value.description
}