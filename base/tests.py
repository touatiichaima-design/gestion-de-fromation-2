import datetime

from django.contrib.auth.models import User
from django.test import TestCase
from django.urls import reverse

from .models import Activity, Formateur, Formation, Notification, Participant, Profile


def make_formation(formateur, name="Docker & K8s", **extra):
    today = datetime.date.today()
    data = dict(name=name, num_salle="A1", domaine="DevOps", formateur=formateur,
                date_debut=today, date_fin=today + datetime.timedelta(days=3), max_places=20)
    data.update(extra)
    return Formation.objects.create(**data)


class PagesPubliquesTests(TestCase):
    """Les pages accessibles sans connexion répondent correctement."""

    def test_accueil(self):
        self.assertEqual(self.client.get(reverse("home")).status_code, 200)

    def test_connexion(self):
        self.assertEqual(self.client.get(reverse("login")).status_code, 200)

    def test_inscription(self):
        self.assertEqual(self.client.get(reverse("register")).status_code, 200)

    def test_admin_login(self):
        self.assertEqual(self.client.get("/admin/login/").status_code, 200)

    def test_profil_exige_une_connexion(self):
        r = self.client.get(reverse("profile"))
        self.assertEqual(r.status_code, 302)
        self.assertIn(reverse("login"), r["Location"])


class FormationModeleTests(TestCase):
    def setUp(self):
        self.formateur = Formateur.objects.create(nom="Ben Salah", prenom="Amine")

    def test_nom_long_cree_une_notification(self):
        """Régression : un nom de plus de 17 caractères faisait planter la création."""
        nom = "Kubernetes et Docker pour debutants avances"[:50]
        f = make_formation(self.formateur, name=nom)
        self.assertTrue(Notification.objects.filter(name__contains=nom).exists())
        f.name = nom.upper()
        f.save()
        f.delete()
        self.assertEqual(Notification.objects.count(), 3)

    def test_plus_de_20_formations(self):
        """Régression : save() bloquait toute création au-delà de max_places formations."""
        for i in range(22):
            make_formation(self.formateur, name=f"Formation {i}")
        self.assertEqual(Formation.objects.count(), 22)

    def test_str(self):
        f = make_formation(self.formateur)
        self.assertEqual(str(f), "Docker & K8s par Ben Salah")

    def test_slug_genere(self):
        f = make_formation(self.formateur)
        self.assertTrue(f.slug)


class InscriptionFormationTests(TestCase):
    def setUp(self):
        self.formateur = Formateur.objects.create(nom="Trabelsi", prenom="Sarra")
        self.user = User.objects.create_user("alice", "alice@test.tn", "MotDePasse-Test-123")
        self.client.login(username="alice", password="MotDePasse-Test-123")

    def test_inscription_sans_fiche_participant(self):
        """Régression : erreur 500 si l'utilisateur n'avait pas de fiche Participant."""
        f = make_formation(self.formateur, name="Securite des applications web")
        r = self.client.get(reverse("join_formation", args=[f.slug]))
        self.assertEqual(r.status_code, 302)
        participant = Participant.objects.get(user=self.user)
        self.assertIn(participant, f.participant.all())
        self.assertTrue(Activity.objects.filter(user=self.user).exists())

    def test_double_inscription_refusee(self):
        f = make_formation(self.formateur)
        self.client.get(reverse("join_formation", args=[f.slug]))
        r = self.client.get(reverse("join_formation", args=[f.slug]))
        self.assertEqual(r.status_code, 302)
        self.assertEqual(f.participant.count(), 1)

    def test_formation_complete(self):
        f = make_formation(self.formateur, max_places=1)
        autre = User.objects.create_user("bob", "bob@test.tn", "MotDePasse-Test-456")
        f.participant.add(Participant.objects.create(user=autre))
        self.client.get(reverse("join_formation", args=[f.slug]))
        self.assertEqual(f.participant.count(), 1)

    def test_desinscription(self):
        f = make_formation(self.formateur)
        self.client.get(reverse("join_formation", args=[f.slug]))
        r = self.client.get(reverse("leave_formation", args=[f.slug]))
        self.assertEqual(r.status_code, 302)
        self.assertEqual(f.participant.count(), 0)

    def test_detail_formation_inconnue(self):
        self.assertEqual(self.client.get(reverse("formation2", args=["inconnue"])).status_code, 404)

    def test_pages_connectees(self):
        f = make_formation(self.formateur)
        for url in [reverse("home"), reverse("formateur-list"), reverse("create_formation"),
                    reverse("formation", args=[f.slug])]:
            self.assertEqual(self.client.get(url).status_code, 200, url)

    def test_deconnexion_par_lien(self):
        r = self.client.get(reverse("logout"))
        self.assertEqual(r.status_code, 302)
        self.assertEqual(self.client.get(reverse("profile")).status_code, 302)

    def test_profil_sans_photo(self):
        """Régression : une image absente faisait planter les pages (image.url)."""
        Profile.objects.create(user=self.user, name="alice")
        make_formation(self.formateur)
        self.assertEqual(self.client.get(reverse("profile")).status_code, 200)
