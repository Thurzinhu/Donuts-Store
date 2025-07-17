from django.urls import path
from . import views

app_name = 'donuts-store'

urlpatterns = [
    path('', views.home, name='home'),
]