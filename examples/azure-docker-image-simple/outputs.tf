output "docker_compose_config" {
  value = module.container-server.docker_compose_config
}

output "vm_fqdn" {
  value = azurerm_public_ip.app.fqdn
}
