module "organization" {
  source = "./organization"
  github_enterprise_slug = var.github_enterprise_slug
  github_token = var.github_token
}

module "repositories" {
  source = "./repositories"
  github_token = var.github_token
}