output "cloud_config" {
  description = "Content of the cloud-init config to be deployed to a server."
  value       = data.cloudinit_config.config.rendered
}

output "environment_variables" {
  value = local.dot_env_data
}

output "included_files" {
  value = [for f in local.files : f.filename]
}

output "docker_compose_config" {
  description = "Content of the Docker Compose config to be deployed to a server."
  value       = join("\n---\n", [for f in local.docker_compose_files : base64decode(f.content)])
}
