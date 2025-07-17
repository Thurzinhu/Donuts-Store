from django.shortcuts import render
from django.http.response import JsonResponse


# Create your views here.
def home(request):
    return JsonResponse({"Status": "Ok"})