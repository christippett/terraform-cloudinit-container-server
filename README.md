# Simple Container Server w/ Terraform & cloud-init

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/christippett/terraform-cloudinit-container-server?label=version) ![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4)

A batteries included [cloud-init](https://cloud-init.io) config to quickly and easily deploy a single Docker image or Docker Compose file to any Cloud™ virtual machine.

## Features

- ☁️ Works with:
  - [AWS](./examples/aws-docker-image-simple/README.md)
  - [Google Cloud Platform](./examples/digitalocean-docker-image-simple/README.md)
  - [DigitalOcean](./examples/gcp-docker-image-simple/README.md)
  - Azure _(currently untested)_
- 🔑 Automatic SSL certificates from [Let's Encrypt](https://letsencrypt.org/)
- 🌐 Uses [Traefik](https://containo.us/traefik/) as a reverse proxy
- 📝 Option to add additional [cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) config(s) to customise your instances

## Usage

Deploy a single Docker image:

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

Deploy a Docker Compose file:

```hcl
module "docker-server" {
  source  = "christippett/container-server/cloudinit"
  version = "1.0.0"

  domain            = "example.com"
  letsencrypt_email = "me@example.com

  compose_file = file("docker-compose.yaml")
}
```

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

💡 Terraform shares the same template syntax as Docker Compose's environment variable interpolation syntax. This module passes both the `domain` and `letsencrypt_email` variables to Docker Compose to help templatise your configuration — this is especially handy when declaring Docker labels for Traefik.

# Terraform

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
