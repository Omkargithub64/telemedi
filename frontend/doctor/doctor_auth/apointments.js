const API_BASE_URL = "http://127.0.0.1:5000/api/doctor";

// Redirect to login if no token is found
const token = localStorage.getItem("token");
if (!token) {
    window.location.href = "index.html";
}

// Fetch doctor's appointments
async function fetchAppointments() {
    try {
        const response = await fetch(`${API_BASE_URL}/appointments`, {
            method: "GET",
            headers: {
                "Authorization": `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error("Failed to fetch appointments");
        }

        const data = await response.json();

        if (data.appointments.length === 0) {
            document.getElementById("appointmentsTable").innerHTML = `
                <tr><td colspan="3">No appointments available.</td></tr>
            `;
        } else {
            const appointments = data.appointments;
            const tableBody = document.querySelector("#appointmentsTable tbody");
            tableBody.innerHTML = ""; // Clear the table first

            appointments.forEach(appointment => {
                const row = document.createElement("tr");
                row.innerHTML = `
                    <td>${appointment.patient_name}</td>
                    <td>${appointment.date}</td>
                    <td>${appointment.reason}</td>
                    <td><button>Start Consultancy</button></td>
                `;
                tableBody.appendChild(row);
            });
        }
    } catch (error) {
        console.error("Error:", error);
        alert("Session expired or error occurred. Please login again.");
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

// Load appointments when the page is ready
fetchAppointments();
