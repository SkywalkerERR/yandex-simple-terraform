# Terraform с нуля: простой пример для Yandex Cloud

Учебный проект: Terraform создаёт **сеть + подсеть + security group + одну ВМ с nginx**.  
После `apply` открываете публичный IP в браузере и видите страницу «Работает!».

---

## Как устроен Terraform (для новичка)

### Идея одной фразой

Вы **описываете желаемую инфраструктуру в файлах**, а Terraform сам:

1. понимает, чего ещё нет;
2. создаёт / меняет / удаляет ресурсы в облаке;
3. запоминает текущее состояние в файле `terraform.tfstate`.

Это называется **Infrastructure as Code** (инфраструктура как код).

### Главные понятия

| Понятие | Что это |
|--------|---------|
| **Provider** | Плагин для конкретного облака (у нас `yandex-cloud/yandex`) |
| **Resource** | То, что Terraform создаёт: ВМ, сеть, диск… |
| **Data source** | То, что Terraform только читает (например, образ Ubuntu) |
| **Variable** | Входной параметр (`var.zone`, `var.vm_name`) |
| **Output** | Полезный результат после apply (публичный IP) |
| **State** | Снимок «что уже создано в облаке» (`terraform.tfstate`) |

### Жизненный цикл команд

```text
terraform init   → скачать провайдер, подготовить рабочую папку
terraform plan   → показать план: что будет создано/изменено/удалено
terraform apply  → применить план в облаке
terraform destroy→ удалить всё, что описано в этой конфигурации
```

`plan` безопасен (ничего не меняет). `apply` и `destroy` меняют облако.

### Как Terraform «связывает» ресурсы

В коде вы ссылаетесь на атрибуты других ресурсов:

```hcl
subnet_id = yandex_vpc_subnet.main.id
```

Terraform сам строит **граф зависимостей**: сначала сеть, потом подсеть, потом ВМ.

---

## Структура этого проекта

```text
yandex-simple/
├── versions.tf                 # версии Terraform и провайдера
├── providers.tf                # настройка провайдера Yandex
├── variables.tf                # объявление входных переменных
├── terraform.tfvars.example    # пример значений переменных
├── network.tf                  # VPC, подсеть, security group
├── compute.tf                  # ВМ + образ Ubuntu + cloud-init/nginx
├── outputs.tf                  # публичный IP, SSH-команда
├── .gitignore                  # чтобы секреты и state не попали в git
└── README.md                   # эта инструкция
```

Файлы с расширением `.tf` читаются **все вместе** — имена файлов для удобства людей, не для порядка выполнения.

Что создаётся в облаке:

1. **VPC-сеть** `tf-hello-network`
2. **Подсеть** `tf-hello-subnet` (`10.10.0.0/24`)
3. **Security group** — порты 22 (SSH) и 80 (HTTP)
4. **ВМ** Ubuntu 22.04 с публичным IP и nginx

---

## Инструкция: настройка и проверка

### 0. Что нужно заранее

- Аккаунт [Yandex Cloud](https://console.yandex.cloud/) с платёжным аккаунтом (`ACTIVE` / `TRIAL_ACTIVE`)
- Установленный [Terraform](https://developer.hashicorp.com/terraform/install) (`terraform version`)
- Установленный [Yandex Cloud CLI (`yc`)](https://yandex.cloud/ru/docs/cli/quickstart)
- SSH-ключ (если нет — создайте, см. ниже)

> ВМ и публичный IP — **платные** ресурсы. После проверки обязательно сделайте `terraform destroy`.

### 1. Установите и проверьте инструменты (Windows PowerShell)

```powershell
terraform version
yc version
```

Если SSH-ключа ещё нет:

```powershell
ssh-keygen -t ed25519 -C "terraform-yandex-lab"
# публичный ключ обычно здесь:
# C:\Users\<Вы>\.ssh\id_ed25519.pub
```

### 2. Войдите в Yandex Cloud CLI

```powershell
yc init
```

Выберите облако и каталог (folder). Запомните: Terraform будет создавать ресурсы **в этом folder**.

### 3. Экспортируйте учётные данные (на текущую сессию PowerShell)

Самый простой способ для обучения — IAM-токен пользователя:

```powershell
$Env:YC_TOKEN = (yc iam create-token)
$Env:YC_CLOUD_ID = (yc config get cloud-id)
$Env:YC_FOLDER_ID = (yc config get folder-id)

# Проверка:
echo $Env:YC_FOLDER_ID
```

Токен живёт до ~12 часов. Если `apply` вдруг начнёт ругаться на auth — снова выполните `yc iam create-token`.

В `providers.tf` мы **намеренно не пишем** token/cloud_id/folder_id — провайдер читает их из `YC_*`.

### 4. Подготовьте переменные проекта

```powershell
cd d:\python\terraform\yandex-simple
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Если ваш публичный ключ не `~/.ssh/id_ed25519.pub`, укажите путь явно, например:

```hcl
ssh_public_key_path = "C:/Users/shura/.ssh/id_ed25519.pub"
```

### 5. Зеркало провайдеров (важно для РФ)

Официальный `registry.terraform.io` часто недоступен. Один раз создайте файл  
`%APPDATA%\terraform.rc` (обычно `C:\Users\<Вы>\AppData\Roaming\terraform.rc`):

```hcl
provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

Без этого `terraform init` может упасть с `Invalid provider registry host`.

### 6. Инициализация

```powershell
terraform init
```

Ожидаемый результат: провайдер `yandex` скачан, сообщение вроде `Terraform has been successfully initialized!`.

Если раньше init уже падал, очистите кэш и повторите:

```powershell
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
terraform init -upgrade
```

### 7. Посмотрите план (ничего ещё не создаётся)

```powershell
terraform plan
```

В конце плана должно быть примерно:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

(сеть, подсеть, SG, ВМ)

### 8. Создайте инфраструктуру

```powershell
terraform apply
```

Напишите `yes` и дождитесь конца (обычно 1–3 минуты).

Посмотрите результаты:

```powershell
terraform output
```

Самое важное — `public_ip`.

### 9. Наглядная проверка, что всё работает

**А) В браузере**

Откройте:

```text
http://<public_ip>
```

Должна открыться страница **«Работает!»** (nginx ставится через cloud-init; иногда нужно подождать 30–90 секунд после apply).

**Б) По SSH**

```powershell
terraform output -raw ssh_command
# затем выполните выведенную команду, например:
# ssh ubuntu@158.160.x.x
```

На ВМ:

```bash
curl -I http://127.0.0.1
systemctl status nginx --no-pager
```

**В) В консоли Yandex Cloud**

1. [console.yandex.cloud](https://console.yandex.cloud/)
2. **Compute Cloud → Виртуальные машины** — ваша ВМ `tf-hello-vm`
3. **VPC → Облачные сети** — сеть `tf-hello-network`
4. Сравните: то, что в файлах `.tf`, видно и в UI

**Г) Эксперимент «изменил код → Terraform поправил облако»**

1. В `terraform.tfvars` поменяйте, например, `vm_name = "tf-hello-vm-2"`
2. Выполните `terraform plan` — увидите изменение
3. `terraform apply` — Terraform пересоздаст/обновит ресурс
4. Снова откройте IP / консоль и убедитесь, что имя изменилось

Так ощущается главный смысл Terraform: **источник правды — файлы**, а не ручные клики в UI.

### 10. Удалите ресурсы (обязательно после практики)

```powershell
terraform destroy
```

Подтвердите `yes`. Проверьте в консоли: ВМ и сеть исчезли.

---

## Частые проблемы

| Симптом | Что сделать |
|--------|-------------|
| `No valid credential sources` | Заново задайте `$Env:YC_TOKEN` и `YC_*` |
| Ошибка про SSH-ключ / `no such file` | Исправьте `ssh_public_key_path` в `terraform.tfvars` |
| Браузер не открывается сразу | Подождите 1–2 минуты: cloud-init ставит nginx |
| `Permission denied` по SSH | Убедитесь, что используете **приватный** ключ к тому же `.pub` |
| Платный аккаунт / квота | Проверьте billing и квоты Compute/VPC в консоли |

---

## Что изучать дальше

1. Разнести код по модулям (`modules/vm`, `modules/network`)
2. Хранить state удалённо (S3-совместимое хранилище Object Storage)
3. Добавить второй ресурс (Load Balancer, Managed PostgreSQL, Object Storage)
4. CI/CD: `plan` в Pull Request, `apply` после merge

Удачной практики — и не забывайте про `destroy` после экспериментов.
