variable "daemon_config" {
  description = <<-EOT
  Docker daemon configuration options. Refer https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file
  EOT

  type    = any
  default = null
}

variable "compose_version" {
  description = "Docker Compose version to install"
  type        = string
  default     = "v2.2.2"
  nullable    = true
}
