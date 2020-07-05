# Docker Compose — Google Cloud Platform

Deploys a custom Docker Compose file to a Compute Engine instance and enables updates via webhook.

## Usage

```hcl
module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  letsencrypt_staging = true # delete this or set to false to enable production Let's Encrypt certificates
  enable_webhook      = true # webhook protected by basic auth

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
    IMAGE                 = "containous/whoami:latest"
    TRAEFIK_API_DASHBOARD = true
  }

  # custom instance configuration is possible through supplemental cloud-init config(s)
  cloudinit_part = [
    {
      content_type = "text/cloud-config"
      content      = local.cloudinit_configure_gcr
    }
  ]

}

```

Once deployed, updates to the container image can be made via the enabled webhook.

```bash
curl \
  --user admin:password \
  --header "Content-Type: application/json" \
  --request PATCH \
  --data '{ "key": "IMAGE", "value": "nginxdemos/hello:latest" }' \
  https://app.example.com:9000/hooks/update-env
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
