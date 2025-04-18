# api/views.py
from multiprocessing.pool import AsyncResult
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import ProcessSerializer
from .tasks import process_request_task


class ProcessAPIView(APIView):
    def post(self, request, format=None):
        serializer = ProcessSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data["email"]
            message = serializer.validated_data["message"]

            task = process_request_task.delay(email, message)

            return Response(
                {
                    "detail": "Request received and is being processed.",
                    "task_id": task.id,
                },
                status=status.HTTP_202_ACCEPTED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProcessStatusAPIView(APIView):
    def get(self, request, task_id, format=None):
        result = AsyncResult(task_id)

        data = {
            "task_id": task_id,
            "status": result.status,
            "result": result.result if result.ready() else None,
        }
        return Response(data, status=status.HTTP_200_OK)
