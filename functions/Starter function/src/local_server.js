// local_server.js
import express from 'express';
import dotenv from 'dotenv';
import appwriteFunction from './main.js'; // Import your function

// Load environment variables from .env file
dotenv.config();

const app = express();
const port = 3000;

// A middleware to handle all incoming requests
app.use(async (req, res) => {
    // Create a context object that mocks the Appwrite environment
    const context = {
        req,
        res: { // Mock Appwrite's res object using Express's res
            send: (body, statusCode = 200) => res.status(statusCode).send(body),
            json: (obj, statusCode = 200) => res.status(statusCode).json(obj),
            text: (text, statusCode = 200) => res.status(statusCode).send(text),
            binary: (data, statusCode = 200) => res.status(statusCode).send(data),
            empty: (statusCode = 204) => res.status(statusCode).send(),
            redirect: (url, statusCode = 301) => res.redirect(statusCode, url),
        },
        log: (message) => console.log(message),
        error: (message) => console.error(message),
    };

    // Since you are running locally, you might need to manually
    // set the header Appwrite uses for the key if your function depends on it.
    // However, the best practice is to use process.env.APPWRITE_API_KEY directly.
    // req.headers['x-appwrite-key'] = process.env.APPWRITE_API_KEY;

    try {
        await appwriteFunction(context);
    } catch (e) {
        context.error(e.message);
        context.res.json({ error: 'Function execution failed.' }, 500);
    }
});

app.listen(port, () => {
    console.log(`🚀 Server listening at http://localhost:${port}`);
});