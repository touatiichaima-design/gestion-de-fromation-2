from django.contrib import admin
from .models import Formation,Formateur,Participant,Profile,Activity,Notification
# Register your models here.
admin.site.register(Formation)
admin.site.register(Formateur)
admin.site.register(Participant)
admin.site.register(Profile)
admin.site.register(Activity)
admin.site.register(Notification)
