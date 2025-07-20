from rest_framework import viewsets
from .serializers import (
    DonutSerializer, RecipeSerializer, IngredientSerializer
)
from .models import (
    Donut, Recipe, Ingredient
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