from rest_framework import viewsets
from .serializers import (
    DonutSerializer, RecipeSerializer, IngredientSerializer,
    CustomerSerializer, EmployeeSerializer, ReviewSerializer
)
from .models import (
    Donut, Recipe, Ingredient, Customer, Employee, Review
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