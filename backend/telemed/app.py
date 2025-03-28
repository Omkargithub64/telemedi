import re
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Api, Resource
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_cors import CORS
from datetime import datetime
import time
import cloudinary
import cloudinary.uploader
import os
from agora_token_builder import RtcTokenBuilder
from sqlalchemy import Column, ForeignKey, Integer, Table

# Initialize Flask App
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///patients.db'  # Use PostgreSQL/MySQL in production
app.config['JWT_SECRET_KEY'] = 'your-secret-key'  # Change this to a strong secret key

db = SQLAlchemy(app)
api = Api(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)
CORS(app)  # Enable CORS for all origins


AGORA_APP_ID = '0db4693a0a32494588c04474878670f5'
AGORA_APP_CERTIFICATE = '0f94c973cf684c7880feb31d273fcf5f'


cloudinary.config(
    cloud_name="dfr9yu2mi",
    api_key="999488851942618",
    api_secret="-SbXYOVyMIKfSnrFj6SWFxlSoAQ"
)



prescription_medicine = Table('prescription_medicine', db.metadata,
    Column('prescription_id', Integer, ForeignKey('prescription.id')),
    Column('medicine_id', Integer, ForeignKey('medicine.id'))
)

class Patient(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    phone_number = db.Column(db.String(15), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    profile_picture = db.Column(db.String(300), nullable=True)  
    prescriptions = db.relationship('Prescription', backref='patient', lazy=True)# Cloudinary URL



class Doctor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    phone_number = db.Column(db.String(15), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    password = db.Column(db.String(200), nullable=False)
    profile_url = db.Column(db.String(300), nullable=True)  # Cloudinary URL

    specialization = db.Column(db.String(100), nullable=False)
    qualification = db.Column(db.String(200), nullable=False)
    experience = db.Column(db.Integer, nullable=False)
    license_number = db.Column(db.String(50), unique=True, nullable=False)

    clinic_name = db.Column(db.String(200), nullable=False)
    clinic_address = db.Column(db.Text, nullable=False)

    is_verified = db.Column(db.Boolean, default=False)  # Doctor verification status
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Password Hashing Methods
    def set_password(self, password):
        self.password = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password, password)




# ----------------------- Appointment Model -----------------------
class Appointment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)
    doctor_name = db.Column(db.String(100), nullable=False)
    date = db.Column(db.DateTime, nullable=False)
    reason = db.Column(db.String(255), nullable=False)

# ----------------------- Health Records Model -----------------------
class HealthRecord(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)
    record_name = db.Column(db.String(100), nullable=False)
    record_url = db.Column(db.String(300), nullable=False) 
    upload_date = db.Column(db.DateTime, default=datetime.utcnow)

# ----------------------- API Routes -----------------------


class Slot(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    is_booked = db.Column(db.Boolean, default=False)
    busy = db.Column(db.Boolean, default=False)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    doctor = db.relationship('Doctor', backref=db.backref('slots', lazy=True))




class Medicine(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    dosage = db.Column(db.String(255), nullable=False)
    instructions = db.Column(db.Text, nullable=False)
    
    def __repr__(self):
        return f'<Medicine {self.name}>'

class Prescription(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=False)  # Assuming a User model for doctors
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)
    date = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    medicines = db.relationship('Medicine', secondary='prescription_medicine', backref='prescriptions')
    
    def __repr__(self):
        return f'<Prescription for {self.patient_name}>'
 

class PatientRegister(Resource):
    def post(self):
        data = request.get_json()

        required_fields = ["username", "full_name", "email", "phone_number", "date_of_birth", "gender", "password"]
        if not all(field in data for field in required_fields):
            return {"message": "All fields are required"}, 400

        if Patient.query.filter_by(email=data["email"]).first():
            return {"message": "Email already registered"}, 400
        if Patient.query.filter_by(username=data["username"]).first():
            return {"message": "Username already taken"}, 400

        new_patient = Patient(
            username=data["username"],
            full_name=data["full_name"],
            email=data["email"],
            phone_number=data["phone_number"],
            date_of_birth=datetime.strptime(data["date_of_birth"], '%Y-%m-%d'),
            gender=data["gender"],
            password_hash=bcrypt.generate_password_hash(data["password"]).decode('utf-8')
        )
        db.session.add(new_patient)
        db.session.commit()

        return {"message": "Patient registered successfully"}, 201
class PatientLogin(Resource):
    def post(self):
        data = request.get_json()
        patient = Patient.query.filter_by(email=data.get("email")).first()

        if not patient or not bcrypt.check_password_hash(patient.password_hash, data.get("password")):
            return {"message": "Invalid credentials"}, 401

        access_token = create_access_token(identity=patient.id)
        
        # Send all required fields in response
        return {
            "token": access_token,
            "patient_id": patient.id,
            "full_name": patient.full_name,
            "email": patient.email,
            "phone_number": patient.phone_number,
            "date_of_birth": patient.date_of_birth.strftime('%Y-%m-%d'),
            "gender": patient.gender,
            "profile_picture": patient.profile_picture if patient.profile_picture else ""
        }, 200

class PatientProfile(Resource):
    @jwt_required()
    def get(self):
        patient_id = get_jwt_identity()
        patient = Patient.query.get(patient_id)

        if not patient:
            return {"message": "Patient not found"}, 404

        return {
            "patient_id": patient.id,
            "full_name": patient.full_name,
            "email": patient.email,
            "phone_number": patient.phone_number,
            "date_of_birth": patient.date_of_birth.strftime('%Y-%m-%d'),
            "gender": patient.gender,
            "profile_picture": patient.profile_picture if patient.profile_picture else ""
        }, 200


class UploadHealthRecord(Resource):
    @jwt_required()
    def post(self):
        patient_id = get_jwt_identity()
        print(f" Patient ID: {patient_id}")

        if 'file' not in request.files:
            print(" No file found in request")
            return {"message": "No file uploaded"}, 400

        file = request.files['file']
        record_name = request.form.get('record_name')

        if not record_name:
            print(" Record name missing")
            return {"message": "Record name is required"}, 400

        print(f" File received: {file.filename}")
        print(f" Record Name: {record_name}")

        try:
            # Upload file to Cloudinary
            upload_result = cloudinary.uploader.upload(file)
            record_url = upload_result['secure_url']
            print(f" Uploaded to Cloudinary: {record_url}")

            # Save to DB
            new_record = HealthRecord(
                patient_id=patient_id,
                record_name=record_name,
                record_url=record_url
            )
            db.session.add(new_record)
            db.session.commit()

            return {"message": "Health record uploaded successfully", "record_url": record_url}, 201

        except Exception as e:
            print(f"Exception: {e}")
            return {"message": str(e)}, 500

# ----------------------- Get All Health Records -----------------------
class GetHealthRecords(Resource):
    @jwt_required()
    def get(self):
        patient_id = get_jwt_identity()
        records = HealthRecord.query.filter_by(patient_id=patient_id).all()

        if not records:
            return {"message": "No health records found"}, 404

        record_list = [
            {
                "id": record.id,
                "record_name": record.record_name,
                "record_url": record.record_url,
                "upload_date": record.upload_date.strftime('%Y-%m-%d %H:%M:%S')
            }
            for record in records
        ]

        return {"health_records": record_list}, 200


# ----------------------- Delete a Health Record -----------------------
class DeleteHealthRecord(Resource):
    @jwt_required()
    def delete(self, record_id):
        patient_id = get_jwt_identity()
        record = HealthRecord.query.filter_by(id=record_id, patient_id=patient_id).first()

        if not record:
            return {"message": "Health record not found"}, 404

        try:
            # Delete file from Cloudinary
            public_id = record.record_url.split("/")[-1].split(".")[0]  # Extract public ID from URL
            cloudinary.uploader.destroy(public_id)

            # Delete record from DB
            db.session.delete(record)
            db.session.commit()

            return {"message": "Health record deleted successfully"}, 200

        except Exception as e:
            return {"message": str(e)}, 500

class RegisterDoctor(Resource):
    def post(self):
        if not request.is_json:
            return {"error": "Invalid request, JSON expected"}, 400

        data = request.get_json()

        if Doctor.query.filter_by(email=data.get('email')).first():
            return {"error": "Email already registered"}, 400

        try:
            hashed_password = bcrypt.generate_password_hash(data.get('password'))

            doctor = Doctor(
                username=data.get('username'),
                full_name=data.get('full_name'),
                email=data.get('email'),
                phone_number=data.get('phone_number'),
                date_of_birth=datetime.strptime(data.get('date_of_birth'), "%Y-%m-%d"),
                gender=data.get('gender'),
                specialization=data.get('specialization'),
                qualification=data.get('qualification'),
                experience=int(data.get('experience')),
                password=hashed_password,
                license_number=data.get('license_number'),
                clinic_name=data.get('clinic_name'),
                clinic_address=data.get('clinic_address'),
            )

            db.session.add(doctor)
            db.session.commit()

            return {"message": "Doctor registered successfully"}, 201

        except Exception as e:
            db.session.rollback()
            return {"error": "An error occurred", "details": str(e)}, 500

# ----------------------- Login a Doctor -----------------------
class LoginDoctor(Resource):
    def post(self):
        data = request.json
        doctor = Doctor.query.filter_by(email=data['email']).first()

        if not doctor or not bcrypt.check_password_hash(doctor.password, data['password']):
            return {"message": "Invalid email or password"}, 401

        access_token = create_access_token(identity=doctor.id)
        return {"token": access_token, "message": "Login successful"}, 200


# ----------------------- Get Doctor Profile -----------------------
class DoctorProfile(Resource):
    @jwt_required()
    def get(self):
        doctor_id = get_jwt_identity()
        doctor = Doctor.query.get(doctor_id)

        if not doctor:
            return {"error": "Doctor not found"}, 404

        return {
            "full_name": doctor.full_name,
            "email": doctor.email,
            "specialization": doctor.specialization,
            "clinic_name": doctor.clinic_name
        }, 200



class CreateSlots(Resource):
    @jwt_required()
    def post(self):
        doctor_id = get_jwt_identity()
        data = request.get_json()

        try:
            start_time = datetime.strptime(data.get('start_time'), '%H:%M').time()
            end_time = datetime.strptime(data.get('end_time'), '%H:%M').time()

            if end_time <= start_time:
                return {"message": "End time must be after start time"}, 400

            slot = Slot(
                doctor_id=doctor_id,
                start_time=start_time,
                end_time=end_time
            )

            db.session.add(slot)
            db.session.commit()

            return {"message": "Slot created successfully"}, 201

        except Exception as e:
            db.session.rollback()
            return {"error": "An error occurred", "details": str(e)}, 500


class GetDoctorSlots(Resource):
    @jwt_required()
    def get(self):
        doctor_id = get_jwt_identity()
        slots = Slot.query.filter_by(doctor_id=doctor_id).all()

        if not slots:
            return {"message": "No slots found"}, 404

        slot_list = [
            {
                "id": slot.id,
                "start_time": slot.start_time.strftime('%H:%M'),
                "end_time": slot.end_time.strftime('%H:%M'),
                "is_booked": slot.is_booked,
                "busy": slot.busy,
                "created_at": slot.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            for slot in slots
        ]

        return {"doctor_slots": slot_list}, 200


class GetAvailableSlots(Resource):
    @jwt_required()
    def get(self):
        slots = Slot.query.filter_by(is_booked=False, busy=False).all()

        if not slots:
            return {"message": "No available slots found"}, 404

        slot_list = [
            {
                "id": slot.id,
                "doctor_id": slot.doctor_id,
                "start_time": slot.start_time.strftime('%H:%M'),
                "end_time": slot.end_time.strftime('%H:%M'),
                "created_at": slot.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            for slot in slots
        ]

        return {"available_slots": slot_list}, 200



class MarkSlotBusy(Resource):
    @jwt_required()
    def post(self, slot_id):
        doctor_id = get_jwt_identity()
        slot = Slot.query.get(slot_id)

        if not slot:
            return {"message": "Slot not found"}, 404

        if slot.doctor_id != doctor_id:
            return {"message": "Unauthorized to mark this slot as busy"}, 403

        slot.busy = True
        db.session.commit()

        return {"message": "Slot marked as busy"}, 200

class UnmarkSlotBusy(Resource):
    @jwt_required()
    def post(self, slot_id):
        doctor_id = get_jwt_identity()
        slot = Slot.query.get(slot_id)

        if not slot:
            return {"message": "Slot not found"}, 404

        if slot.doctor_id != doctor_id:
            return {"message": "Unauthorized to unmark this slot as busy"}, 403

        slot.busy = False
        db.session.commit()

        return {"message": "Slot unmarked as busy"}, 200
    
    
class DeleteSlot(Resource):
    @jwt_required()
    def delete(self, slot_id):
        doctor_id = get_jwt_identity()
        slot = Slot.query.get(slot_id)

        if not slot:
            return {"message": "Slot not found"}, 404

        if slot.doctor_id != doctor_id:
            return {"message": "Unauthorized to delete this slot"}, 403

        db.session.delete(slot)
        db.session.commit()

        return {"message": "Slot deleted successfully"}, 200



class BookSlot(Resource):
    @jwt_required()
    def post(self, slot_id):
        patient_id = get_jwt_identity()  # Get logged-in patient's ID

        # Fetch the slot
        slot = Slot.query.get(slot_id)
        if not slot:
            return {"message": "Slot not found"}, 404

        if slot.is_booked:
            return {"message": "Slot is already booked"}, 400

        # Fetch doctor details
        doctor = Doctor.query.get(slot.doctor_id)
        if not doctor:
            return {"message": "Doctor not found"}, 404

        # Fetch patient details
        patient = Patient.query.get(patient_id)
        if not patient:
            return {"message": "Patient not found"}, 404

        # Get appointment reason from request
        data = request.get_json()
        reason = data.get("reason", "General Consultation")

        # Create an appointment entry
        appointment = Appointment(
            patient_id=patient.id,
            doctor_name=doctor.full_name,
            date=datetime.utcnow(),
            reason=reason
        )
        db.session.add(appointment)

        # Mark the slot as booked
        slot.is_booked = True
        slot.busy = True
        db.session.commit()

        return {"message": "Slot booked successfully, appointment created"}, 200


class GetAppointments(Resource):
    @jwt_required()
    def get(self):
        patient_id = get_jwt_identity()  # Get logged-in patient's ID

        # Fetch the patient's appointments
        appointments = Appointment.query.filter_by(patient_id=patient_id).all()
        if not appointments:
            return {"message": "No appointments found"}, 404

        # Prepare the response data
        appointment_list = []
        for appointment in appointments:
            appointment_list.append({
                "id": appointment.id,
                "doctor_name": appointment.doctor_name,
                "date": appointment.date.strftime("%Y-%m-%d %H:%M:%S"),
                "reason": appointment.reason
            })

        return {"appointments": appointment_list}, 200
class GetDoctorAppointments(Resource):
    @jwt_required()
    def get(self):
        doctor_id = get_jwt_identity()  # Get logged-in doctor's ID from the JWT token

        # Fetch the doctor by ID
        doctor_id = get_jwt_identity()  # Get logged-in doctor's name from the JWT token

        # Fetch the doctor by name
        doctor = Doctor.query.filter_by(id=doctor_id).first()
        if not doctor:
            return {"message": "Doctor not found"}, 404

        # Fetch the doctor's appointments using the doctor_id
        appointments = Appointment.query.filter_by(doctor_name=doctor.full_name).all()
        if not appointments:
            return {"message": "No appointments found for this doctor"}, 404

        # Prepare the response data
        appointment_list = []
        for appointment in appointments:
            # Fetch the patient for each appointment
            patient = Patient.query.filter_by(id=appointment.patient_id).first()
            if patient:
                patient_name = patient.full_name  # Assuming the Patient model has a full_name field
            else:
                patient_name = "Unknown"

            appointment_list.append({
                "id": appointment.id,
                "patient_name": patient_name,  # Use the patient_name extracted from the patient object
                "date": appointment.date.strftime("%Y-%m-%d %H:%M:%S"),
                "reason": appointment.reason
            })

        return {"appointments": appointment_list}, 200
    
    
    
@app.route('/get-token', methods=['POST'])
def get_token():
    channel_name = request.json.get('channel_name')
    user_id = request.json.get('user_id')

    expiration_time_in_seconds = 3600  # 1 hour expiration
    current_timestamp = int(time.time())
    expired_timestamp = current_timestamp + expiration_time_in_seconds

    # User role: 0 for publisher (can publish streams), 1 for subscriber (only receives streams)
    role = 1 if user_id != 'local' else 0

    token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channel_name,
        0,  # UID = 0 for anonymous user
        role,
        expired_timestamp
    )
    # 007eJxTYMi2nGRRtUjjrtLi+y0LVu49VDtX22VW3Vu3GRMK13MmGKorMBikJJmYWRonGiQaG5lYmphaWCQbmJiYm1iYW5iZG6SZSj5+mt4QyMjwO7CFmZEBAkF8VgZDI2MTUwYGADxBHhI=
    
    return jsonify({"token": token, "channel_name": channel_name})


@app.route('/room/<int:room>')
def room(room):
    context = {
        'interviewid': str(room),  # Use room number as interview ID
        'user': "1",               # Example user ID
        'interviewer': "1"         # Example interviewer ID
    }
    return jsonify(context)




class GetPrescriptions(Resource):
    @jwt_required()
    def get(self):
        patient_id = get_jwt_identity()  # Get the patient ID from the JWT token
        prescriptions = Prescription.query.filter_by(patient_id=patient_id).all()

        if not prescriptions:
            return {"message": "No prescriptions found"}, 404

        prescription_list = [
            {
                "id": prescription.id,
                "patient_name": prescription.patient_name,
                "doctor_name": prescription.doctor_name,
                "date": prescription.date.strftime('%Y-%m-%d'),
                "medicines": [
                    {
                        "medicine_name": medicine.name,
                        "dosage": medicine.dosage,
                        "instructions": medicine.instructions
                    }
                    for medicine in prescription.medicines
                ]
            }
            for prescription in prescriptions
        ]

        return {"prescriptions": prescription_list}, 200
    
class GetMedicines(Resource):
    @jwt_required()
    def get(self):
        medicines = Medicine.query.all()  # Assuming `Medicine` is a defined model in your app

        if not medicines:
            return {"message": "No medicines found"}, 404

        medicine_list = [
            {
                "id": medicine.id,
                "name": medicine.name,
                "dosage": medicine.dosage,
                "instructions": medicine.instructions
            }
            for medicine in medicines
        ]

        return {"medicines": medicine_list}, 200



class CreatePrescription(Resource):
    @jwt_required()
    def post(self):
        patient_id = get_jwt_identity()  # Get the patient ID from JWT token
        data = request.get_json()

        # Validate required fields
        if not data.get("patient_name") or not data.get("medicines"):
            return {"message": "Missing required fields (patient_name, medicines)"}, 400

        # Create new prescription
        new_prescription = Prescription(
            patient_name=data["patient_name"],
            doctor_name=data["doctor_name"],  # You can get the doctor's name from the JWT token or request data
            patient_id=patient_id
        )

        db.session.add(new_prescription)
        db.session.commit()  # Save the prescription to get the ID

        # Add medicines to the prescription
        for medicine_data in data["medicines"]:
            medicine = Medicine.query.get(medicine_data["medicine_id"])
            if medicine:
                new_prescription.medicines.append(medicine)
            else:
                return {"message": f"Medicine with ID {medicine_data['medicine_id']} not found"}, 404
        
        db.session.commit()

        return {"message": "Prescription created successfully", "prescription_id": new_prescription.id}, 201
    
class CreateMedicine(Resource):
    @jwt_required()
    def post(self):
        data = request.get_json()

        # Validate required fields
        if not data.get("name") or not data.get("dosage") or not data.get("instructions"):
            return {"message": "Missing required fields (name, dosage, instructions)"}, 400

        # Create new medicine entry
        new_medicine = Medicine(
            name=data["name"],
            dosage=data["dosage"],
            instructions=data["instructions"]
        )

        db.session.add(new_medicine)
        db.session.commit()

        return {"message": "Medicine created successfully", "medicine_id": new_medicine.id}, 201











# ----------------------- Register API Routes -----------------------
api.add_resource(PatientRegister, "/api/users/patients/register/")
api.add_resource(PatientLogin, "/api/users/patients/login/")
api.add_resource(PatientProfile, "/api/users/patients/profile/")
api.add_resource(UploadHealthRecord, '/api/health_records/upload/')
api.add_resource(GetHealthRecords, "/api/health_records/")
api.add_resource(DeleteHealthRecord, "/api/health_records/<int:record_id>/")
api.add_resource(RegisterDoctor, "/api/doctor/register")
api.add_resource(LoginDoctor, "/api/doctor/login")
api.add_resource(DoctorProfile, "/api/doctor/profile")
api.add_resource(CreateSlots, "/api/doctor/slots")
api.add_resource(GetAvailableSlots, "/api/slots/available")
api.add_resource(GetDoctorSlots, "/api/doctor/slots/mine")
api.add_resource(BookSlot, "/api/patient/slots/book/<int:slot_id>")
api.add_resource(GetAppointments, "/api/patient/appointments")
api.add_resource(GetDoctorAppointments, "/api/doctor/appointments")
api.add_resource(MarkSlotBusy, "/api/doctor/slots/busy/<int:slot_id>")
api.add_resource(UnmarkSlotBusy, "/api/doctor/slots/unbusy/<int:slot_id>")
api.add_resource(DeleteSlot, "/api/doctor/slots/delete/<int:slot_id>")
api.add_resource(CreateMedicine, "/api/medicines")
api.add_resource(GetMedicines, "/api/getmedicines")
api.add_resource(CreatePrescription, "/api/prescriptions")


# api.add_resource(StartConsultancy, '/api/start-consultancy')



# ----------------------- Run the App -----------------------
if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(debug=True)
