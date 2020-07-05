# Docker Image — Google Cloud Platform

Deploys a single Docker image to a Compute Engine instance.

## Usage

```hcl
module "container" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.letsencrypt_email

  letsencrypt_staging = true # delete this or set to false to enable production Let's Encrypt certificates

  files = [
    {
      filename = "docker-compose.yaml"
      content  = filebase64("${path.module}/assets/docker-compose.yaml")
    },
    # https://docs.traefik.io/v2.0/middlewares/basicauth/#usersfile
    {
      filename = "users"
      content  = filebase64("${path.module}/assets/users")
    }
  ]

  env = {
    TRAEFIK_API_DASHBOARD = true
  }

  # custom instance configuration is possible through supplemental cloud-init config(s)
  cloudinit_part = [{
    content_type = "text/cloud-config"
    content      = local.cloudinit_configure_gcr
  }]
}

# configure access to private gcr repositories

locals {
  cloudinit_configure_gcr = <<EOT
#cloud-config

write_files:
  - path: /etc/systemd/system/gcr.service
    permissions: 0644
    content: |
      [Unit]
      Description=Configure Google Container Registry
      Before=docker.service

      [Service]
      Type=oneshot
      Environment=HOME=/run/app
      PassEnvironment=HOME
      ExecStart=/usr/bin/docker-credential-gcr configure-docker

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl enable --now gcr.service

EOT
}

```

# Terraform

## Inputs

| Name           | Description                                                          | Type     | Default | Required |
| -------------- | -------------------------------------------------------------------- | -------- | ------- | :------: |
| cloud_dns_zone | Cloud DNS zone name.                                                 | `string` | n/a     |   yes    |
| domain         | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email          | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| project        | The ID of the project in which to provision resources.               | `string` | n/a     |   yes    |
| region         | Google Cloud region where the instance will be created.              | `string` | n/a     |   yes    |
| subnet_name    | The name of the subnet where the instance will be created.           | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
