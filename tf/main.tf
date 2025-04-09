module "repositories" {
  source = "./repositories"
  # github_token = var.github_token
  # github_organization = var.github_organization
}

module "teams" {
  source = "./teams"
  # github_token = var.github_token
  # github_organization = var.github_organization
}

module "repositorypermissions" {
  source = "./repositorypermissions"
  github_token = var.github_token
  github_organization = var.github_organization
}