# Версии Terraform и провайдеров.
# Terraform читает этот блок при `terraform init`.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.140"
    }
  }
}
