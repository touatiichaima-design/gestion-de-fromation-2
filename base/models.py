from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinLengthValidator
from django.dispatch import receiver
from django.db.models.signals import pre_save
from .utils import unique_slug_generator
from django.db.models.signals import post_save,post_delete
from django.contrib.auth import get_user_model

# Create your models here.

class Formateur (models.Model):
    nom = models.CharField(max_length=70)
    prenom = models.CharField(max_length=50)
    email = models.EmailField(max_length=254,blank=True, null=True)
    domaine = models.CharField(max_length=50,blank=True, null=True)
    image = models.ImageField(upload_to="images-formation",blank=True, null=True,default='/static/images/az.jpg')
    def __str__(self):
        return self.nom

class Participant(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE,null=True,blank=True)
    cin = models.CharField(validators=[MinLengthValidator(8)],max_length=8,blank=True, null=True)
    service = models.CharField(max_length=50,null=True,blank=True)
    email = models.EmailField(blank=True,null=True)
    entreprise = models.CharField(max_length=50,null=True,blank=True)

    def __str__(self):
        if self.user:
            return str(self.user.username)
        return str(self.user)

class Formation(models.Model):
    name = models.CharField(max_length=50)
    num_salle = models.CharField(max_length=50)
    domaine = models.CharField(max_length=50,blank=True,null=True)
    description = models.TextField(blank=True, null=True)
    date_debut = models.DateField(blank=True, null=True)
    horraire_debut = models.TimeField(blank=True, null=True)
    date_fin = models.DateField(blank=True, null=True)
    formateur = models.ForeignKey(Formateur, on_delete=models.CASCADE)
    max_places = models.IntegerField(blank=True, null=True,default=20)
    image = models.ImageField(upload_to="images-formation",blank=True, null=True)
    participant = models.ManyToManyField(Participant,blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE,null=True,blank=True)
    slug = models.SlugField(null=True,blank=True)
    def __str__(self):
        return str(self.name + " par " + self.formateur.name)
    def save(self, *args, **kwargs):
        if Formation.objects.count() >= self.max_places:
            raise ValidationError("la formation est saturé.")
        super().save(*args, **kwargs)

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE,blank=True, null=True)
    email = models.EmailField(max_length=254,blank=True, null=True)
    image = models.ImageField(upload_to="images/users/",blank=True, null=True)
    name = models.CharField(max_length=50,blank=True, null=True)
    def __str__(self):
        return str(self.user.username)

class Activity(models.Model):
    name = models.CharField(max_length=50,blank=True, null=True)
    user = models.ForeignKey(User,on_delete=models.CASCADE,blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True,blank=True, null=True)
    def __str__(self):
        return self.user.username

class Notification(models.Model):
    name = models.CharField(max_length=50,blank=True, null=True)
    timestamp = models.DateField(auto_now_add=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE,blank=True, null=True)
    def __str__(self):
        return self.name

@receiver(pre_save, sender=Formation)
def pre_save_receiver(sender, instance, *args, **kwargs):
   if not instance.slug:
       instance.slug = unique_slug_generator(instance)

@receiver(post_save, sender=Formation)
def formation_created_or_updated(sender, instance, created, **kwargs):
    if created:
        # If a new Formation object is created, create a notification object
        name = f"A new formation {instance.name} has been created"
    else:
        # If an existing Formation object is updated, create a notification object
        name = f'Formation "{instance.name}" has been updated.'
    user = get_user_model().objects.first()  # Replace this with your logic to get the user who triggered the action
    Notification.objects.create(name=name, user=user)

@receiver(post_delete, sender=Formation)
def formation_deleted(sender, instance, **kwargs):
    user = get_user_model().objects.first()  # Replace this with your logic to get the user who triggered the action
    Notification.objects.create(name=f'Formation "{instance.name}" has been deleted.', user=user)