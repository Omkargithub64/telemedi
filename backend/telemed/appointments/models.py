# from django.db import models
# from users.models import CustomUser

# class Appointment(models.Model):
#     patient = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='appointments')
#     doctor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='doctor_appointments')
#     date = models.DateTimeField()
#     status = models.CharField(max_length=20, choices=[('pending', 'Pending'), ('completed', 'Completed')])

#     def __str__(self):
#         return f"{self.patient.username} with {self.doctor.username}"
