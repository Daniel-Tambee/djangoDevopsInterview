from django.urls import path
from .views import ProcessAPIView, ProcessStatusAPIView

urlpatterns = [
    path("process/", ProcessAPIView.as_view(), name="process-request"),
    path(
        "status/<str:task_id>/",
        ProcessStatusAPIView.as_view(),
        name="task-status-endpoint",
    ),
]
