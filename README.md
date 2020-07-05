# Simple Container Server w/ Terraform & Cloud-Init

[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/christippett/terraform-cloudinit-container-server?label=Version)](./CHANGELOG.md) [![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4)](https://registry.terraform.io/modules/christippett/container-server/cloudinit/)

A batteries included [cloud-init](https://cloud-init.io) config to quickly and easily deploy a single Docker image or Docker Compose file to any Cloud™ virtual machine. No external dependencies, no fancy framework, just good ol' fashioned `docker` and `systemd`.

> [**What is cloud-init?**](https://github.com/canonical/cloud-init)
>
> _Cloud-init is the industry standard multi-distribution method for cross-platform cloud instance initialization. It is supported across all major public cloud providers, provisioning systems for private cloud infrastructure, and bare-metal installations._
>
> _Cloud-init will identify the cloud it is running on during boot, read any provided metadata from the cloud and initialize the system accordingly. This may involve setting up network and storage devices to configuring SSH access key and many other aspects of a system. Later on cloud-init will also parse and process any optional user or vendor data that was passed to the instance._

The module takes things one step further by bootstrapping an environment that hosts your containers with minimal fuss. All credit goes to the creators of cloud-init and Traefik for making this so easy.

# Features

- ☁️ This module is compatible with most major cloud providers:
  - **AWS** ([see example](./examples/aws-docker-image-simple/))
  - **Google Cloud Platform** ([see example](./examples/digitalocean-docker-image-simple/))
  - **DigitalOcean** ([see example](./examples/gcp-docker-image-simple/))
  - **Azure** ([see example](./examples/azure-docker-image-simple))
  - _(and theoretically any other platform that supports cloud-init)_
- 🌐 Installs and configures **Traefik** under-the-hood as the reverse proxy for your container(s)
- 🔑 Generates and renews SSL/TLS certificates automatically using **Let's Encrypt**.
- 📝 Gives you the option to provide supplementary **cloud-init** config file(s) to further customise the setup of your instances ([see example](./examples/gcp-docker-compose-advanced/main.tf)).

# Why?

Even the most basic and cheapest of VMs are capable of running _a lot_ of containers. As fantastic as the cloud's PaaS and serverless offerings are, it's sometimes easier to orchestrate several containers without having to mess with IAM, networking, service inter-dependencies etc. Having all your containers colocated on the same machine using Docker Compose can be a more manageable solution. The use-case for this module is for small hobby projects, POCs and other experimental workloads.

Below are the going rates for a cheap VM running on each of the major cloud providers. These instances are more than capable of running dozens of containers, especially if they're not receiving much traffic.

- **AWS**
  - **Cost:** USD\$4.76/month<br />
    _t3a.micro • 2vCPU/1GB • 10GB HDD_
- **Google Cloud Platform**
  - **Cost:** USD\$6.11/month\*\*<br />
    _e2.micro • 0.25vCPU/1GB • 10GB HDD_
- **DigitalOcean**
  - **Cost:** USD\$6.00/month\*\*<br />
    _Standard Droplet • 1vCPU/1GB • 10 HDD_
- **Azure**
  - **Cost:** USD\$14.73/month\*\*<br />
    _A0 • 1vCPU/0.75GB • 32GB HDD_

# Requirements

The only two dependencies are for `docker` and `systemd` to be available on whatever virtual machine you're deploying to.

The following operating systems have been tested successfully:

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

The easiest way to get a container up and running is to specify an `image` within the `container` input variable. The `container` variable can accept any attribute found under Docker Compose's `service` configuration ([docs](https://docs.docker.com/compose/compose-file/#service-configuration-reference)), but in most cases `image` and `ports` are all that's need to get started.

Let's Encrypt is enabled by default, so we also provide a `domain` and `email`.

```hcl
module "container-server" {
  source  = "christippett/container-server/cloudinit"
  version = "~> 1.1"

  domain = "example.com"
  email  = "me@example.com"

  container = {
    image   = "nginxdemos/hello"
  }
}
```

## Module Definition — Docker Compose

Choosing to use a Docker Compose file (`docker-compose.yaml`) provides greater flexibility with regards to how your containers are deployed, but requires you to manually configure the labels required by Traefik for each of your service(s).

```hcl
module "container-server" {
  source  = "christippett/container-server/cloudinit"
  version = "~> 1.0"

  domain = "example.com"
  email  = "me@example.com"

  files = [{ filename = "docker-compose.yaml", content  = filebase64("${path.module}/assets/docker-compose.yaml") }]
}
```

Traefik is a wonderful tool with a lot of functionality and configuration options, however it can be a bit intimidating to set up if you're not familiar with it. The four labels shown in the `docker-compose.yaml` file below are all you need to get a container up and running. These labels need to be added for every service defined in your Docker Compose file that you want to make available externally.

For more advanced options, refer to the official [Traefik documentation](https://docs.traefik.io/).

```yaml
# docker-compose.yaml

version: "3"

services:
  portainer:
    restart: unless-stopped
    image: portainer/portainer:latest
    command: --admin-password ${PORTAINER_PASSWORD}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`${domain}`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls=true"
      - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
networks:
  default:
    external:
      name: web
```

### Note:

- 🔗 Traefik connects to services over the `web` Docker network by default — this network must be added for all service(s) you want exposed.
- 🔒 Let's Encrypt is configured using the `letsencrypt` certificate resolver from Traefik. Refer to the example `docker-compose.yaml` file above for the labels used to enable and configure this feature.
- 📋 Almost all configuration options are defined as environment variables and saved as a `.env` file on the virtual machine. These values are read by Docker Compose on start-up and can be used to parameterise your Docker Compose file without impacting its use in other environments (such as running `docker-compose` locally).
- 📊 The module provides an option for enabling Traefik's [monitoring dashboard](https://docs.traefik.io/operations/dashboard/) and API. When enabled, the dashboard is accessible from `https://${domain}:9000/dashboard/` and the API from `https://${domain}:9000/api/`. The port used by Traefik can be customised using the `TRAEFIK_OPS_PORT` environment variable.

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

  user_data = module.container-server.cloud_config # 👈
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
    user-data = module.container-server.cloud_config # 👈
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = "vpc"
    subnetwork_project = "my-project"

    access_config { }
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

  custom_data = base64encode(module.container-server.cloud_config) # 👈

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

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

  user_data = module.container-server.cloud_config # 👈
}
```

# Terraform Documentation

## Inputs

| Name                | Description                                                                                                                    | Type                                                        | Default | Required |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- | ------- | :------: |
| domain              | The domain to deploy applications under.                                                                                       | `string`                                                    | n/a     |   yes    |
| email               | The email address used for requesting certificates from Lets Encrypt.                                                          | `string`                                                    | n/a     |   yes    |
| cloudinit_part      | Supplementary cloud-init config used to customise the instance.                                                                | `list(object({ content_type : string, content : string }))` | `[]`    |    no    |
| container           | The container definition used to deploy a Docker image to the server. Follows the same schema as a Docker Compose service.     | `any`                                                       | `{}`    |    no    |
| enable_webhook      | Flag whether to enable the webhook endpoint on the server, allowing updates to be made independent of Terraform.               | `bool`                                                      | `false` |    no    |
| env                 | A list environment variables provided as key/value pairs. These can be used to interpolate values within Docker Compsoe files. | `map(string)`                                               | `{}`    |    no    |
| files               | A list of files to upload to the server. Content must be base64 encoded. Files are available under the `/run/app/` directory.  | `list(object({ filename : string, content : string }))`     | `[]`    |    no    |
| letsencrypt_staging | Boolean flag to decide whether the Let's Encrypt staging server should be used.                                                | `bool`                                                      | `false` |    no    |

## Outputs

| Name                  | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| cloud_config          | Content of the cloud-init config to be deployed to a server.     |
| docker_compose_config | Content of the Docker Compose config to be deployed to a server. |
| environment_variables | n/a                                                              |
| included_files        | n/a                                                              |
