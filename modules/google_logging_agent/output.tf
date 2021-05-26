output "config" {
  value = local.config
}

output "cloudinit_config" {
  value = data.cloudinit_config.config
}
