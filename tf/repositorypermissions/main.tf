# Read and decode the CSV file
locals {
  repositories_csv = file("${path.root}/csv/repositorypermissions.csv")
  repositories     = csvdecode(local.repositories_csv)
}

resource "github_team_repository" "team_permissions" {
    for_each    = { for permission in local.repositories : permission.id => permission }
    team_id    = each.value.Group
    repository = each.value.Repository
    permission  = each.value.Permission_Level == "PROJECT_ADMIN" ? "admin" : "push"
 }