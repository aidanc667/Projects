require("dotenv").config();
const express = require("express");
const cors = require("cors");
const fetch = require("node-fetch");

const app = express();
app.use(cors());
app.use(express.json());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY; // Load API key from .env

app.post("/ask-gemini", async (req, res) => {
    try {
        const { transcript, question } = req.body;

        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                prompt: `Based on this transcript, answer the following question:\n\n${transcript}\n\nQuestion: ${question}`
            })
        });

        const data = await response.json();
        res.json({ answer: data.candidates?.[0]?.output || "No response from AI." });

    } catch (error) {
        res.status(500).json({ error: "Error contacting Gemini AI" });
    }
});

app.listen(3000, () => console.log("Server running on port 3000"));
