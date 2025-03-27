from rest_framework import serializers
from .models import Doctor, Patient

class DoctorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Doctor
        fields = [
            "id", "username", "full_name", "email", "phone_number", "profile_picture",
            "specialization", "license_number", "experience_years", "hospital_name",
            "consultation_fees", "available_days", "available_time_slots", "about_me",
            "languages_spoken", "video_consultation_enabled", "is_verified"
        ]
        extra_kwargs = {
            "password": {"write_only": True},
            "is_verified": {"read_only": True}  # Prevent direct modification
        }

    def create(self, validated_data):

        password = validated_data.pop("password")
        doctor = Doctor(**validated_data)
        doctor.set_password(password)  # Hash password before saving
        doctor.save()
        return doctor


class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = [
            "id", "username", "full_name", "email", "phone_number", "profile_picture",
            "date_of_birth", "gender", "address", "medical_history",
            "current_medications", "allergies", "emergency_contact_name",
            "emergency_contact_phone"
        ]
        extra_kwargs = {
            "password": {"write_only": True},
        }

    def create(self, validated_data):
        """ Create patient and hash password """
        password = validated_data.pop("password")
        patient = Patient(**validated_data)
        patient.set_password(password)  # Hash password before saving
        patient.save()
        return patient

