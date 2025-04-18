# myproject/celery.py
import os
from celery import Celery

# Ensure Django settings are loaded
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")

# Create the Celery app instance
app = Celery("myproject")

# Set the broker URL from the environment or fallback to Redis at redis:6379/0
app.conf.broker_url = os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/0")

# Load any additional Celery configuration from Django's settings, using the CELERY_ namespace
app.config_from_object("django.conf:settings", namespace="CELERY")

# Auto-discover tasks from all installed apps
app.autodiscover_tasks()
