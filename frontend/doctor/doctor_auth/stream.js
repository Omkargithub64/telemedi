
const APP_ID = 'f9baa6f6f8a442e59264c1895147ad90';
const CHANNEL = "12345";  // Channel name should be dynamic based on room
const TOKEN = "007eJxTYMi2nGRRtUjjrtLi+y0LVu49VDtX22VW3Vu3GRMK13MmGKorMBikJJmYWRonGiQaG5lYmphaWCQbmJiYm1iYW5iZG6SZSj5+mt4QyMjwO7CFmZEBAkF8VgZDI2MTUwYGADxBHhI="


const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

let localTracks = [];
let remoteUsers = {};


let joinAndDisplayLocalStream = async () => {
    document.getElementById('room-name').innerHTML = CHANNEL;

    client.on('user-published', handleUserJoined);
    client.on('user-left', handleUserLeft);

    try {
        // Joining the Agora channel and getting UID
        UID = await client.join(APP_ID, CHANNEL, TOKEN);
        
        // Update URL to reflect the room ID (e.g., /room/3)
        window.history.pushState({}, '', `/room/${CHANNEL}`);
        
        // Publish local streams
        localTracks = await AgoraRTC.createMicrophoneAndCameraTracks();
        let player = `<div class="video-container2" id="user-container-${UID}">
                        <div class="username-wrapper"><span class="user-name">My name</span></div>
                        <div class="video-player" id="user-${UID}"></div>
                      </div>`;
        document.getElementById('vid-streams').insertAdjacentHTML('beforeend', player);

        localTracks[1].play(`user-${UID}`);
        await client.publish([localTracks[0], localTracks[1]]);
    } catch (error) {
        console.error('Error joining and displaying local stream:', error);
    }
};

let handleUserJoined = async (user, mediaType) => {
    remoteUsers[user.uid] = user;
    await client.subscribe(user, mediaType);

    if (mediaType === 'video') {
        let player = document.getElementById(`user-container-${user.uid}`);
        if (player) {
            player.remove();
        }

        player = `<div class="video-container2" id="user-container-${user.uid}">
                    <div class="username-wrapper"><span class="user-name">User ${user.uid}</span></div>
                    <div class="video-player" id="user-${user.uid}"></div>
                  </div>`;
        document.getElementById('vid-streams').insertAdjacentHTML('beforeend', player);
        user.videoTrack.play(`user-${user.uid}`);
    }

    if (mediaType === 'audio') {
        user.audioTrack.play();
    }
};

let handleUserLeft = (user) => {
    delete remoteUsers[user.uid];
    const playerContainer = document.getElementById(`user-container-${user.uid}`);
    if (playerContainer) {
        playerContainer.remove();
    }
};

let leaveAndRemoveLocalStream = async () => {
    for (let i = 0; i < localTracks.length; i++) {
        localTracks[i].stop();
        localTracks[i].close();
    }
    if (screenTrack) {
        screenTrack.stop();
        screenTrack.close();
    }

    await client.leave();
    window.open('/', '_self');
};

let toggleCamera = async (e) => {
    if (localTracks[1].muted) {
        await localTracks[1].setMuted(false);
        e.target.style.backgroundColor = '#59ff83';
    } else {
        await localTracks[1].setMuted(true);
        e.target.style.backgroundColor = '#fff';
    }
};

let toggleMic = async (e) => {
    if (localTracks[0].muted) {
        await localTracks[0].setMuted(false);
        e.target.style.backgroundColor = '#59ff83';
    } else {
        await localTracks[0].setMuted(true);
        e.target.style.backgroundColor = '#fff';
    }
};

let toggleScreenShare = async (e) => {
    if (!isScreenSharingActive) {
        try {
            screenTrack = await AgoraRTC.createScreenVideoTrack();
            await client.unpublish(localTracks[1]); // Unpublish the camera video track
            await client.publish(screenTrack); // Publish the screen track

            screenTrack.play(`user-${UID}`);
            e.target.innerText = 'Stop Sharing';
            isScreenSharingActive = true;

            // Handle stopping screen share
            screenTrack.on('track-ended', async () => {
                await client.unpublish(screenTrack);
                await client.publish(localTracks[1]);
                localTracks[1].play(`user-${UID}`);
                e.target.innerText = 'Share Screen';
                isScreenSharingActive = false;
            });
        } catch (error) {
            console.error('Error starting screen share:', error);
        }
    } else {
        // Stop screen sharing and switch back to the camera
        await client.unpublish(screenTrack);
        await client.publish(localTracks[1]);
        localTracks[1].play(`user-${UID}`);
        screenTrack.stop();
        e.target.innerText = 'Share Screen';
        isScreenSharingActive = false;
    }
};

joinAndDisplayLocalStream();

document.getElementById('x-btn').addEventListener('click', leaveAndRemoveLocalStream);
document.getElementById('vid-btn').addEventListener('click', toggleCamera);
document.getElementById('mic-btn').addEventListener('click', toggleMic);
document.getElementById('screen-share-btn').addEventListener('click', toggleScreenShare);
