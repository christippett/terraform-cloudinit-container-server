# Simple Container Server w/ Terraform & cloud-init

[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/christippett/terraform-cloudinit-container-server?label=version)](./CHANGELOG.md) [![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4)](https://registry.terraform.io/modules/christippett/container-server/cloudinit/)

A batteries included [cloud-init](https://cloud-init.io) config to quickly and easily deploy a single Docker image or Docker Compose file to any Cloud™ virtual machine.

> [**What is cloud-init?**](https://github.com/canonical/cloud-init)
>
> _Cloud-init is the industry standard multi-distribution method for cross-platform cloud instance initialization. It is supported across all major public cloud providers, provisioning systems for private cloud infrastructure, and bare-metal installations._
>
> _Cloud-init will identify the cloud it is running on during boot, read any provided metadata from the cloud and initialize the system accordingly. This may involve setting up network and storage devices to configuring SSH access key and many other aspects of a system. Later on cloud-init will also parse and process any optional user or vendor data that was passed to the instance._

The module takes things one step further by bootstrapping an environment that hosts your containers with minimal fuss. All credit goes to the creators of cloud-init and Traefik for making this so easy.

## Features

- ☁️ The module can be used to deploy instances on:
  - [AWS](./examples/aws-docker-image-simple/README.md)
  - [Google Cloud Platform](./examples/digitalocean-docker-image-simple/README.md)
  - [DigitalOcean](./examples/gcp-docker-image-simple/README.md)
  - Azure
  - _(and theoretically any other platform that supports cloud-init)_
- 🔑 Automatic SSL certificates from [Let's Encrypt](https://letsencrypt.org/)
- 🌐 Installs [Traefik](https://containo.us/traefik/) for use as a reverse proxy (includes automatic HTTP 🠆 HTTPS redirection)
- 📝 Provides the option to supply your own [cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) config(s) to further customise your instances

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

## Notes

- 🏷️ If using deploying a Docker Compose file, you must specify all the relevant labels to configure Traefik and Let's Encrypt.
- 🔗 Traefik is configured to monitor the `web` network, any services you wish to expose must belong to this network.
- 🤓 Terraform shares the same template syntax as Docker Compose's environment variable interpolation syntax. This module passes both the `domain` and `letsencrypt_email` variables to Docker Compose to help templatise your configuration — this is especially handy when declaring Docker labels for Traefik.
- 🌎 If enabled, Traefik's [monitoring dashboard](https://docs.traefik.io/operations/dashboard/) will be available at `https://traefik.${domain}/dashboard/`. This is currently hard-coded in the configuration, so ensure to set up the appropriate DNS record if you want to enable this feature.

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
