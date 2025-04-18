# api/tasks.py
import time
import logging
from celery import shared_task

logger = logging.getLogger(__name__)


@shared_task
def process_request_task(email, message):
    time.sleep(5)

    logger.info(f"Processed request for email: {email} with message: {message}")

    return {"status": "completed", "email": email}
