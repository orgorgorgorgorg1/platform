module "repositories" {
  source = "./repositories"
}

module "teams" {
  source = "./teams"
}

module "repositorypermissions" {
  source = "./repositorypermissions"
  depends_on = [module.repositories, module.teams]
}