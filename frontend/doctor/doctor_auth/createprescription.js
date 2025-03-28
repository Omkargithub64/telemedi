const API_BASE_URL = "http://127.0.0.1:5000/api"; // Base URL for your API

// 🔥 Load Medicines for Prescription Creation (this function can be omitted since no medicine selection is required now)
async function loadMedicines() {
    const response = await fetch(`${API_BASE_URL}/getmedicines`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${localStorage.getItem("token")}`  // JWT for authentication
        }
    });

    const result = await response.json();
    if (response.ok) {
        const medicines = result.medicines;
        const medicinesSelect = document.getElementById("medicines");
        medicinesSelect.innerHTML = "";  // Clear previous options
        medicines.forEach(medicine => {
            const option = document.createElement("option");
            option.value = medicine.id;
            option.textContent = medicine.name;
            medicinesSelect.appendChild(option);
        });
    } else {
        alert("Failed to load medicines: " + result.message);
    }
}

// 🔥 Create Medicine (Medicine will be added to the prescription automatically)
async function createMedicine() {
    const name = document.getElementById("medicine_name").value;
    const dosage = document.getElementById("medicine_dosage").value;
    const instructions = document.getElementById("medicine_instructions").value;

    const data = {
        name: name,
        dosage: dosage,
        instructions: instructions
    };

    const response = await fetch(`${API_BASE_URL}/medicines`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${localStorage.getItem("token")}`  // JWT for authentication
        },
        body: JSON.stringify(data),
    });

    const result = await response.json();

    if (response.ok) {
        document.getElementById("medicineMessage").innerText = "Medicine created successfully!";
        // Automatically create the prescription once medicine is created
        createPrescription(result.medicine_id);
    } else {
        document.getElementById("medicineMessage").innerText = "Error: " + result.message;
    }
}

// 🔥 Create Prescription (Medicine will be automatically added to the prescription)
async function createPrescription(medicineId) {
    // Dynamically retrieve patient and doctor names (you can replace this with logic to fetch from UI)
    const patient_name = "John Doe";  // Replace with dynamic data
    const doctor_name = "Dr. Smith";  // Replace with dynamic data

    const data = {
        patient_name: patient_name,
        doctor_name: doctor_name,
        medicines: [medicineId]  // Directly use the medicine ID that was just created
    };

    const response = await fetch(`${API_BASE_URL}/prescriptions`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${localStorage.getItem("token")}`  // JWT for authentication
        },
        body: JSON.stringify(data),
    });

    const result = await response.json();

    if (response.ok) {
        document.getElementById("message").innerText = "Prescription created successfully!";
    } else {
        document.getElementById("message").innerText = "Error: " + result.message;
    }
}

// 🔥 Initialize the page by handling form submissions
document.addEventListener("DOMContentLoaded", function() {
    // Handle the medicine form submission
    document.getElementById("create-medicine-form").addEventListener("submit", function(e) {
        e.preventDefault();
        createMedicine();
    });
});
