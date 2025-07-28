from rest_framework import viewsets
from .serializers import (
    DonutSerializer, RecipeSerializer, IngredientSerializer,
    CustomerSerializer, EmployeeSerializer, ReviewSerializer,
    OrderSerializer, DonutOrderSerializer, PaymentSerializer
)
from .models import (
    Donut, Recipe, Ingredient, Customer, Employee, Review,
    Order, DonutOrder, Payment
)


class DonutViewSet(viewsets.ModelViewSet):
    queryset = Donut.objects.all()
    serializer_class = DonutSerializer


class IngredientViewSet(viewsets.ModelViewSet):
    queryset = Ingredient.objects.all()
    serializer_class = IngredientSerializer


class RecipeViewSet(viewsets.ModelViewSet):
    queryset = Recipe.objects.all()
    serializer_class = RecipeSerializer


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer


class EmployeeViewSet(viewsets.ModelViewSet):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer


class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer


class DonutOrderViewSet(viewsets.ModelViewSet):
    queryset = DonutOrder.objects.all()
    serializer_class = DonutOrderSerializer


class PaymentViewSet(viewsets.ModelViewSet):
    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer