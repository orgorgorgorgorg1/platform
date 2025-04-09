# Read and decode the CSV file
locals {
  repositorypermissions_csv = file("${path.root}/csv/repositorypermissions.csv")
  repositorypermissions     = csvdecode(local.repositorypermissions_csv)
}

resource "github_team_repository" "team_permissions" {
    for_each    = { for repo in local.repositorypermissions : repo.id => repo }
    team_id    = each.value.Group
    repository = each.value.Repository
    permission  = each.value.Permission_Level == "PROJECT_ADMIN" ? "admin" : "push"
 }