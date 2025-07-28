from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'donuts-store'

router = DefaultRouter()
router.register('donut', views.DonutViewSet)
router.register('ingredient', views.IngredientViewSet)
router.register('recipe', views.RecipeViewSet)
router.register('customer', views.CustomerViewSet)
router.register('employee', views.EmployeeViewSet)
router.register('review', views.ReviewViewSet)
router.register('order', views.OrderViewSet)
router.register('donut-order', views.DonutOrderViewSet)
router.register('payment', views.PaymentViewSet)

urlpatterns = [
    path('', include(router.urls))
]