# Docker Compose — Google Cloud Platform

Deploys a Docker Compose file to a Compute Engine instance.

## Features

- Built on top of Google's [Container Optimized OS](https://cloud.google.com/container-optimized-os)
- Enables the [Google Cloud logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) for improved container observability in Stackdriver
- Uses a supplemental cloud-init config to format and mount a persistent disk for storing Let's Encrypt certificates that persist beyond the life of the instance
- Creates a static IP and associates it with a Cloud DNS record
- Enables Traefik's [monitoring dashboard](https://docs.traefik.io/operations/dashboard/) and API (pointing to `traefik.<your-domain>`)

## Usage

```hcl
module "docker-server" {
  source = "../.."

  domain       = var.domain
  compose_file = file("${path.cwd}/docker-compose.yaml")

  enable_letsencrypt = true
  letsencrypt_email  = var.letsencrypt_email

  enable_traefik_api   = true
  traefik_api_user     = var.traefik_api_user
  traefik_api_password = var.traefik_api_password

  # https://docs.docker.com/config/containers/logging/gcplogs/
  docker_log_driver = "gcplogs"
  docker_log_opts   = { gcp-log-cmd = "true" }

  # custom instance configuration can be provided by providing supplemental cloud-init config(s)
  cloudinit_part = [{
    content_type = "text/cloud-config"
    content = local.cloudinit_disk
  }]
}

# prepare persistent disk

locals {
  cloudinit_disk = <<EOT
#cloud-config

bootcmd:
  - fsck.ext4 -tvy /dev/sdb || mkfs.ext4 /dev/sdb
  - mkdir -p /run/app
  - mount -o defaults -t ext4 /dev/sdb /run/app

EOT
}
```

# Terraform

## Inputs

| Name                 | Description                                                                                          | Type     | Default | Required |
| -------------------- | ---------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| cloud_dns_zone       | Cloud DNS zone name.                                                                                 | `string` | n/a     |   yes    |
| domain               | The domain where the app will be hosted.                                                             | `string` | n/a     |   yes    |
| letsencrypt_email    | Email address used when registering certificates with Let's Encrypt.                                 | `string` | n/a     |   yes    |
| network_name         | The name of the network where the instance will be created.                                          | `string` | n/a     |   yes    |
| project              | The ID of the project in which to provision resources.                                               | `string` | n/a     |   yes    |
| region               | Google Cloud region where the instance will be created.                                              | `string` | n/a     |   yes    |
| subnetwork_name      | The name of the subnet where the instance will be created.                                           | `string` | n/a     |   yes    |
| traefik_api_password | Password to access Traefik dashboard (basic auth). Must be hashed following the `htpasswd` standard. | `string` | n/a     |   yes    |
| traefik_api_user     | Username to access Traefik dashboard (basic auth).                                                   | `string` | n/a     |   yes    |
| zone                 | Google Cloud region zone where the instance will be created.                                         | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
