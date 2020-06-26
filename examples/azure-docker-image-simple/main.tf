module "docker-server" {
  source = "../.."

  domain            = "portainer.${var.domain}"
  letsencrypt_email = var.letsencrypt_email

  container = {
    image   = "portainer/portainer"
    command = "--admin-password ${replace(var.portainer_password, "$", "$$")}"
    ports   = ["9000"]
    volumes = ["/var/run/docker.sock:/var/run/docker.sock:ro"]
  }
}

resource "azurerm_resource_group" "example" {
  name     = var.base_resource_name
  location = var.location
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "container-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"

  custom_data = base64encode(module.docker-server.cloud_config) # 👈

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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

  tags = {
    Name = "portainer"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "${var.base_resource_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = var.base_resource_name
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmpubip.id
  }
}

resource "azurerm_public_ip" "vmpubip" {
  name                = "${var.base_resource_name}-vmpubip"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  domain_name_label   = var.base_resource_name
}

resource "azurerm_virtual_network" "example" {
  name                = var.base_resource_name
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "example" {
  name                 = var.base_resource_name
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = cidrsubnet(azurerm_virtual_network.example.address_space[0], 16, 1)
}
