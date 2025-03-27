from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.shortcuts import get_object_or_404
from .models import Doctor, Patient
from .serializers import DoctorSerializer, PatientSerializer


class DoctorRegisterView(generics.CreateAPIView):
    queryset = Doctor.objects.all()
    serializer_class = DoctorSerializer
    permission_classes = [permissions.AllowAny]  # Open to new registrations


class VerifiedDoctorListView(generics.ListAPIView):
    queryset = Doctor.objects.filter(is_verified=True)
    serializer_class = DoctorSerializer
    permission_classes = [permissions.AllowAny]  # Open access


class DoctorDetailView(generics.RetrieveAPIView):
    queryset = Doctor.objects.all()
    serializer_class = DoctorSerializer
    permission_classes = [permissions.IsAuthenticated]  # Only logged-in users


@api_view(["PATCH"])
@permission_classes([permissions.IsAdminUser])  # Only admin can verify
def verify_doctor(request, doctor_id):
    doctor = get_object_or_404(Doctor, id=doctor_id)
    doctor.is_verified = True
    doctor.save()
    return Response({"message": f"Doctor {doctor.full_name} verified successfully!"})


class PatientRegisterView(generics.CreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.AllowAny]  # Open to new registrations

# 2️⃣ List all patients (for admin use)
class PatientListView(generics.ListAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAdminUser]  # Only admin can view all patients

# 3️⃣ Get patient profile by ID
class PatientDetailView(generics.RetrieveAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]  # Only logged-in users

# 4️⃣ Update patient profile (Only Patient themselves)
class PatientUpdateView(generics.UpdateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        """ Allow only the logged-in patient to update their own profile """
        return self.request.user
