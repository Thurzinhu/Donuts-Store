from django.db import models
from django.core.validators import MinValueValidator

# Create your models here.
class Ingredient(models.Model):
    class Unit(models.TextChoices):
        GRAM = 'g', 'Gram'
        MILLILITER = 'ml', 'Milliliter'
        UNIT = 'unit', 'Unit'
        KILOGRAM = 'kg', 'Kilogram'
        LITER = 'l', 'Liter'

    name = models.CharField(null=False, blank=False, max_length=100)
    price_per_unit = models.DecimalField(null=False, blank=False, max_digits=6, decimal_places=2, validators=[MinValueValidator(0)])
    unit = models.CharField(max_length=10, choices=Unit.choices, default=Unit.UNIT)


    def __str__(self):
        return f"Ingredient {self.name} - ${self.price_per_unit}/{self.unit}"


class Recipe(models.Model):
    donut = models.ForeignKey('Donut', on_delete=models.CASCADE)
    ingredient = models.ForeignKey('Ingredient', on_delete=models.CASCADE)
    quantity = models.DecimalField(max_digits=6, decimal_places=2, validators=[MinValueValidator(0)])


    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['donut', 'ingredient'], name='unique_donut_ingredient')
        ]


    def __str__(self):
        return f"{self.quantity} {self.ingredient.unit} of {self.ingredient.name} in {self.donut.name}"


class Donut(models.Model):
    name = models.CharField(null=False, blank=False, max_length=100)
    gluten_free = models.BooleanField(null=False, blank=False, default=False)
    price = models.DecimalField(null=False, blank=False, max_digits=6, decimal_places=2, validators=[MinValueValidator(0)])
    ingredients = models.ManyToManyField(Ingredient, through=Recipe, related_name='donuts')
    description = models.TextField(null=True, blank=True)


    def __str__(self):
        return f"Donut {self.name} costs ${self.price}"