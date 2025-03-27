const API_BASE_URL = "http://127.0.0.1:5000/api"; // Update if hosted elsewhere
const token = localStorage.getItem("token"); // Retrieve JWT Token

// 🔹 Create Slot (Doctor)
async function createSlot() {
    const start_time = document.getElementById("startTime").value;
    const end_time = document.getElementById("endTime").value;

    const response = await fetch(`${API_BASE_URL}/doctor/slots`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify({ start_time, end_time }),
    });

    const result = await response.json();
    document.getElementById("statusMessage").innerText = result.message;
}

// 🔹 Fetch Doctor's Slots
async function fetchDoctorSlots() {
    const response = await fetch(`${API_BASE_URL}/doctor/slots/mine`, {
        headers: { "Authorization": `Bearer ${token}` }
    });

    const result = await response.json();
    const list = document.getElementById("doctorSlotsList");
    list.innerHTML = "";

    if (response.ok) {
        result.doctor_slots.forEach(slot => {
            const li = document.createElement("li");
            li.innerHTML = `Slot: ${slot.start_time} - ${slot.end_time} 
                <button onclick="markBusy(${slot.id})">Busy</button> 
                <button onclick="deleteSlot(${slot.id})">Delete</button>`;
            list.appendChild(li);
        });
    } else {
        document.getElementById("statusMessage").innerText = result.message;
    }
}

// 🔹 Mark Slot as Busy (Doctor)
async function markBusy(slotId) {
    const response = await fetch(`${API_BASE_URL}/doctor/slots/busy/${slotId}`, {
        method: "POST",
        headers: { "Authorization": `Bearer ${token}` }
    });

    const result = await response.json();
    document.getElementById("statusMessage").innerText = result.message;
    fetchDoctorSlots();
}

// 🔹 Delete Slot (Doctor)
async function deleteSlot(slotId) {
    const response = await fetch(`${API_BASE_URL}/doctor/slots/delete/${slotId}`, {
        method: "DELETE",
        headers: { "Authorization": `Bearer ${token}` }
    });

    const result = await response.json();
    document.getElementById("statusMessage").innerText = result.message;
    fetchDoctorSlots();
}

// 🔹 Fetch Available Slots (Patients)
async function fetchAvailableSlots() {
    const response = await fetch(`${API_BASE_URL}/slots/available`, {
        headers: { "Authorization": `Bearer ${token}` }
    });

    const result = await response.json();
    const list = document.getElementById("availableSlotsList");
    list.innerHTML = "";

    if (response.ok) {
        result.available_slots.forEach(slot => {
            const li = document.createElement("li");
            li.innerHTML = `Doctor ${slot.doctor_id}: ${slot.start_time} - ${slot.end_time} 
                <button onclick="bookSlot(${slot.id})">Book</button>`;
            list.appendChild(li);
        });
    } else {
        document.getElementById("statusMessage").innerText = result.message;
    }
}


