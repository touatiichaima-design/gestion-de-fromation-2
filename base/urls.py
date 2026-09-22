from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from .views import (
    FormationListView,
    FormationDetailView,
    join_formation,
    leave_formation,
    signUpView,
    profile,
    FormationCreateView,
    FormationUpdate,
    FormationDelete,
    formation_detail,
    FormateurListView,
    FormateurCreateView,
    FormateurUpdateView,
    FormateurDeleteView,
)

urlpatterns = [
    path("",FormationListView.as_view(),name="home"),
    path('formateurs/', FormateurListView.as_view(), name='formateur-list'),
    path('formateurs/create/', FormateurCreateView.as_view(), name='formateur-create'),
    path('formateurs/<int:pk>/update/', FormateurUpdateView.as_view(), name='formateur-update'),
    path('formateurs/<int:pk>/delete/', FormateurDeleteView.as_view(), name='formateur-delete'),
    path("profile/",profile,name="profile"),
    path("formation/create/",FormationCreateView.as_view(),name="create_formation"),
    path('user/register/', signUpView, name='register'),
    path("<slug:slug>/",FormationDetailView.as_view(),name="formation"),
    path("formation/<slug:slug>/",formation_detail,name="formation2"),
    path('formation/<slug:slug>/update',FormationUpdate.as_view(), name='update_formation'),
    path('formation/<slug:slug>/delete',FormationDelete.as_view(), name='delete_formation'),
    path('leave/<slug:slug>/',leave_formation, name='leave_formation'),
    path('join/<slug:slug>/',join_formation, name='join_formation'),
]+ static(settings.MEDIA_URL,document_root=settings.MEDIA_ROOT)
