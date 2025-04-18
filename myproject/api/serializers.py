from rest_framework import serializers


class ProcessSerializer(serializers.Serializer):
    email = serializers.EmailField()
    message = serializers.CharField()
