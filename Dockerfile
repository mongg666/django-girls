# Используем официальный образ Python
FROM python:3.11-slim-bullseye

# Установка зависимостей системы с надежными зеркалами
RUN sed -i 's/deb.debian.org/ftp.ru.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/ftp.ru.debian.org/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя приложения и рабочих директорий
RUN useradd --create-home appuser && \
    mkdir -p /home/appuser/app/static && \
    mkdir -p /home/appuser/app/media && \
    mkdir -p /home/appuser/app/db && \
    chown -R appuser:appuser /home/appuser && \
    chmod -R 775 /home/appuser

# Установка зависимостей Python
COPY --chown=appuser:appuser requirements.txt /tmp/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Переключаемся на пользователя приложения
USER appuser
WORKDIR /home/appuser/app

# Копирование кода приложения
COPY --chown=appuser:appuser . .

# Создаем файл БД и даем права
RUN touch db.sqlite3 && \
    chmod 664 db.sqlite3

# Сборка статических файлов
ENV PYTHONUNBUFFERED=1
RUN python manage.py collectstatic --noinput

# Порт приложения
EXPOSE 8000

# Команда запуска (миграции + gunicorn)
CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 mysite.wsgi"]
