# Провайдер — «драйвер» облака.
# Секреты (токен, cloud_id, folder_id) берём из переменных окружения:
#   YC_TOKEN, YC_CLOUD_ID, YC_FOLDER_ID
# Так они не попадают в файлы и git.

provider "yandex" {
  zone = var.zone
}
