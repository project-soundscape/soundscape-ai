import { Client, Databases, Storage, ID, Query } from 'node-appwrite';
import axios from 'axios';
import FormData from 'form-data';

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(req.headers['x-appwrite-key'] ?? process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const storage = Storage(client);

  const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || "68da4b6900256869e751";
  const RECORDINGS_COLLECTION_ID = "recordings";
  const DETECTIONS_COLLECTION_ID = "detections";
  const USERS_COLLECTION_ID = "users";
  const BUCKET_ID = "68da4c5b000c0e3e788d";
  
  const HF_API_URL = "https://shabeer-wms-multi-sound-api.hf.space/classify/perch";

  try {
    let payload = {};
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

    // ACTION: Analyze Recording (Default/Event)
    // Event triggers send the document in body.
    // HTTP triggers might send { s3key: ... }
    
    let recordingDoc = payload;

    if (!recordingDoc || !recordingDoc.s3key) {
        // If we are here and it's not a user action, return neutral
        return res.json({ success: false, message: "No valid recording document or action found." });
    }

    const fileId = recordingDoc.s3key;
    const recordingId = recordingDoc.$id;

    log(`Processing Recording: ${recordingId}, File: ${fileId}`);

    // Update status to PROCESSING
    await databases.updateDocument(
        DATABASE_ID,
        RECORDINGS_COLLECTION_ID,
        recordingId,
        { status: 'PROCESSING' }
    );

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
    if (req.body && req.body.$id) {
         try {
            await databases.updateDocument(
                DATABASE_ID,
                RECORDINGS_COLLECTION_ID,
                req.body.$id,
                { status: 'FAILED' }
            );
         } catch(e) {}
    }

    return res.json({
        success: false,
        error: err.message
    }, 500);
  }
};