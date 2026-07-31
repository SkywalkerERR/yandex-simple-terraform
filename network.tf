# Сеть: VPC → подсеть.
# Без сети ВМ не сможет получать IP и ходить в интернет.
#
# Кастомный security group здесь специально не используем:
# для его правил часто нужна роль vpc.admin на каталоге.
# У новой сети есть default security group (разрешает трафик) — для учёбы достаточно.

resource "yandex_vpc_network" "main" {
  name        = "tf-hello-network"
  description = "Учебная сеть для первого Terraform-примера"
}

resource "yandex_vpc_subnet" "main" {
  name           = "tf-hello-subnet"
  description    = "Подсеть в одной зоне доступности"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}
