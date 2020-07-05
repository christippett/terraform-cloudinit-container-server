module "container" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

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

/* Instance ----------------------------------------------------------------- */

resource "google_compute_instance" "app" {
  name         = "app"
  project      = var.project
  zone         = "${var.region}-a"
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.container.cloud_config
  }

  boot_disk {
    initialize_params { image = data.google_compute_image.cos.self_link }
  }

  network_interface {
    subnetwork         = var.subnet_name
    subnetwork_project = var.project
    access_config {}
  }
}

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-81-lts"
}

/* DNS ---------------------------------------------------------------------- */

resource "google_dns_record_set" "app" {
  project      = var.project
  name         = "app.${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_instance.app.network_interface[0].access_config[0].nat_ip]
}
