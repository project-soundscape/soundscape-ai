# Raspberry Pi Integration for SoundScape

This guide outlines how to turn a Raspberry Pi into a dedicated, real-time acoustic and visual monitoring station that automatically pushes discoveries to the SoundScape map.

## 🛠 Hardware Requirements
*   **Raspberry Pi:** 3B+, 4, or 5.
*   **Microphone:** USB Microphone or an I2S Microphone HAT (e.g., Adafruit SPH0645).
*   **Camera:** Raspberry Pi Camera Module (V2 or V3) or any standard USB Webcam.
*   **Internet:** WiFi or Ethernet.
*   **Storage:** 16GB+ microSD card.

## 🚀 Setup Instructions

### 1. OS Preparation
Install **Raspberry Pi OS (Lite)** using the Raspberry Pi Imager. Ensure SSH, Camera, and WiFi are configured in the advanced options.

### 2. Install Dependencies
Connect to your Pi and run:
```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-numpy libportaudio2 libatlas-base-dev libopencv-dev
pip3 install appwrite tflite-runtime sounddevice scipy opencv-python
```

### 3. Deploy the Monitoring Script
Create a file named `monitor.py` on your Pi. This script will perform dual-stream analysis:
1.  **Acoustic Loop:** Captures audio and identifies species via BirdNET.
2.  **Visual Loop:** Triggers the camera when sound is detected to capture confirming evidence.
3.  **Upload:** Pushes both data points to the SoundScape Appwrite backend.

#### Example `monitor.py` (Snippet)
```python
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.services.storage import Storage
from appwrite.input_file import InputFile
import sounddevice as sd
import cv2
import os

# Configuration
PROJECT_ID = "soundscape"
DATABASE_ID = "68da4b6900256869e751"
COLLECTION_ID = "recordings"
BUCKET_ID = "68da4c5b000c0e3e788d"
STATION_LAT = 12.345 
STATION_LON = 67.890 

client = Client()
client.set_endpoint('https://fra.cloud.appwrite.io/v1')
client.set_project(PROJECT_ID)
client.set_key('YOUR_APPWRITE_API_KEY')

databases = Databases(client)
storage = Storage(client)
camera = cv2.VideoCapture(0)

def capture_image():
    ret, frame = camera.read()
    if ret:
        cv2.imwrite('detection.jpg', frame)
        return 'detection.jpg'
    return None

def on_detection(label, confidence):
    # 1. Capture visual evidence
    img_path = capture_image()
    image_id = None
    
    if img_path:
        result = storage.create_file(BUCKET_ID, 'unique()', InputFile.from_path(img_path))
        image_id = result['$id']

    # 2. Log to database
    databases.create_document(
        database_id=DATABASE_ID,
        collection_id=COLLECTION_ID,
        document_id='unique()',
        data={
            'commonName': label,
            'confidence': confidence,
            'latitude': STATION_LAT,
            'longitude': STATION_LON,
            'status': 'processed',
            's3key': image_id # Link the captured image
        }
    )

print("SoundScape Multi-Sensor Station Active...")
```

## 📹 Real-time Streaming (Live Feed)

To stream live video and audio from your Pi to the SoundScape app, we recommend using **MediaMTX** (formerly rtsp-simple-server) and **FFmpeg**.

### 1. Install MediaMTX
Download the latest release for ARM from [MediaMTX Releases](https://github.com/bluenviron/mediamtx/releases) and run it on your Pi. It will act as the streaming server.

### 2. Start the Stream
Run the following FFmpeg command to capture the camera and microphone and push it to MediaMTX:

```bash
ffmpeg -f alsa -i default -f v4l2 -i /dev/video0 \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -c:a aac -f rtsp rtsp://localhost:8554/live
```

### 3. Update Appwrite Document
When your Pi registers itself (or during discovery), ensure the `streamUrl` field is set:
```python
# In your monitor.py
'data': {
    'commonName': label,
    'streamUrl': 'rtsp://YOUR_PI_IP:8554/live', # Your public or local IP
    ...
}
```

## 🛰 Real-time Data Flow
1.  **Acoustic detection** identifying a species.
2.  **Live Feed** becomes available in the app via the `streamUrl`.
3.  **Users** can tap "GO LIVE" on the map marker to see and hear the environment in real-time.

## 🔧 Automation
To make the script run on boot:
1.  `sudo nano /etc/systemd/system/soundscape.service`
2.  Add configuration to run `python3 /home/pi/monitor.py`.
3.  `sudo systemctl enable soundscape && sudo systemctl start soundscape`.

