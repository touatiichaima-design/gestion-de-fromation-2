from django import forms
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import Formation,Profile
import datetime

class UserRegisterForm(UserCreationForm):
    email = forms.EmailField()
    cin = forms.CharField(max_length=8, required=True)
    class Meta:
        model = User
        fields = ['username', 'cin', 'email', 'password1', 'password2']
    def __init__(self, *args, **kwargs):
        super(UserRegisterForm, self).__init__(*args, **kwargs)
        for visible in self.visible_fields():
            visible.field.widget.attrs['class'] = 'form-control'
    def clean_cin(self):
        cin = self.cleaned_data['cin']
        if cin:
            nb_cin = len(cin)
        if nb_cin != 8 :
            raise ValidationError(_("votre cin doit etre 8 chiffres ! si vous n'avez pas carte n'hésitez pas le faire :)"))
        return cin       

class ProfileForm(forms.ModelForm):
    
    class Meta:
        model = Profile
        fields = ("name","email","image")
    def __init__(self, *args, **kwargs):
        super(ProfileForm, self).__init__(*args, **kwargs)
        for visible in self.visible_fields():
            visible.field.widget.attrs['class'] = 'form-control'

class FormationForm(forms.ModelForm):
    
    class Meta:
        model = Formation
        fields = ("name","num_salle","domaine","description","date_debut","horraire_debut","date_fin","formateur","max_places","image")
        widgets = {
            'date_debut': forms.DateInput(attrs={'type': 'date'}),
            'date_fin': forms.DateInput(attrs={'type': 'date'}),
            'horraire_debut' : forms.TimeInput(attrs={'type': 'time'}),
        }
    def __init__(self, *args, **kwargs):
        super(FormationForm, self).__init__(*args, **kwargs)
        for visible in self.visible_fields():
            visible.field.widget.attrs['class'] = 'form-control'
    def clean_date_fin(self,*args, **kwargs):
        date = self.cleaned_data['date_debut']
        data = self.cleaned_data['date_fin']
        if date < datetime.date.today():
            raise ValidationError(_("la date de debut doit etre a partir d'aujoudrd'hui !"))
        if data < self.cleaned_data['date_debut']:
            raise ValidationError(_("la date de fin doit etre superieur au date debut !"))
        if data > (datetime.date.today() + datetime.timedelta(weeks=4)):
            raise ValidationError(_("la periode de formation est trés long:"))
        return data