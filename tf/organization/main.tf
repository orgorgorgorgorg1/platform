resource "github_enterprise_organization" "red" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "tyrone2-org-red"
  display_name  = "tyrone-org-red"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "green" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "tyrone2-org-green"
  display_name  = "tyrone-org-green"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "sandbox" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "tyrone2-org-archive"
  display_name  = "tyrone99-org-archive"
  description   = "Hoihoi"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

resource "github_enterprise_organization" "archive" {
  enterprise_id = data.github_enterprise.enterprise.id
  name          = "tyrone2-org-sandbox"
  display_name  = "tyrone-org-sandbox"
  description   = "Organization created with terraform"
  billing_email = "tvriesde@gmail.com"
  admin_logins  = [
    "tvriesde"
  ]
}

data "github_enterprise" "enterprise" {
  slug = var.github_enterprise_slug
}
