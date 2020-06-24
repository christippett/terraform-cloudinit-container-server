output "cloud_config" {
  description = "Content of the cloud-init config to be deployed to the server."
  value       = data.cloudinit_config.config.rendered
}

output "docker_compose_config" {
  description = "Content of the Compose file to be deployed to the server."
  value       = data.template_file.docker_compose.rendered
}
