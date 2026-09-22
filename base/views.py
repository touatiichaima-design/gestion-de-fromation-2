from django.shortcuts import render,get_object_or_404,redirect
from .models import Formation,Participant,Profile,Activity,Notification,Formateur
from .forms import UserRegisterForm,ProfileForm,FormationForm
from django.contrib.auth.decorators import login_required
from django.views.generic import ListView,DetailView,CreateView,UpdateView,DeleteView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse,reverse_lazy
from django.contrib.auth.models import User
import datetime
from django.contrib.auth import login,authenticate
from random import sample


class FormationListView(ListView):
    model = Formation
    template_name = "base/index.html"
    context_object_name = "myFormation"
    def get(self, request, *args, **kwargs):
        # Get the logged in user
        user = self.request.user

        # Call the parent's get() method to get the context data dictionary
        context = super().get(request, *args, **kwargs).context_data

        # Add the user to the context data dictionary
        context['user'] = user
        server_name = request.META['SERVER_NAME']
        context['formateurs'] = Formateur.objects.all()
        if user.is_authenticated:
            try:
                context['participant_user'] = Participant.objects.get(user=user)
            except:
                pass
        return self.render_to_response(context)
    
class FormationDetailView(DetailView):
    model = Formation
    template_name = "base/course-details.html"
    context_object_name = "formation"


class FormationCreateView(LoginRequiredMixin,CreateView):
    form_class = FormationForm
    template_name = "base/create_formation.html"
    queryset = Formation.objects.none()
    success_url = '/'
    def form_valid(self, form):
        # Set the user as the currently authenticated user
        form.instance.user = self.request.user
        return super().form_valid(form)
class FormationUpdate(UpdateView):
    model = Formation
    fields = ("name","num_salle","domaine","description","date_debut","horraire_debut","date_fin","formateur","max_places","image")
    template_name = "base/update_formation.html"    
    def get_success_url(self):
        formation_slug = self.kwargs['slug']
        formation = get_object_or_404(Formation, slug=formation_slug)
        return reverse_lazy('formation',kwargs={'slug':formation.slug})
    def form_valid(self, form):
        # Set the user as the currently authenticated user
        form.instance.user = self.request.user
        return super().form_valid(form)

class FormationDelete(DeleteView):
    model = Formation
    template_name = "base/delete_formation.html"
    def get_success_url(self):
        return reverse_lazy('profile')



@login_required
def join_formation(request, slug):
    formation = get_object_or_404(Formation, slug=slug)
    participant = Participant.objects.get(user=request.user)
    if participant:
        if participant in formation.participant.all():
            messages.error(request, "You have already joined this formation.")
            return reverse_lazy('home')
        else:
            formation.participant.add(participant)
            messages.success(request, "You have joined the formation successfully.")
            Activity.objects.create(name=f'participer a la formation {formation.name}',user=request.user)
    else:
        participant = Participant.objects.create(user=request.user)
        formation.participant.add(participant)
        messages.success(request, "You have joined the formation successfully.")
        Activity.objects.create(name=f'participer a la formation {formation.name}',user=request.user)
    formation.save()
    return redirect('profile')

@login_required
def leave_formation(request, slug):
    formation = get_object_or_404(Formation, slug=slug)
    participant = Participant.objects.get(user=request.user)
    if participant:
        if participant in formation.participant.all():
            formation.participant.remove(participant)
            messages.success(request, "You have left the formation successfully.")
            Activity.objects.create(name=f'annuler l"inscription de formation {formation.name}',user=request.user)
        else:
            messages.error(request, "You are not part of this formation.")
    else:
        messages.error(request, "You are not a registered participant.")
        return redirect('register')
    formation.save()
    return redirect('profile')


def signUpView(request):
    form = UserRegisterForm()
    if request.method == 'POST':
        form = UserRegisterForm(request.POST)
        if form.is_valid():
            form.save()
            user = User.objects.get(username=request.POST.get('username'))
            if user:
                Participant.objects.create(user=user,email=user.email)
                Profile.objects.create(user=user,name=user.username,email=user.email)
            # log in the user after successful registration
                username = form.cleaned_data.get('username')
                password = form.cleaned_data.get('password1')
                user = authenticate(username=username, password=password)
                if user is not None:
                    login(request, user)
                    return redirect(reverse_lazy('home'))
            return redirect(reverse_lazy('login'))
    context = {
        'form':form
    }
    return render(request,'registration/register.html',context)

@login_required
def profile(request):
    try:
        form = ProfileForm(instance=Profile.objects.get(user=request.user))
    except:
        form={}
    if request.method == 'POST':
        form = ProfileForm(request.POST,request.FILES,instance=Profile.objects.get(user=request.user))
        if form.is_valid():
            form.save()
            return redirect(reverse_lazy('profile'))
    context = {}
    if request.user:
        context['profile'] = Profile.objects.get(user=request.user)
        try:
            participant = Participant.objects.get(user=request.user)
            context['formations'] = participant.formation_set.all()
        except:
            pass
        context['activities'] = Activity.objects.filter(user=request.user)[:4]
        context['form'] = form
        context['allFormations'] = Formation.objects.all()[:10]
        notifications_rev= Notification.objects.order_by('-timestamp')
        if notifications_rev:
            notifications = []
            for notif in reversed(notifications_rev):
                notifications.append(notif)
            context['notifications'] = notifications[:5]
        try:
            context['suggestions'] = Formation.objects.exclude(participant=request.user.participant)[:3]
        except:
            pass
    return render(request, 'base/profile.html',context)

def formation_detail(request,slug):
    context = {}
    formation = {}
    if slug:
        formation = Formation.objects.get(slug=slug)
        print(formation.name)
    d1 = formation.date_debut
    d2 = formation.date_fin
    nb_jours = abs((d2 - d1).days)
    dates = []
    context['formation'] = formation
    while d1 <= d2:
        dates.append(d1)
        d1 += datetime.timedelta(days=1)
    context['dates'] = dates
    context['participants'] = formation.participant.all()
    return render(request, 'base/detail2.html',context)

#CRUD for formateur models
class FormateurListView(ListView):
    model = Formateur
    template_name = 'base/formateur_list.html'
    context_object_name = 'formateurs'

class FormateurCreateView(CreateView):
    model = Formateur
    fields = ['nom','prenom','email','domaine','image']
    template_name = 'base/formateur_create.html'
    def get_success_url(self):
        return reverse_lazy('formateur-list')
class FormateurUpdateView(UpdateView):
    model = Formateur
    fields = ['nom','prenom','email','image']
    template_name = 'base/formateur_update.html'
    def get_success_url(self):
        return reverse_lazy('formateur-list')
class FormateurDeleteView(DeleteView):
    model = Formateur
    template_name = 'base/formateur_delete.html'
    def get_success_url(self):
        return reverse_lazy('formateur-list')