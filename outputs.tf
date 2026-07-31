# Outputs — «результаты» после apply. Смотрите их командой:
#   terraform output

output "vm_name" {
  description = "Имя созданной ВМ"
  value       = yandex_compute_instance.web.name
}

output "public_ip" {
  description = "Публичный IP — откройте http://<этот_адрес> в браузере"
  value       = yandex_compute_instance.web.network_interface[0].nat_ip_address
}

output "ssh_command" {
  description = "Команда для SSH-входа"
  value       = "ssh ${var.ssh_username}@${yandex_compute_instance.web.network_interface[0].nat_ip_address}"
}

output "console_hint" {
  description = "Куда смотреть в консоли Yandex Cloud"
  value       = "Консоль → Compute Cloud → Виртуальные машины → ${yandex_compute_instance.web.name}"
}
