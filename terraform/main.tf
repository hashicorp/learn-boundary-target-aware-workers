terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.0.5"
    }
  }
}

provider "boundary" {
  addr             = "http://127.0.0.1:9200"
  recovery_kms_hcl = <<EOT
kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_recovery"
}
EOT
}

variable "users" {
  type = set(string)
  default = [
    "user1",
  ]
}

resource "boundary_scope" "global" {
  global_scope = true
  name         = "global"
  scope_id     = "global"
}

resource "boundary_scope" "org" {
  scope_id    = boundary_scope.global.id
  name        = "primary"
  description = "Primary organization scope"
}

resource "boundary_scope" "project" {
  name                     = "databases"
  description              = "Databases project"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_user" "user" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account.user[each.value].id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_auth_method" "password" {
  name        = "org_password_auth"
  description = "Password auth method for org"
  type        = "password"
  scope_id    = boundary_scope.org.id
}

resource "boundary_account" "user" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  type           = "password"
  login_name     = lower(each.key)
  password       = "password"
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_role" "global_anon_listing" {
  scope_id = boundary_scope.global.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}

resource "boundary_role" "org_anon_listing" {
  scope_id = boundary_scope.org.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}
resource "boundary_role" "org_admin" {
  scope_id       = "global"
  grant_scope_id = boundary_scope.org.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}

resource "boundary_role" "proj_admin" {
  scope_id       = boundary_scope.org.id
  grant_scope_id = boundary_scope.project.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}

resource "boundary_host_catalog" "databases" {
  name        = "databases"
  description = "Database targets"
  type        = "static"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host" "localhost" {
  type            = "static"
  name            = "localhost"
  description     = "Localhost host"
  address         = "localhost"
  host_catalog_id = boundary_host_catalog.databases.id
}

# Target hosts available on localhost: ssh and postgres
# Postgres is exposed to localhost for debugging of the 
# Boundary DB from the CLI. Assumes SSHD is running on
# localhost.
resource "boundary_host_set" "local" {
  type            = "static"
  name            = "local"
  description     = "Host set for local servers"
  host_catalog_id = boundary_host_catalog.databases.id
  host_ids        = [boundary_host.localhost.id]
}

resource "boundary_target" "ssh" {
  type                     = "tcp"
  name                     = "ssh"
  description              = "SSH server"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  session_max_seconds      = 2
  default_port             = 22
  host_set_ids = [
    boundary_host_set.local.id
  ]
}

resource "boundary_target" "db" {
  type                     = "tcp"
  name                     = "boundary-db"
  description              = "Boundary Postgres server"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  session_max_seconds      = 2
  default_port             = 5432
  host_set_ids = [
    boundary_host_set.local.id
  ]
}

resource "boundary_host" "postgres" {
  type        = "static"
  name        = "postgres"
  description = "Private postgres container"
  # DNS set via docker-compose
  address         = "postgres"
  host_catalog_id = boundary_host_catalog.databases.id
}

resource "boundary_host_set" "postgres" {
  type            = "static"
  name            = "postgres"
  description     = "Host set for postgres containers"
  host_catalog_id = boundary_host_catalog.databases.id
  host_ids        = [boundary_host.postgres.id]
}

resource "boundary_target" "postgres" {
  type                     = "tcp"
  name                     = "postgres"
  description              = "postgres server"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  session_max_seconds      = 20
  default_port             = 5432
  host_set_ids = [
    boundary_host_set.postgres.id
  ]
  // worker_filter             = "\"/name\" == \"worker1\""
  // worker_filter_unformatted = "/name" == "worker1" # Unformatted filter, don't uncomment
}

resource "boundary_host" "redis" {
  type        = "static"
  name        = "redis"
  description = "Private redis container"
  # DNS set via docker-compose
  address         = "redis"
  host_catalog_id = boundary_host_catalog.databases.id
}

resource "boundary_host_set" "redis" {
  type            = "static"
  name            = "redis"
  description     = "Host set for redis containers"
  host_catalog_id = boundary_host_catalog.databases.id
  host_ids        = [boundary_host.redis.id]
}

resource "boundary_target" "redis" {
  type                     = "tcp"
  name                     = "redis"
  description              = "Redis server"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  session_max_seconds      = 20
  default_port             = 6379
  host_set_ids = [
    boundary_host_set.redis.id
  ]
  // worker_filter             = "\"us-west-1\" in \"/tags/region\" or \"redis\" in \"/tags/type\""
  // worker_filter_unformatted = "us-west-1" in "/tags/region" or "redis" in "/tags/type" # Unformatted filter, don't uncomment
}

resource "boundary_host" "mysql" {
  type        = "static"
  name        = "mysql"
  description = "Private mysql container"
  # DNS set via docker-compose
  address         = "mysql"
  host_catalog_id = boundary_host_catalog.databases.id
}

resource "boundary_host_set" "mysql" {
  type            = "static"
  name            = "mysql"
  description     = "Host set for mysql containers"
  host_catalog_id = boundary_host_catalog.databases.id
  host_ids        = [boundary_host.mysql.id]
}

resource "boundary_target" "mysql" {
  type                     = "tcp"
  name                     = "mysql"
  description              = "MySQL server"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  session_max_seconds      = 100
  default_port             = 3306
  host_set_ids = [
    boundary_host_set.mysql.id
  ]
  worker_filter                = "\"/name\" == \"bad filter\""
  // worker_filter             = "\"/name\" == \"worker1\" or (\"prod\" in \"/tags/type\" and \"database\" in \"/tags/type\")"
  // worker_filter_unformatted = "/name" == "worker1" or ("prod" in "/tags/type" and "database" in "/tags/type")" # Unformatted filter, don't uncomment
}