module "organization" {
  source = "./organization"
  github_enterprise_slug = var.github_enterprise_slug
  github_token = var.github_token
}

module "repositories" {
  source = "./repositories"
  github_token = var.github_token
  github_organization = var.github_organization
}

module "teams" {
  source = "./teams"
  github_token = var.github_token
  github_organization = var.github_organization
}