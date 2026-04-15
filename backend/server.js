const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');
const admin = require('firebase-admin');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// 1. Initialize Firebase Admin (Firestore)
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin initialized');
} catch (error) {
  console.log('⚠️  Firebase Service Account not found or invalid. Firestore updates will be skipped.');
}

const db = admin.apps.length > 0 ? admin.firestore() : null;

// 2. Optional MongoDB Connection
if (process.env.MONGO_URI && process.env.MONGO_URI.startsWith('mongodb')) {
  mongoose.connect(process.env.MONGO_URI)
      .then(() => console.log('MongoDB connected'))
      .catch(err => console.error('MongoDB Connection Error:', err.message));
}

// 3. Gemini AI Setup
const ai = new GoogleGenAI({ 
  apiKey: process.env.GEMINI_API_KEY || "" 
});

// --- CHATBOT ENDPOINT (UNTOUCHED) ---
app.post('/chatAssistant', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: "Message is required" });
  try {
    const systemPrompt = "Instruction: You are an emergency assistant. Provide 2-3 short, calm safety sentences. Prioritize safety.";
    const fullMessage = `${systemPrompt}\n\nUser: ${message}`;
    const result = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: fullMessage,
    });
    res.json({ reply: result.text });
  } catch (error) {
    console.error("❌ Gemini Chat Error:", error.message);
    res.status(500).json({ error: "AI Unavailable" });
  }
});

// --- NEW INCIDENT ANALYSIS ENDPOINT ---
app.post('/analyzeIncident', async (req, res) => {
  const { incidentId, description, imageUrl, location } = req.body;

  if (!incidentId || !description) {
    return res.status(400).json({ error: "incidentId and description are required" });
  }

  try {
    console.log(`🔍 Analyzing incident: ${incidentId}`);
    let contents = [];

    // Prompt construction
    const systemPrompt = `
      Analyze this emergency incident report and image. 
      Return ONLY a STRICT JSON object.
      Required Fields:
      - type: "fire", "medical", "crime", or "other"
      - severity: "low", "medium", or "high"
      - confidence: Integer (0-100)
      - reasoning: Short 1-sentence explanation
      - priority: "low", "medium", or "high"

      Description: ${description}
      Location: ${location || 'Unknown'}
    `;

    // Multimodal input preparation
    if (imageUrl && imageUrl.startsWith('http')) {
      try {
        const imageResponse = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        const base64Image = Buffer.from(imageResponse.data).toString('base64');
        contents.push({
          role: 'user',
          parts: [
            { text: systemPrompt },
            { 
              inlineData: { 
                data: base64Image, 
                mimeType: "image/jpeg" // Cloudinary images are typically jpegs/pngs
              } 
            }
          ]
        });
      } catch (imgError) {
        console.warn("⚠️ Failed to download image, proceeding with text only", imgError.message);
        contents.push({ role: 'user', parts: [{ text: systemPrompt }] });
      }
    } else {
      contents.push({ role: 'user', parts: [{ text: systemPrompt }] });
    }

    // Call Gemini
    const result = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: contents,
    });

    // Parse JSON from response (remove markdown if present)
    const jsonStr = result.text.replace(/```json|```/g, '').trim();
    const analysis = JSON.parse(jsonStr);

    // Update Firestore if available
    if (db) {
      const startTime = Date.now();
      await db.collection('incidents').doc(incidentId).update({
        type: analysis.type,
        severity: analysis.severity,
        aiConfidence: analysis.confidence,
        aiReasoning: analysis.reasoning,
        aiPriority: analysis.priority,
        aiAnalysisTime: `${((Date.now() - startTime) / 1000).toFixed(1)}s`
      });
      console.log(`✅ Firestore updated for incident: ${incidentId}`);
    }

    res.json(analysis);

  } catch (error) {
    console.error("❌ Incident Analysis Error:", error.message);
    res.status(500).json({ 
      error: "Analysis failed", 
      details: error.message 
    });
  }
});

// --- AUTOMATIC TRIGGER: FIRESTORE LISTENER ---
if (db) {
  console.log("📡 Starting Firestore auto-analysis listener...");
  db.collection('incidents').onSnapshot(snapshot => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === 'added') {
        const data = change.doc.data();
        const incidentId = change.doc.id;

        // Only auto-analyze if it hasn't been analyzed yet and it's a new report
        if (!data.aiReasoning && data.status === 'Open') {
          console.log(`🤖 Auto-triggering analysis for new incident: ${incidentId}`);
          try {
            await triggerAnalysis(incidentId, data);
          } catch (err) {
            console.error(`❌ Auto-analysis failed for ${incidentId}:`, err.message);
          }
        }
      }
    });
  });
}

async function triggerAnalysis(incidentId, data) {
  const { description, imageUrl, location } = data;
  let contents = [];

  const systemPrompt = `
    Analyze this emergency incident report and image. Return ONLY a STRICT JSON object.
    Fields: type (fire/medical/crime/other), severity (low/medium/high), confidence (0-100), reasoning (1 sentence), priority (low/medium/high).
    Description: ${description}
    Location: ${location || 'Unknown'}
  `;

  if (imageUrl && imageUrl.startsWith('http')) {
    try {
      const imageResponse = await axios.get(imageUrl, { responseType: 'arraybuffer' });
      const base64Image = Buffer.from(imageResponse.data).toString('base64');
      contents.push({
        role: 'user',
        parts: [{ text: systemPrompt }, { inlineData: { data: base64Image, mimeType: "image/jpeg" } }]
      });
    } catch (e) {
      contents.push({ role: 'user', parts: [{ text: systemPrompt }] });
    }
  } else {
    contents.push({ role: 'user', parts: [{ text: systemPrompt }] });
  }

  const result = await ai.models.generateContent({ model: "gemini-3-flash-preview", contents });
  const jsonStr = result.text.replace(/```json|```/g, '').trim();
  const analysis = JSON.parse(jsonStr);

  const startTime = Date.now();
  await db.collection('incidents').doc(incidentId).update({
    type: analysis.type,
    severity: analysis.severity,
    aiConfidence: analysis.confidence,
    aiReasoning: analysis.reasoning,
    aiPriority: analysis.priority,
    aiAnalysisTime: `${((Date.now() - startTime) / 1000).toFixed(1)}s`
  });
}

const PORT = 5005;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
