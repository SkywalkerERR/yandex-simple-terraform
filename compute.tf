# Data-источник: не создаёт ресурс, а находит актуальный образ Ubuntu.
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Виртуальная машина с публичным IP и nginx (через cloud-init).
resource "yandex_compute_instance" "web" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory
    core_fraction = 20 # дешевле для обучения (гарантировано 20% CPU)
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true # публичный IP
  }

  metadata = {
    # SSH-ключ для входа
    ssh-keys = "${var.ssh_username}:${file(pathexpand(var.ssh_public_key_path))}"

    # cloud-init: ставит nginx и показывает простую страницу
    user-data = <<-EOT
      #cloud-config
      package_update: true
      packages:
        - nginx
      runcmd:
        - |
          cat > /var/www/html/index.html <<'HTML'
          <!DOCTYPE html>
          <html lang="ru">
          <head>
            <meta charset="utf-8" />
            <title>Terraform + Yandex Cloud</title>
            <style>
              body {
                margin: 0;
                min-height: 100vh;
                display: grid;
                place-items: center;
                font-family: Georgia, "Times New Roman", serif;
                background:
                  radial-gradient(circle at 20% 20%, #ffe8a3 0%, transparent 40%),
                  radial-gradient(circle at 80% 0%, #9ad0ff 0%, transparent 35%),
                  linear-gradient(160deg, #0f1c2e, #1f3b5b 55%, #0b1320);
                color: #f7f3ea;
              }
              main {
                max-width: 40rem;
                padding: 2rem;
                text-align: center;
              }
              h1 { font-size: 2.4rem; margin-bottom: 0.5rem; }
              p { font-size: 1.15rem; line-height: 1.5; opacity: 0.92; }
              code {
                background: rgba(255,255,255,0.12);
                padding: 0.15rem 0.45rem;
                border-radius: 0.35rem;
              }
            </style>
          </head>
          <body>
            <main>
              <h1>Работает!</h1>
              <p>
                Эту страницу отдаёт nginx на ВМ, которую создал
                <code>terraform apply</code> в Yandex Cloud.
              </p>
            </main>
          </body>
          </html>
          HTML
        - systemctl enable --now nginx
    EOT
  }
}
