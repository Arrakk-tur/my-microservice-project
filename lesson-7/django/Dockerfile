FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

WORKDIR /app/my_best_ever_site

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "my_best_ever_site.wsgi:application"]