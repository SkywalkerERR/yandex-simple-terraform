variable "zone" {
  description = "Зона доступности Yandex Cloud (например ru-central1-a)"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "tf-hello-vm"
}

variable "vm_cores" {
  description = "Число vCPU"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Память ВМ в ГБ"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Размер загрузочного диска в ГБ"
  type        = number
  default     = 20
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу (для входа на ВМ)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_username" {
  description = "Имя пользователя на ВМ (для Ubuntu обычно ubuntu)"
  type        = string
  default     = "ubuntu"
}
