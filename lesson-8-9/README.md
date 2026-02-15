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
### Крок 1: Підготовка Backend (S3 + DynamoDB)

Для безпечного зберігання `terraform.tfstate` необхідно спочатку створити кошик S3 та таблицю DynamoDB.

1. У файлі `backend.tf` залиште блок `terraform { backend "s3" { ... } }` **закоментованим**.
2. Виконайте ініціалізацію та створення ресурсів:
   ```bash
   terraform init
   terraform apply -target=module.s3_backend
   ```
3. Розкоментуйте блок у `backend.tf` та виконайте `terraform init` знову, щоб перенести стейт у хмару.

### Крок 2: Створення інфраструктури EKS та ECR
Створіть EKS, ECR та всі допоміжні сервіси:
   ```bash
   terraform apply
   ```

### Крок 3: Налаштування доступу до кластера
Під'єднайтесь до створеного кластера EKS:
   ```bash
   aws eks update-kubeconfig --region eu-north-1 --name django-cluster
   ```

### Крок 4: Налаштування Jenkins
1. Отримайте URL Jenkins:
   ```bash
   kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
2. Отримайте пароль адміністратора:
   ```bash
   kubectl exec -n jenkins -it svc/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Налаштування Credentials: Створіть запис Username with password з ID `github-token`.

### Крок 5: Налаштування Argo CD
1. Отримайте URL Argo CD:
   ```bash
   kubectl get svc -n argocd argo-cd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
2. Отримайте пароль:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

## Видалення ресурсів

```bash
terraform destroy
```

## CI/CD Workflow (Процес роботи)
1. Push: Розробник пушить зміни в теку `django/`.