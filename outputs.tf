output "cloud_config" {
  description = "Content of the cloud-init config to be deployed to a server."
  value       = data.cloudinit_config.config.rendered
}

output "environment" {
  value = local.env
}

output "files" {
  value = local.files
}

output "services" {
  value = local.compose_services
}

output "docker_compose_config" {
  description = "Docker Compose service config."
  value       = local.compose_config
}
