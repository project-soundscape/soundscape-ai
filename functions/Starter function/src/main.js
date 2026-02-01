import { Client, Databases, Storage, ID, Query } from 'node-appwrite';
import axios from 'axios';
import FormData from 'form-data';

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(req.headers['x-appwrite-key'] ?? process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const storage = new Storage(client);

  const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || "68da4b6900256869e751";
  const RECORDINGS_COLLECTION_ID = "recordings";
  const DETECTIONS_COLLECTION_ID = "detections";
  const USERS_COLLECTION_ID = "users";
  const BUCKET_ID = "68da4c5b000c0e3e788d";
  
  const HF_API_URL = "https://shabeer-wms-multi-sound-api.hf.space/classify/perch";

  let payload = {};
  try {
    if (req.body) {
        if (typeof req.body === 'object') {
            payload = req.body;
        } else if (typeof req.body === 'string') {
            try {
                payload = JSON.parse(req.body);
            } catch(e) {
                // If not JSON, maybe it's just a raw string?
            }
        }
    }

    // ACTION: Create User Document
    if (payload.action === 'create_user_doc') {
        const { userId, email } = payload;
        if (!userId) throw new Error("Missing userId");

        log(`Creating user doc for: ${userId}`);
        
        // Check if exists first to avoid 409
        try {
            await databases.getDocument(DATABASE_ID, USERS_COLLECTION_ID, userId);
            log("User doc already exists");
            return res.json({ success: true, message: "User doc exists" });
        } catch (e) {
            // If 404, create
            await databases.createDocument(
                DATABASE_ID,
                USERS_COLLECTION_ID,
                userId,
                {
                    email: email,
                    role: 'SCOUT'
                }
            );
            log("User doc created");
            return res.json({ success: true, message: "User doc created" });
        }
    }

    // Detect if this is an Event Trigger or HTTP Trigger
    const event = req.headers['x-appwrite-event'];
    log(`Triggered by event: ${event || 'HTTP'}`);

    // If event is 'databases.*.collections.recordings.documents.*.create'
    // or 'databases.*.collections.recordings.documents.*.update'
    // Appwrite sends the document in req.body
    
    let recordingDoc = payload;

    // IMPORTANT: If this is an update event, check if status changed to 'QUEUED' 
    // to avoid infinite loops when we update status to 'PROCESSING' or 'COMPLETED'
    if (event && event.includes('.update')) {
        if (recordingDoc.status !== 'QUEUED') {
            log('Document updated but status is not QUEUED. Skipping.');
            return res.json({ success: true, message: "Skipping non-queued update" });
        }
    }

    if (!recordingDoc || !recordingDoc.s3key) {
        // If we are here and it's not a user action, return neutral
        return res.json({ success: false, message: "No valid recording document or action found." });
    }

    const fileId = recordingDoc.s3key;
    const recordingId = recordingDoc.$id;

    log(`Processing Recording: ${recordingId}, File: ${fileId}`);

    // Update status to PROCESSING
    try {
        await databases.updateDocument(
            DATABASE_ID,
            RECORDINGS_COLLECTION_ID,
            recordingId,
            { status: 'PROCESSING' }
        );
    } catch (e) {
        log(`Warning: Could not update status to PROCESSING: ${e.message}`);
    }

    // 2. Download File
    const fileBuffer = await storage.getFileDownload(BUCKET_ID, fileId);
    
    // 3. Send to Hugging Face API
    const formData = new FormData();
    formData.append('audio_file', Buffer.from(fileBuffer), { filename: 'audio.aac', contentType: 'audio/aac' });

    log(`Sending to HF API: ${HF_API_URL}`);
    
    const hfResponse = await axios.post(HF_API_URL, formData, {
        headers: {
            ...formData.getHeaders(),
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 240000 // 4 minute axios timeout
    });

    const predictions = hfResponse.data.predictions;
    log(`HF Response: ${JSON.stringify(predictions)}`);

    if (!predictions || predictions.length === 0) {
        throw new Error("No predictions returned from AI");
    }

    // 4. Save Detections
    const scientificNames = predictions.map(p => p.class_name);
    const confidenceLevels = predictions.map(p => Math.round(p.score * 100));

    await databases.createDocument(
        DATABASE_ID,
        DETECTIONS_COLLECTION_ID,
        ID.unique(),
        {
            recordings: recordingId,
            scientificName: scientificNames,
            confidenceLevel: confidenceLevels,
            'timestamp-offset': 0
        }
    );

    // 5. Update Recording Status
    await databases.updateDocument(
        DATABASE_ID,
        RECORDINGS_COLLECTION_ID,
        recordingId,
        { status: 'COMPLETED' }
    );

    return res.json({
        success: true,
        message: "Analysis completed successfully",
        predictions: predictions
    });

  } catch (err) {
    error(`Error: ${err.message}`);
    if(err.response) error(`API Error Data: ${JSON.stringify(err.response.data)}`);
    
    // Try to update status to FAILED
    const recordingId = payload?.$id;
    if (recordingId) {
         try {
            await databases.updateDocument(
                DATABASE_ID,
                RECORDINGS_COLLECTION_ID,
                recordingId,
                { status: 'FAILED' }
            );
            log(`Updated status to FAILED for ${recordingId}`);
         } catch(e) {
            error(`Failed to update status to FAILED: ${e.message}`);
         }
    }

    return res.json({
        success: false,
        error: err.message
    }, 500);
  }
};