# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [1.2.0-alpha.0](https://github.com/christippett/terraform-cloudinit-container-server/compare/v1.1.0...v1.2.0-alpha.0) (2020-07-05)


### Features

* Add webhook to enable updates independent of Terraform ([9ecbe8e](https://github.com/christippett/terraform-cloudinit-container-server/commit/9ecbe8ed54a09e4b770eedac3e211d019103b726))

## [1.1.0](https://github.com/christippett/terraform-cloudinit-container-server/compare/v1.0.3...v1.1.0) (2020-07-05)

### ⚠ BREAKING CHANGES

- A number of variables have been renamed or removed in favour of defining their values either as an environment variable or via a custom `docker-compose.yaml` file

The following variables have been renamed:

- `letsencrypt_email` → `email`
- `letsencrypt_staging_server` → `letsencrypt_staging`
- `compose_file` → `files`

The following variables have been replaced with an environment variable:

- `traefik_version` → `TRAEFIK_IMAGE_TAG`
- `enable_traefik_api` → `TRAEFIK_API_DASHBOARD`
- `docker_log_driver` → `DOCKER_LOG_DRIVER`

The following variables have been removed completely. These can be customised by providing a custom user-defined `docker-compose.yaml` file

- `docker_log_opts`
- `enable_letsencrypt`

The following variables have been removed in favour of using a `users` auth file read by Traefik. The name/location of this file can be customised using the `TRAEFIK_PASSWD_FILE` environment variable:

- `traefik_api_user`
- `traefik_api_password`

### Features

- Add another example for GCP showing how to configure GCR ([5db6482](https://github.com/christippett/terraform-cloudinit-container-server/commit/5db64820710667391e4e830f63d768a03551b8f1))
- Add functionality for file uploads ([b5125ee](https://github.com/christippett/terraform-cloudinit-container-server/commit/b5125ee457bb7efe50db30c0f818a3ab534c2a61))
- Refactor how apps are configured ([1885953](https://github.com/christippett/terraform-cloudinit-container-server/commit/1885953dcd574219dd64aa8e9570b6ffd91a8405))

### Bug Fixes

- Additional cloud-init configurations will append rather than replace original configuration ([d5c55e0](https://github.com/christippett/terraform-cloudinit-container-server/commit/d5c55e01e8926ea9ac3306309b68b37b769fe6f2))
- Raise error if Docker Compose install fails ([81761fc](https://github.com/christippett/terraform-cloudinit-container-server/commit/81761fcf7d69956078eaa6c2828457d0d87c9053))

### [1.0.3](https://github.com/christippett/terraform-cloudinit-container-server/compare/v1.0.2...v1.0.3) (2020-07-01)

### Features

- Add Azure example ([f8b9882](https://github.com/christippett/terraform-cloudinit-container-server/commit/f8b98821e54efe7ea284c0b559b27984fb0dd169))

### Bug Fixes

- Remove troublesome GCR config ([06e8a48](https://github.com/christippett/terraform-cloudinit-container-server/commit/06e8a484ff4ded5c3b293fedf4562d32d0229652))

### [1.0.2](https://github.com/christippett/terraform-cloudinit-container-server/compare/v1.0.1...v1.0.2) (2020-06-26)

### [1.0.1](https://github.com/christippett/terraform-cloudinit-container-server/compare/v1.0.0...v1.0.1) (2020-06-25)

## 1.0.0 (2020-06-24)

### Features

- Add AWS example ([ab2fdbb](https://github.com/christippett/terraform-cloudinit-container-server/commit/ab2fdbb7f02e946f8b84b0d55612194ffef19040))
- Add DigitalOcean example ([fd1370a](https://github.com/christippett/terraform-cloudinit-container-server/commit/fd1370a5f52a8a8b264a2b4912da47817ba139ea))
