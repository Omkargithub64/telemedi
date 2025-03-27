const API_BASE_URL = "http://127.0.0.1:5000/api/doctor"; // Change if running on a different server
// 🔥 Doctor Login
async function loginDoctor() {
    const email = document.getElementById("loginEmail").value;
    const password = document.getElementById("loginPassword").value;

    const response = await fetch(`${API_BASE_URL}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
    });

    const result = await response.json();

    if (response.ok) {
        localStorage.setItem("token", result.token); // Save JWT
        document.getElementById("loginMessage").innerText = "Login successful! Redirecting...";

        setTimeout(() => {
            window.location.href = "dashboard.html";  // Redirect to dashboard
        }, 2000);
    } else {
        document.getElementById("loginMessage").innerText = "Login failed: " + result.message;
    }
}

// 🔥 Doctor Registration
async function registerDoctor() {
    const data = {
        full_name: document.getElementById("registerFullName").value,
        username: document.getElementById("registerUsername").value,
        email: document.getElementById("registerEmail").value,
        phone_number: document.getElementById("registerPhone").value,
        date_of_birth: document.getElementById("registerDob").value,
        gender: document.getElementById("registerGender").value,
        specialization: document.getElementById("registerSpecialization").value,
        qualification: document.getElementById("registerQualification").value,
        experience: parseInt(document.getElementById("registerExperience").value),
        license_number: document.getElementById("registerLicense").value,
        clinic_name: document.getElementById("registerClinicName").value,
        clinic_address: document.getElementById("registerClinicAddress").value,
        password: document.getElementById("registerPassword").value
    };

    const response = await fetch(`${API_BASE_URL}/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
    });

    const result = await response.json();

    if (response.ok) {
        document.getElementById("registerMessage").innerText = "Registration successful!";
    } else {
        document.getElementById("registerMessage").innerText = "Error: " + result.message;
    }
}



