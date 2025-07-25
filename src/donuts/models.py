from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator

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


class Customer(models.Model):
    first_name = models.CharField(null=False, blank=False, max_length=100)
    last_name = models.CharField(null=False, blank=False, max_length=100)
    email = models.CharField(null=False, blank=False, max_length=255, unique=True)

    def __str__(self):
        return f"Customer {self.first_name} {self.last_name} - {self.email}"


class Employee(models.Model):
    name = models.CharField(null=False, blank=False, max_length=100)
    role = models.CharField(null=False, blank=False, max_length=100)
    hire_date = models.DateField(null=False, blank=False)
    salary = models.DecimalField(null=False, blank=False, max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])

    def __str__(self):
        return f"Employee {self.name} - {self.role}"


class Review(models.Model):
    customer = models.ForeignKey('Customer', on_delete=models.CASCADE)
    donut = models.ForeignKey('Donut', on_delete=models.CASCADE)
    comment = models.CharField(null=True, blank=True, max_length=500)
    rating = models.IntegerField(null=False, blank=False, validators=[MinValueValidator(1), MaxValueValidator(5)])
    review_date = models.DateTimeField(null=False, blank=False, auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['customer', 'donut'], name='unique_customer_donut_review')
        ]

    def __str__(self):
        return f"Review by {self.customer.first_name} {self.customer.last_name} for {self.donut.name} - {self.rating}/5"