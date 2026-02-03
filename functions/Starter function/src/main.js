import { Client, Databases, Storage, ID, Query } from 'node-appwrite';
import axios from 'axios';
import FormData from 'form-data';

export default async ({ req, res, log, error }) => {
  const startTime = Date.now();
  
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
  
  // Updated to use combined endpoint for better accuracy
  const API_URL = process.env.HF_API_URL || "https://shabeer-wms-multi-sound-api.hf.space/classify/combined";

  let payload = {};
  try {
    if (req.body) {
        if (typeof req.body === 'object') {
            payload = req.body;
        } else if (typeof req.body === 'string') {
            try {
                payload = JSON.parse(req.body);
            } catch(e) {
                // Not JSON
            }
        }
    }

    // ACTION: Create User Document
    if (payload.action === 'create_user_doc') {
        const { userId, email } = payload;
        if (!userId) throw new Error("Missing userId");

        log(`Creating user doc for: ${userId}`);
        
        try {
            await databases.getDocument(DATABASE_ID, USERS_COLLECTION_ID, userId);
            log("User doc already exists");
            return res.json({ success: true, message: "User doc exists" });
        } catch (e) {
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

    // Detect if this is an Event Trigger
    const event = req.headers['x-appwrite-event'];
    log(`Triggered by event: ${event || 'HTTP'}`);
    
    let recordingDoc = payload;

    // Check status to avoid infinite loops
    if (event && event.includes('.update')) {
        if (recordingDoc.status !== 'QUEUED') {
            log('Document updated but status is not QUEUED. Skipping.');
            return res.json({ success: true, message: "Skipping non-queued update" });
        }
    }

    if (!recordingDoc || !recordingDoc.s3key) {
        return res.json({ success: false, message: "No valid recording document or action found." });
    }

    const fileId = recordingDoc.s3key;
    const recordingId = recordingDoc.$id;

    log(`Processing Recording: ${recordingId}, File: ${fileId}`);

    // Update status to PROCESSING (non-blocking)
    databases.updateDocument(
        DATABASE_ID,
        RECORDINGS_COLLECTION_ID,
        recordingId,
        { status: 'PROCESSING' }
    ).catch(e => log(`Warning: Could not update to PROCESSING: ${e.message}`));

    // Download File with streaming for memory efficiency
    log('Downloading audio file...');
    const fileBuffer = await storage.getFileDownload(BUCKET_ID, fileId);
    
    // Send to API with optimized settings
    const formData = new FormData();
    formData.append('audio_file', Buffer.from(fileBuffer), { 
        filename: 'audio.m4a', 
        contentType: 'audio/aac' 
    });

    log(`Sending to API: ${API_URL}`);
    
    const apiResponse = await axios.post(API_URL, formData, {
        headers: formData.getHeaders(),
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 180000, // 3 minutes timeout
        validateStatus: (status) => status < 500 // Don't throw on 4xx
    });

    if (apiResponse.status !== 200) {
        throw new Error(`API returned ${apiResponse.status}: ${JSON.stringify(apiResponse.data)}`);
    }

    const { predictions, bird_detected, confidence_method, processing_time, audio_duration } = apiResponse.data;
    log(`API Response - Bird detected: ${bird_detected}, Method: ${confidence_method}, Time: ${processing_time}s`);

    if (!predictions || predictions.length === 0) {
        throw new Error("No predictions returned from AI");
    }

    // Filter out low confidence or "No bird detected" results
    const validPredictions = predictions.filter(p => 
        p.class_name !== "No bird detected" && p.score > 0.1
    );

    if (validPredictions.length === 0) {
        log('No valid bird detections found');
        await databases.updateDocument(
            DATABASE_ID,
            RECORDINGS_COLLECTION_ID,
            recordingId,
            { 
                status: 'COMPLETED',
                // Add a note field if it exists in your schema
            }
        );
        
        return res.json({
            success: true,
            message: "Analysis completed - No birds detected",
            bird_detected: false
        });
    }

    // Save Detections (optimized format)
    const scientificNames = validPredictions.map(p => p.class_name);
    const confidenceLevels = validPredictions.map(p => Math.round(p.score * 100));

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

    // Update Recording Status
    await databases.updateDocument(
        DATABASE_ID,
        RECORDINGS_COLLECTION_ID,
        recordingId,
        { status: 'COMPLETED' }
    );

    const totalTime = (Date.now() - startTime) / 1000;
    log(`Total processing time: ${totalTime}s (API: ${processing_time}s)`);

    return res.json({
        success: true,
        message: "Analysis completed successfully",
        predictions: validPredictions,
        bird_detected,
        confidence_method,
        processing_time: totalTime
    });

  } catch (err) {
    error(`Error: ${err.message}`);
    if(err.response) error(`API Error Data: ${JSON.stringify(err.response.data)}`);
    
    // Update status to FAILED
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