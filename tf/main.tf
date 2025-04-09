module "repositories" {
  source = "./repositories"
  # providers = {
  #   github = github
  # }  
  # github_token = var.github_token
  # github_organization = var.github_organization
}

module "teams" {
  source = "./teams"
  # providers = {
  #   github = github
  # }
  # github_token = var.github_token
  # github_organization = var.github_organization
}

module "repositorypermissions" {
  source = "./repositorypermissions"
  # providers = {
  #   github = github
  # }
  depends_on = [module.repositories, module.teams]
}