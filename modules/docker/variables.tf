variable "daemon_config" {
  description = "JSON string content for `/etc/docker/daemon.json`"
  type        = string
  default     = null
}
