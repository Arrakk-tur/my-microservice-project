# Agro CD + CD (Lesson 8-9)
## Опис проєкту
Цей проєкт розгортає інфраструктуру в AWS, що включає:
- **S3 Backend**: для безпечного зберігання стану (`terraform.tfstate`).
- **VPC**: мережа з 3 публічними та 3 приватними підмережами у різних AZ.
- **ECR**: репозиторій для Docker-образів з автоматичним скануванням.
- **EKS**: Kubernetes кластер.
- **Jenkins**: CI-інструмент, що використовує Kubernetes Pod Agents (Kaniko) для безпечної збірки образів.
- **Argo CD**: CD-інструмент для синхронізації стану кластера з Helm-чартом у Git.

## Структура модулів
- `s3-backend`: Створює S3 бакет та DynamoDB.
- `vpc`: Налаштовує мережу, IGW, NAT Gateway та таблиці маршрутизації.
- `ecr`: Створює репозиторій з політиками доступу.
- `eks`: Налаштовує Kubernetes кластер.
- `jenkins`: Jenkins сервер та ServiceAccount (IRSA) для Kaniko.
- `argo_cd`: Argo CD та Application для автоматичного деплою.
- `charts/django-app`: Helm-чарт (Deployment, Service, HPA, ConfigMap).
- `django`: Код Django-застосунку та Dockerfile.

## Кроки розгортання

### Крок 1: Налаштування змінних

Відредагуйте файли, вказавши ваші актуальні дані:
**`./variables.tf`**:
- `aws_region`: Регіон (наприклад, `eu-north-1`).
- `s3_bucket_name`: Унікальне ім'я для Terraform Backend.
- `git_repo`: URL вашого репозиторію.
- `git_token`: Персональний токен доступу GitHub (PAT).
- `django_secret` та `django_db_pswd`: Секрети для застосунку.


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
Створіть EKS, ECR та всі допоміжні сервіси:
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
2. Отримайте пароль адміністратора:
   ```bash
   kubectl exec -n jenkins -it svc/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```
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
2. Отримайте пароль:
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
1. Push: Розробник пушить зміни в теку `django/`.
