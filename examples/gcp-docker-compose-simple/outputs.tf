output "cloud_config" {
  description = "Content of the cloud-init config to be deployed to a server."
  value       = module.container-server.cloud_config
}

output "docker_compose_config" {
  description = "Content of the Docker Compose config to be deployed to a server."
  value       = module.container-server.docker_compose_config
}

output "environment_variables" {
  value = module.container-server.environment_variables
}

output "included_files" {
  value = module.container-server.included_files
}
