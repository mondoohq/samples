data "okta_everyone_group" "everyone_group" {}

data "okta_groups" "default" {}

// GROUPS

resource "okta_group" "super_admins" {
  name        = "Super Admins"
  description = "Super Admin groups"
}

resource "okta_group_role" "super_admins_role" {
  group_id  = okta_group.super_admins.id
  role_type = "SUPER_ADMIN"
}

resource "okta_group" "org_admins" {
  name        = "Org Admins"
  description = "Org admin group"
}

resource "okta_group_role" "org_admin_role" {
  group_id  = okta_group.org_admins.id
  role_type = "ORG_ADMIN"
}


resource "okta_group" "developers" {
  name        = "Developers"
  description = "Developer group"
}

resource "okta_group_role" "dev_app_admin_role" {
  group_id  = okta_group.developers.id
  role_type = "APP_ADMIN"
}

resource "okta_group_memberships" "dev" {
  group_id = okta_group.developers.id
  users = [
    okta_user.jane_doe.id,
  ]
}

resource "okta_group" "api_admins" {
  name        = "API Admins"
  description = "API admin groups"
}

resource "okta_group_role" "api_admin_role" {
  group_id  = okta_group.api_admins.id
  role_type = "API_ACCESS_MANAGEMENT_ADMIN"
}

resource "okta_group_memberships" "api_admins" {
  group_id = okta_group.api_admins.id
  users = [
    okta_user.jane_doe.id,
  ]
}

// USERS

resource "okta_user" "jane_doe" {
  first_name = "Jane"
  last_name  = "Doe"
  login      = "jdoe@example.com"
  email      = "jdoe@example.com"
}

output "groups" {
  value = data.okta_groups.default.groups
}