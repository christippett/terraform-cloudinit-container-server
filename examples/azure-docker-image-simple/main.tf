module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

resource "azurerm_resource_group" "app" {
  name     = var.base_resource_name
  location = var.location
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "container-server"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = "Standard_F2"
  admin_username      = "adminuser"

  custom_data = base64encode(module.container-server.cloud_config)

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

resource "azurerm_network_interface" "app" {
  name                = "${var.base_resource_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  ip_configuration {
    name                          = var.base_resource_name
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app.id
  }
}

resource "azurerm_public_ip" "app" {
  name                = "${var.base_resource_name}-vmpubip"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  allocation_method   = "Static"
  domain_name_label   = var.base_resource_name
}

resource "azurerm_virtual_network" "app" {
  name                = var.base_resource_name
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "app" {
  name                 = var.base_resource_name
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefix       = cidrsubnet(azurerm_virtual_network.app.address_space[0], 16, 1)
}
