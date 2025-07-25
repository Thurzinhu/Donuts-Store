from rest_framework import serializers
from .models import Ingredient, Recipe, Donut, Customer, Employee, Review

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


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = ['id', 'first_name', 'last_name', 'email']


class EmployeeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ['id', 'name', 'role', 'hire_date', 'salary']


class ReviewSerializer(serializers.ModelSerializer):
    customer = CustomerSerializer(read_only=True)
    customer_id = serializers.PrimaryKeyRelatedField(queryset=Customer.objects.all(), source='customer', write_only=True)
    donut = DonutSerializer(read_only=True)
    donut_id = serializers.PrimaryKeyRelatedField(queryset=Donut.objects.all(), source='donut', write_only=True)

    class Meta:
        model = Review
        fields = ['id', 'customer', 'customer_id', 'donut', 'donut_id', 'comment', 'rating', 'review_date']
        read_only_fields = ['review_date']
