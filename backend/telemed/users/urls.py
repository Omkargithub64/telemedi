from django.urls import path
from .views import *

urlpatterns = [
    path("register/", DoctorRegisterView.as_view(), name="doctor-register"),
    path("list/", VerifiedDoctorListView.as_view(), name="verified-doctor-list"),
    path("profile/<int:pk>/", DoctorDetailView.as_view(), name="doctor-profile"),
    path("verify/<int:doctor_id>/", verify_doctor, name="verify-doctor"),
    path("register/", PatientRegisterView.as_view(), name="patient-register"),
    path("list/", PatientListView.as_view(), name="patient-list"),
    path("profile/<int:pk>/", PatientDetailView.as_view(), name="patient-profile"),
    path("update/", PatientUpdateView.as_view(), name="patient-update"),
]
