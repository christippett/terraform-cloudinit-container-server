output "cloud_config" {
  description = "Content of the cloud-init config to be deployed to a server."
  value       = data.cloudinit_config.config.rendered
}

output "compose_config" {
  description = "Docker Compose service config."
  value       = local.compose_config
}

output "environment" {
  value     = local.env
  sensitive = true
}

output "traefik_admin_password" {
  value     = local.traefik_admin_password
  sensitive = true
}
