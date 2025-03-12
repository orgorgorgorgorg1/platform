provider "github" { 
  token = var.github_token
  //for rotterdam, probably have to set base_url to the version that supports data locality
}

resource "github_enterprise_organization" "red" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "red"
  display_name  = "red"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "green" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "green"
  display_name  = "green"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "sandbox" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "archive"
  display_name  = "Some Awesome Org"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "archive" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "sandbox"
  display_name  = "Some Awesome Org"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

data "github_enterprise" "example" {
  slug = var.github_enterprise_slug
}
