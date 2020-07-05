# Docker Image — Azure

Deploys a single Docker image to an Azure Linux VM.

## Usage

```hcl
module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "container-server"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = "Standard_F2"
  admin_username      = "adminuser"

  custom_data = base64encode(module.container-server.cloud_config) # 👈

  network_interface_ids = [
    azurerm_network_interface.app.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

```

# Terraform

## Inputs

| Name               | Description                                                          | Type     | Default | Required |
| ------------------ | -------------------------------------------------------------------- | -------- | ------- | :------: |
| domain             | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email              | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| base_resource_name | Used for resource group, DNS name, etc.                              | `string` | n/a     |   yes    |
| location           | Azure location to which resources should be deployed.                | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
