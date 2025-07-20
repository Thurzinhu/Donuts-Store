from rest_framework import serializers
from .models import Ingredient, Recipe, Donut

class IngredientSerializer(serializers.ModelSerializer):
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)

    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'price_per_unit', 'unit', 'unit_display']


class RecipeSerializer(serializers.ModelSerializer):
    ingredient = IngredientSerializer(read_only=True)
    ingredient_id = serializers.PrimaryKeyRelatedField(queryset=Ingredient.objects.all(), source='ingredient', write_only=True)

    class Meta:
        model = Recipe
        fields = ['id', 'donut', 'ingredient', 'ingredient_id', 'quantity']


class DonutSerializer(serializers.ModelSerializer):
    ingredients = RecipeSerializer(source='recipe_set', many=True, read_only=True)

    class Meta:
        model = Donut
        fields = ['id', 'name', 'gluten_free', 'price', 'description', 'ingredients']
