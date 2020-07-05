module "container-server" {
  source = "../.."

  domain = var.domain
  email  = var.email

  files = [
    {
      filename = "docker-compose.yaml"
      content  = filebase64("${path.module}/assets/docker-compose.yaml")
    },
    {
      filename = "users"
      content  = filebase64("${path.module}/assets/users")
    }
  ]
  env = {
    PORTAINER_PASSWORD    = var.portainer_password
    TRAEFIK_API_DASHBOARD = true
    DOCKER_LOG_DRIVER     = "gcplogs"
  }

  # extra cloud-init config provided to setup + format persistent disk
  cloudinit_part = [{
    content_type = "text/cloud-config"
    content      = local.cloudinit_disk
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


/* Instance ----------------------------------------------------------------- */

resource "google_compute_instance" "app_server" {
  name         = "app-server"
  project      = var.project
  zone         = "${var.region}-a"
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.container-server.cloud_config
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = var.subnet_name
    subnetwork_project = var.project

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  scheduling {
    automatic_restart = true
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-81-lts"
}

/* Disk --------------------------------------------------------------------- */

resource "google_compute_disk" "default" {
  project = var.project
  name    = "disk-app-server"
  type    = "pd-standard"
  zone    = "${var.region}-a"
  size    = 10
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.default.id
  instance = google_compute_instance.app_server.id
}

/* Network ------------------------------------------------------------------ */

resource "google_compute_address" "static" {
  project      = var.project
  region       = var.region
  name         = "ip-app-server"
  network_tier = "PREMIUM"
}

/* DNS ---------------------------------------------------------------------- */

resource "google_dns_record_set" "default" {
  project      = var.project
  name         = "${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_address.static.address]
}

resource "google_dns_record_set" "wildcard" {
  project      = var.project
  name         = "*.${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_address.static.address]
}

/* IAM ---------------------------------------------------------------------- */

resource "google_service_account" "default" {
  account_id   = "app-server"
  display_name = "Application Service Account"
  project      = var.project
}

resource "google_project_iam_member" "default" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.default.email}"
}
