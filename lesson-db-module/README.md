# Agro CD + CD (Lesson 8-9)
## Опис проєкту
Цей проєкт розгортає інфраструктуру в AWS, що включає:
- **S3 Backend**: для безпечного зберігання стану (`terraform.tfstate`).
- **VPC**: мережа з 3 публічними та 3 приватними підмережами у різних AZ.
- **RDS / Aurora**: реляційна база даних PostgreSQL для зберігання даних застосунку.
- **ECR**: репозиторій для Docker-образів з автоматичним скануванням.
- **EKS**: Kubernetes кластер.
- **Jenkins**: CI-інструмент, що використовує Kubernetes Pod Agents (Kaniko) для безпечної збірки образів.
- **Argo CD**: CD-інструмент для синхронізації стану кластера з Helm-чартом у Git.

## Структура модулів
- `s3-backend`: Створює S3 бакет та DynamoDB.
- `vpc`: Налаштовує мережу, IGW, NAT Gateway та таблиці маршрутизації.
- `rds`: Розгортає базу даних (AWS RDS PostgreSQL або Aurora PostgreSQL).
- `ecr`: Створює репозиторій з політиками доступу.
- `eks`: Налаштовує Kubernetes кластер.
- `jenkins`: Jenkins сервер та ServiceAccount (IRSA) для Kaniko.
- `argo_cd`: Argo CD та Application для автоматичного деплою.
- `charts/django-app`: Helm-чарт (Deployment, Service, HPA, ConfigMap).
- `django`: Код Django-застосунку та Dockerfile.

## Робота з базою даних (Модуль RDS)

Модуль `rds` дозволяє гнучко розгортати базу даних PostgreSQL у приватних підмережах кластера. Він підтримує як стандартний AWS RDS, так і AWS Aurora.

### Приклад використання модуля (файл `main.tf`)

```terraform
module "rds" {
  source          = "./modules/rds"
  project_name    = "django-app"
  use_aurora      = false # Змініть на true для використання AWS Aurora
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  eks_nodes_sg_id = module.eks.node_security_group_id

  db_name         = "my_best_db"
  username        = "postgres_user"
  password        = var.django_db_pswd
  engine_version  = "13.7"
  family          = "postgres13"
  instance_class  = "db.t3.medium"
  max_connections = "200"
}
```

### Опис змінних модуля RDS

- `project_name` (string): Префікс для іменування ресурсів БД (обов'язкова).
- `use_aurora` (bool): Якщо `true`, створюється кластер Aurora PostgreSQL. Якщо `false` — звичайний RDS PostgreSQL (за замовчуванням `false`).
- `vpc_id` (string): ID VPC, де буде розміщена БД (обов'язкова).
- `subnet_ids` (list): Список приватних підмереж для DB Subnet Group (обов'язкова).
- `eks_nodes_sg_id` (string): Security Group воркер-нод EKS, якій дозволено доступ до БД на порт 5432 (обов'язкова).
- `db_name` (string): Початкова назва бази даних (обов'язкова).
- `username` (string): Логін адміністратора БД (обов'язкова).
- `password` (string): Пароль адміністратора БД. Передається безпечно через `variables.tf` (обов'язкова).
- `engine_version` (string): Версія рушія PostgreSQL (за замовчуванням `"13.7"`).
- `family` (string): Версія Parameter Group. Має відповідати версії рушія (за замовчуванням `"postgres13"`).
- `instance_class` (string): Тип інстансу для БД (за замовчуванням `"db.t3.medium"`).
- `max_connections` (string): Ліміт максимальної кількості з'єднань до БД (за замовчуванням `"100"`).
- `work_mem` (string): Об'єм пам'яті для внутрішніх операцій сортування в PostgreSQL (за замовчуванням `"16MB"`).

### Як змінити конфігурацію БД

- **Зміна типу БД (RDS <-> Aurora):** Відредагуйте параметр `use_aurora` у файлі `main.tf`. 
  >**КРИТИЧНЕ ПОПЕРЕДЖЕННЯ ПРО ВТРАТУ ДАНИХ:** Зміна параметра `use_aurora` на вже розгорнутій (live) інфраструктурі призведе до **видалення** поточної бази даних і створення нової. Усі дані будуть втрачені! Якщо ви робите це не на тестовому середовищі, обов'язково створіть бекап і сплануйте міграцію даних перед виконанням `terraform apply`.
- **Зміна класу інстансу (Скейлінг):** Змініть `instance_class` (наприклад, з `db.t3.medium` на `db.r5.large`), якщо застосунок потребує більше ресурсів. 
- **Оновлення версії (Engine):** Змініть `engine_version` та відповідно оновіть `family` (наприклад, для PostgreSQL 14: `engine_version = "14.4"`, `family = "postgres14"`).

## Кроки розгортання

### Крок 1: Налаштування змінних

Відредагуйте файли, вказавши ваші актуальні дані:
**`terraform.tfvars`**:
- `aws_region`: Регіон AWS для розгортання ресурсів.
- `s3_bucket_name`: Унікальне (глобально) ім'я для кошика S3, де зберігатиметься Terraform Backend.
- `git_username`: Ваш логін на GitHub (для налаштування Argo CD).
- `git_repo`: URL вашого репозиторію (де лежить Helm-чарт `charts/django-app`).
- `git_token`: GitHub Personal Access Token (PAT) з правами на читання/запис репозиторію. Використовується Jenkins та Argo CD.
- `django_secret`: `SECRET_KEY` для фреймворку Django.
- `django_db_pswd`: Пароль для підключення до створеної бази даних (RDS/Aurora).
- `jenkins_admin_password`: Бажаний пароль для доступу до веб-інтерфейсу Jenkins.

> **СУВОРЕ ПРАВИЛО БЕЗПЕКИ:** Ніколи не комітьте файл `terraform.tfvars` у Git, оскільки він містить критичні паролі та токени доступу. Переконайтеся, що `terraform.tfvars` додано до вашого файлу `.gitignore`.

### Крок 2: Підготовка Backend (S3 + DynamoDB)

Для безпечного зберігання `terraform.tfstate` необхідно спочатку створити кошик S3 та таблицю DynamoDB.

1. У файлі `backend.tf` залиште блок `terraform { backend "s3" { ... } }` **закоментованим**.
2. Виконайте ініціалізацію та створення ресурсів:
   ```bash
   terraform init
   terraform apply -target=module.s3_backend
   ```
3. Розкоментуйте блок у `backend.tf` та виконайте `terraform init` знову, щоб перенести стейт у хмару.

### Крок 3: Створення основної інфраструктури
Створіть EKS, ECR, RDS та всі допоміжні сервіси:
   ```bash
   terraform apply
   ```
   
*Після завершення Terraform виведе URL-адреси та назви ресурсів.*

### Крок 4: Налаштування доступу до кластера
Під'єднайтесь до створеного кластера EKS:
   ```bash
   aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)
   ```

### Крок 5: Налаштування Jenkins
1. Отримайте URL Jenkins:
   ```bash
   kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
2. Пароль адміністратора ви вже задали в `terraform.tfvars` (`jenkins_admin_password`). Використовуйте його та логін `admin`.
3. Налаштування Credentials:
В інтерфейсі Jenkins перейдіть до *Manage Jenkins -> Credentials* та створіть:
   - **ID**: `github-token` (тип: Username with password).
   - **Username**: Ваш GitHub логін.
   - **Password**: Ваш GitHub PAT.

### Крок 6: Запуск CI/CD Workflow
1. Створіть у Jenkins нову **Pipeline** job.
2. Вкажіть посилання на ваш репозиторій та шлях до `Jenkinsfile`.
3. Запустіть збірку. 
   - **Build & Push**: Jenkins запустить Pod Agent з Kaniko, змонтує IRSA роль, збере образ та заштовхне його в ECR.
   - **Update Git**: Jenkins оновить тег образу в `charts/django-app/values.yaml` та зробить `git push`.

### Крок 7: Налаштування Argo CD
Argo CD автоматично розгортає застосунок, як тільки бачить зміни в Helm-чарті.

1. Отримайте URL Argo CD:
   ```bash
   kubectl get svc -n argocd argo-cd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
2. Отримайте пароль (логін за замовчуванням — `admin`):
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

### Перевірка результату
- У консолі Argo CD ви побачите додаток `django-app`.
- Після завершення синхронізації (Status: **Synced**), отримайте URL вашого Django застосунку:
  ```bash
  kubectl get svc django-app-django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```

## Обслуговування та видалення

### Перевірка логів застосунку
```bash
kubectl logs -l app.kubernetes.io/name=django-app -f
```

### Видалення всіх ресурсів
Щоб уникнути зайвих витрат в AWS, виконайте:
```bash
terraform destroy
```

## CI/CD Workflow (Процес роботи)
1. **Push:** Розробник пушить зміни коду в директорію `django/`.
2. **CI Pipeline:** Jenkins перехоплює зміни, білдить образ через Kaniko і пушить в ECR.
3. **GitOps Update:** Jenkins оновлює `values.yaml` новим тегом і комітить в репозиторій.
4. **CD Pipeline:** Argo CD фіксує зміну в `values.yaml` і автоматично оновлює поди в EKS.
