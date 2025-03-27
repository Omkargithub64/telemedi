const API_BASE_URL = "http://127.0.0.1:5000/api/doctor";

// Redirect to login if no token is found
const token = localStorage.getItem("token");
if (!token) {
    window.location.href = "index.html";
}

// Fetch doctor details
async function fetchDoctorDetails() {
    document.getElementById("loadingState").style.display = 'block';  // Show loading state
    try {
        const response = await fetch(`${API_BASE_URL}/profile`, {
            method: "GET",
            headers: {
                "Authorization": `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error("Failed to fetch doctor details");
        }

        const doctor = await response.json();
        document.getElementById("doctorName").innerText = doctor.full_name;
        document.getElementById("doctorEmail").innerText = doctor.email;
        document.getElementById("doctorSpecialization").innerText = doctor.specialization;
        document.getElementById("doctorClinic").innerText = doctor.clinic_name;

        document.getElementById("loadingState").style.display = 'none'; // Hide loading state
    } catch (error) {
        console.error("Error:", error);
        document.getElementById("loadingState").style.display = 'none';
        document.getElementById("errorState").innerText = 'Session expired or error occurred. Please login again.';
        document.getElementById("errorState").style.display = 'block';
        localStorage.removeItem("token");
        setTimeout(() => {
            window.location.href = "index.html";
        }, 3000); // Redirect after 3 seconds
    }
}

// Logout function with confirmation
document.getElementById("logoutBtn").addEventListener("click", () => {
    const confirmLogout = confirm("Are you sure you want to log out?");
    if (confirmLogout) {
        localStorage.removeItem("token");
        window.location.href = "index.html";
    }
});

// Load doctor details on page load
fetchDoctorDetails();
