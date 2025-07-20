from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'donuts-store'

router = DefaultRouter()
router.register('donut', views.DonutViewSet)
router.register('ingredient', views.IngredientViewSet)
router.register('recipe', views.RecipeViewSet)

urlpatterns = [
    path('', include(router.urls))
]