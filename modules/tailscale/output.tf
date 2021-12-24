output "config" {
  value = data.cloudinit_config.config.part
}

output "user_data" {
  value = data.cloudinit_config.config.rendered
}
