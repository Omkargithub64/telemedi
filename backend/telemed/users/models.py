from django.contrib.auth.models import AbstractUser
from django.db import models

class Doctor(AbstractUser):  
    SPECIALIZATION_CHOICES = [
        ("Cardiologist", "Cardiologist"),
        ("Dermatologist", "Dermatologist"),
        ("Neurologist", "Neurologist"),
        ("Pediatrician", "Pediatrician"),
        ("General Physician", "General Physician"),
        # Add more as needed
    ]

    full_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True)
    profile_picture = models.ImageField(upload_to="doctor_profiles/", blank=True, null=True)

    specialization = models.CharField(max_length=50, choices=SPECIALIZATION_CHOICES)
    license_number = models.CharField(max_length=50, unique=True)
    experience_years = models.PositiveIntegerField()
    hospital_name = models.CharField(max_length=100, blank=True, null=True)
    consultation_fees = models.DecimalField(max_digits=10, decimal_places=2)

    available_days = models.JSONField(default=list)  # Store as ["Monday", "Wednesday"]
    available_time_slots = models.JSONField(default=list)  # Store as ["10:00-13:00", "17:00-20:00"]
    
    about_me = models.TextField(blank=True, null=True)
    languages_spoken = models.JSONField(default=list)  # Store as ["English", "Hindi"]
    video_consultation_enabled = models.BooleanField(default=True)

    is_verified = models.BooleanField(default=False)  # Admin Verification
    
    groups = models.ManyToManyField(
        "auth.Group",
        related_name="doctor_users",
        blank=True
    )
    user_permissions = models.ManyToManyField(
        "auth.Permission",
        related_name="doctor_users",
        blank=True
    )
    
    
    def __str__(self):
        return f"{self.full_name} - {self.specialization}"



class Patient(AbstractUser):  
    GENDER_CHOICES = [
        ("Male", "Male"),
        ("Female", "Female"),
        ("Other", "Other"),
    ]

    full_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True)
    profile_picture = models.ImageField(upload_to="patient_profiles/", blank=True, null=True)
    
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    address = models.TextField(blank=True, null=True)

    medical_history = models.JSONField(default=list)  # Store past diseases, surgeries
    current_medications = models.JSONField(default=list)  # Store ["Paracetamol", "Insulin"]
    allergies = models.JSONField(default=list)  # Store ["Peanuts", "Penicillin"]

    emergency_contact_name = models.CharField(max_length=100, blank=True, null=True)
    emergency_contact_phone = models.CharField(max_length=15, blank=True, null=True)
    
    groups = models.ManyToManyField(
        "auth.Group",
        related_name="patient_users",
        blank=True
    )
    user_permissions = models.ManyToManyField(
        "auth.Permission",
        related_name="patient_users",
        blank=True
    )
    
    def __str__(self):
        return f"{self.full_name} - {self.email}"
