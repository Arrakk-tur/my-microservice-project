# Helm (Lesson 7)
## Опис проєкту
Цей проєкт розгортає інфраструктуру в AWS, що включає:
- **S3 Backend**: для безпечного зберігання стану (`terraform.tfstate`).
- **DynamoDB**: для запобігання одночасному внесенню змін (state locking).
- **VPC**: мережа з 3 публічними та 3 приватними підмережами у різних AZ.
- **ECR**: репозиторій для Docker-образів з автоматичним скануванням.
- **EKS**: Kubernetes кластер.

## Структура модулів
- `s3-backend`: Створює S3 бакет та DynamoDB.
- `vpc`: Налаштовує мережу, IGW, NAT Gateway та таблиці маршрутизації.
- `ecr`: Створює репозиторій з політиками доступу.
- `eks`: Налаштовує Kubernetes кластер.
- `/charts/django-app`: Helm-чарт (Deployment, Service, HPA, ConfigMap).
- `/django`: Rод Django-застосунку та Dockerfile.

## Кроки розгортання
**Крок 1: Підготовка Backend (S3 + DynamoDB)**

Для безпечного зберігання `terraform.tfstate` необхідно спочатку створити кошик S3 та таблицю DynamoDB.
1. У файлі `backend.tf` залиште блок `terraform { backend "s3" { ... } }` **закоментованим**.
2. Виконайте ініціалізацію та створення ресурсів:
   ```bash
   terraform init
   terraform apply -target=module.s3_backend
   ```
3. Розкоментуйте блок у `backend.tf` та виконайте `terraform init` знову, щоб перенести стейт у хмару.

**Крок 2: Створення інфраструктури EKS та ECR**

Тепер створимо мережу, кластер та репозиторій для образів.

```bash
terraform apply
```

**Крок 3: Збірка та завантаження Docker-образу**

Після створення ECR, вам потрібно завантажити туди свій застосунок. Отримайте URL репозиторію з виводу Terraform (`ecr_repository_url`).

1. Авторизація в ECR:
   ```bash
   aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com
   ```
2. Збірка образу:
   ```bash
   docker build -t django-app ./django
   ```
3. Тегування та Push:
   ```bash
   docker tag django-app:latest <YOUR_ECR_REPOSITORY_URL>:latest
   docker push <YOUR_ECR_REPOSITORY_URL>:latest
   ```

**Крок 4: Налаштування доступу до кластера**

Щоб керувати кластером через kubectl, оновіть свій kubeconfig:

   ```bash
   aws eks update-kubeconfig --region eu-north-1 --name django-cluster
   ```

## Видалення ресурсів

```bash
terraform destroy
```