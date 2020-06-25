# Simple Container Server w/ Terraform & cloud-init

[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/christippett/terraform-cloudinit-container-server?label=version)](./CHANGELOG.md) [![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4)](https://registry.terraform.io/modules/christippett/container-server/cloudinit/)

A batteries included [cloud-init](https://cloud-init.io) config to quickly and easily deploy a single Docker image or Docker Compose file to any Cloud™ virtual machine.

> [**What is cloud-init?**](https://github.com/canonical/cloud-init)
>
> _Cloud-init is the industry standard multi-distribution method for cross-platform cloud instance initialization. It is supported across all major public cloud providers, provisioning systems for private cloud infrastructure, and bare-metal installations._
>
> _Cloud-init will identify the cloud it is running on during boot, read any provided metadata from the cloud and initialize the system accordingly. This may involve setting up network and storage devices to configuring SSH access key and many other aspects of a system. Later on cloud-init will also parse and process any optional user or vendor data that was passed to the instance._

The module takes things one step further by bootstrapping an environment that hosts your containers with minimal fuss. All credit goes to the creators of cloud-init and Traefik for making this so easy.

# Features

- ☁️ This module is compatible with most major cloud providers:
  - **AWS** ([see example](./examples/aws-docker-image-simple/))
    - Cost: USD\$4.76/month <span style="font-size: 0.75em; opacity: 0.5; margin-left: 0.5rem">_t3a.micro • 2vCPU/1GB • 10GB HDD_</span>
  - **Google Cloud Platform** ([see example](./examples/digitalocean-docker-image-simple/))
    - Cost: USD\$6.11/month <span style="font-size: 0.75em; opacity: 0.5; margin-left: 0.5rem">_e2.micro • 0.25vCPU/1GB • 10GB HDD_</span>
  - **DigitalOcean** ([see example](./examples/gcp-docker-image-simple/))
    - Cost: USD\$6.00/month <span style="font-size: 0.75em; opacity: 0.5; margin-left: 0.5rem">_Standard Droplet • 1vCPU/1GB • 10 HD_</span>
  - **Azure**
    - Cost: USD\$14.73/month <span style="font-size: 0.75em; opacity: 0.5; margin-left: 0.5rem">_A0 • 1vCPU/0.75GB • 32GB HDD)_</span>
  - _(and theoretically any other platform that supports cloud-init)_
- 🌐 Installs and configures **Traefik** under-the-hood as the reverse proxy for your container(s)
- 🔑 Generates and renews SSL/TLS certificates automatically from **Let's Encrypt**.
- 📝 Gives you the option to provide supplementary **cloud-init** config file(s) to further customise the setup of your instances ([example](./examples/gcp-docker-compose-advanced/main.tf)).

# Requirements

The only two dependencies are for Docker and `systemd` to be installed on whatever virtual machine you're deploying to.

The following operating systems have been test successfully:

- [Google's Container Optimized OS](https://cloud.google.com/container-optimized-os)
- [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/)
- [Ubuntu 18.04 (via DigitalOcean's Marketplace)](https://marketplace.digitalocean.com/apps/docker)

# Usage

The output of this module is the content of a cloud-init configuration file with everything needed to setup a VM and run your container(s). Use this as input into one of either `user_data` (AWS / DigitalOcean), `metadata.user-data` (Google Cloud) or `custom_data` (Azure) when creating a virtual machine.

Some providers expect this value to be base64 encoded, refer to the Terraform documentation below for details relevant to your cloud provider of choice:

- [AWS Documentation](https://www.terraform.io/docs/providers/aws/r/instance.html#user_data)
- [Google Cloud Documentation](https://www.terraform.io/docs/providers/google/r/compute_instance.html#metadata)
- [Azure Documentation](https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html#custom_data)
- [DigitalOcean Documentation](https://www.terraform.io/docs/providers/do/r/droplet.html#user_data)

## Module Definition — Single Container

The easiest way to get a container up and running is to specify an `image` and the `ports` to expose as part of the `container` input variable. The `container` variable can accept any attribute found under Docker Compose's `service` configuration ([docs](https://docs.docker.com/compose/compose-file/#service-configuration-reference)), but in most cases `image` and `ports` are all that's need to get started.

Let's Encrypt is enabled by default, so we also provide a `domain` and `letsencrypt_email`.

```hcl
module "docker-server" {
  source  = "christippett/container-server/cloudinit"
  version = "1.0.0"

  domain            = "example.com"
  letsencrypt_email = "me@example.com

  container = {
    image   = "nginxdemos/hello"
    ports   = ["80"]
  }
}
```

## Module Definition — Docker Compose

Choosing to use a Docker Compose file (`docker-compose.yaml`) provides greater flexibility with regards to how your containers are deployed, but requires you to manually configure your services to work with Traefik.

```hcl
module "docker-server" {
  source  = "christippett/container-server/cloudinit"
  version = "1.0.0"

  domain            = "example.com"
  letsencrypt_email = "me@example.com

  compose_file = file("docker-compose.yaml")
}
```

Traefik is a wonderful tool with a lot of functionality and configuration options, however it can be a bit intimidating to set up if you're not familiar with it. The four labels shown in the `docker-compose.yaml` file below are all you need to get a container up and running. These labels need to be added for every service defined in your Docker Compose file that you want to make available externally.

For more advanced options, refer to the official [Traefik documentation](https://docs.traefik.io/).

```yaml
# docker-compose.yaml

version: "3"

services:
  hello-world:
    restart: unless-stopped
    image: nginxdemos/hello
    ports:
      - "80"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.hello-world.rule=Host(`${domain}`)"
      - "traefik.http.routers.hello-world.entrypoints=websecure"
      - "traefik.http.routers.hello-world.tls=true"
      - "traefik.http.routers.hello-world.tls.certresolver=letsencrypt"
networks:
  default:
    external:
      name: web
```

### Note:

- 🔗 Traefik connects to services over the `web` Docker network by default — this network must be added for all service(s) you want exposed.
- 🔒 Let's Encrypt is configured using the `letsencrypt` certificate resolver from Traefik. Refer to the example `docker-compose.yaml` file above for the labels used to enable and configure this feature.
- 📋 Terraform shares the same variable interpolation syntax as Docker Compose's environment variables. We leverage this fact by parsing `docker-compose.yaml` as a Terraform template, providing both `${domain}` and `${letsencrypt_email}` as template variables. These can be used to parameterise your Docker Compose file without impacting its compatibility with other applications (such as running `docker-compose` locally).
- 📊 The module provides an option for enabling Traefik's [monitoring dashboard](https://docs.traefik.io/operations/dashboard/) and API. When enabled, the dashboard is accessible from `https://traefik.${domain}/dashboard/` and the API from `https://traefik.${domain}/api/`. The **traefik** sub-domain is currently hard-coded and cannot be changed. Don't forget to create the corresponding DNS record for the dashboard and API to be accessible.

# Integration w/ Cloud Providers

## AWS

```hcl
resource "aws_instance" "vm" {
  ami             = "ami-0560993025898e8e8" # Amazon Linux 2
  instance_type   = "t2.micro"
  security_groups = ["sg-allow-everything-from-anywhere"]

  tags = {
    Name = "container-server"
  }

  user_data = module.docker-server.cloud_config # 👈
}

```

## Google Cloud

```hcl
resource "google_compute_instance" "vm" {
  name         = "container-server"
  project      = "my-project"
  zone         = "australia-southeast1
  machine_type = "e2-small"
  tags         = ["http-server", "https-server"]

  metadata = {
    user-data = module.docker-server.cloud_config # 👈
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = "vpc"
    subnetwork_project = "my-project"

    access_config {
      // Ephemeral IP
    }
  }
}

```

## Azure

```hcl
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
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

```

## DigitalOcean

```hcl
resource "digitalocean_droplet" "vm" {
  name   = "container-server"
  image  = "docker-18-04"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  user_data = module.docker-server.cloud_config # 👈
}
```

# Terraform Documentation

## Inputs

| Name                       | Description                                                                                                                                                                        | Type                                                        | Default       | Required |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------- | :------: |
| domain                     | The domain to deploy applications under.                                                                                                                                           | `string`                                                    | n/a           |   yes    |
| letsencrypt_email          | The email address used for requesting certificates from Lets Encrypt.                                                                                                              | `string`                                                    | n/a           |   yes    |
| cloudinit_part             | Supplementary cloud-init config used to customise the instance.                                                                                                                    | `list(object({ content_type : string, content : string }))` | `[]`          |    no    |
| compose_file               | The content of a Compose file used to deploy one or more services to the server. Either `container` or `compose_file` must be specified.                                           | `string`                                                    | `null`        |    no    |
| container                  | The container definition used to deploy a Docker image to the server. Follows the same schema as a Docker Compose service. Either `container` or `compose_file` must be specified. | `any`                                                       | `{}`          |    no    |
| docker_log_driver          | Custom Docker log driver (e.g. `gcplogs`).                                                                                                                                         | `string`                                                    | `"json-file"` |    no    |
| docker_log_opts            | Additional arguments/options for Docker log driver.                                                                                                                                | `map`                                                       | `{}`          |    no    |
| enable_letsencrypt         | Whether Lets Encrypt certificates should be automatically generated.                                                                                                               | `bool`                                                      | `true`        |    no    |
| enable_traefik_api         | Whether the Traefik dashboard and API should be enabled.                                                                                                                           | `bool`                                                      | `false`       |    no    |
| letsencrypt_staging_server | Whether to use the Lets Encrypt staging server (useful for testing).                                                                                                               | `bool`                                                      | `false`       |    no    |
| traefik_api_password       | The password used to access the Traefik dashboard + API.                                                                                                                           | `string`                                                    | `null`        |    no    |
| traefik_api_user           | The username used to access the Traefik dashboard + API.                                                                                                                           | `string`                                                    | `"admin"`     |    no    |
| traefik_version            | The version of Traefik used by the server.                                                                                                                                         | `string`                                                    | `"v2.2"`      |    no    |

## Outputs

| Name                  | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| cloud_config          | Content of the cloud-init config to be deployed to a server.     |
| docker_compose_config | Content of the Docker Compose config to be deployed to a server. |
