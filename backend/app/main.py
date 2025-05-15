# backend/app/main.py
from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
import firebase_admin
from firebase_admin import credentials, firestore, auth

# Load environment variables
load_dotenv()

# Initialize the FastAPI app
app = FastAPI(title="SkyView AI Backend")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase (if Firebase service account credentials are available)
try:
    # Check if running in production or development
    if os.getenv("FIREBASE_PROJECT_ID"):
        # Use environment variables for Firebase credentials
        firebase_config = {
            "type": "service_account",
            "project_id": os.getenv("FIREBASE_PROJECT_ID"),
            # Add other required Firebase credential fields
        }
        
        # Initialize Firebase
        cred = credentials.Certificate(firebase_config)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase initialized successfully")
    else:
        print("Firebase configuration not found, running without Firebase")
except Exception as e:
    print(f"Failed to initialize Firebase: {e}")
    # Continue without Firebase

# Initialize Gemini API
try:
    genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
    model = genai.GenerativeModel('gemini-pro')
    print("Gemini API initialized successfully")
except Exception as e:
    print(f"Failed to initialize Gemini API: {e}")
    model = None

# Define data models
class ChatMessage(BaseModel):
    content: str
    role: str = "user"  # "user" or "ai"

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    user_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    status: str = "success"

# Add startup event to ensure configuration
@app.on_event("startup")
async def startup_event():
    if not os.getenv("GOOGLE_API_KEY"):
        print("WARNING: GOOGLE_API_KEY not set. AI functionality will be limited.")

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "gemini_available": model is not None}

# Chat endpoint
@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    if not model:
        # Fallback responses if Gemini is not available
        fallback_responses = {
            "flight": "I can help you find flights. Please provide your departure city, destination, and dates.",
            "book": "To book a flight, I'll need information about your travel dates, destination, and preferences.",
            "cancel": "If you need to cancel a booking, please go to the My Bookings section in your profile.",
            "baggage": "Baggage allowance depends on the airline and fare class. Economy generally allows 15-20kg.",
            "default": "I'm your travel assistant. I can help you book flights, answer questions about travel, and provide recommendations."
        }
        
        # Determine which fallback to use based on the last user message
        last_message = request.messages[-1].content.lower() if request.messages else ""
        
        if "flight" in last_message:
            response = fallback_responses["flight"]
        elif "book" in last_message:
            response = fallback_responses["book"]
        elif "cancel" in last_message:
            response = fallback_responses["cancel"]
        elif "baggage" in last_message or "luggage" in last_message:
            response = fallback_responses["baggage"]
        else:
            response = fallback_responses["default"]
            
        return ChatResponse(response=response)
    
    try:
        # Format the conversation for Gemini
        formatted_messages = []
        for msg in request.messages:
            role = "user" if msg.role == "user" else "model"
            formatted_messages.append({"role": role, "parts": [msg.content]})
        
        # Add system prompt to guide the AI's behavior
        system_prompt = """You are SkyView's AI travel assistant. 
        Your goal is to help users with flight bookings, travel recommendations, and answer questions.
        Be concise, friendly, and provide accurate travel information.
        If asked about booking flights, guide users to search on the app.
        Keep responses under 150 words and focus on being helpful."""
        
        # Create a chat session with the system prompt
        chat = model.start_chat(history=[
            {"role": "user", "parts": ["What's your role?"]},
            {"role": "model", "parts": [system_prompt]}
        ])
        
        # Send the conversation to Gemini
        response = chat.send_message(formatted_messages)
        
        # Store the conversation in Firebase if user_id is provided
        if request.user_id and 'db' in globals():
            try:
                # Create a conversation record
                conversation_ref = db.collection('conversations').document()
                conversation_ref.set({
                    'user_id': request.user_id,
                    'timestamp': firestore.SERVER_TIMESTAMP,
                    'query': request.messages[-1].content,
                    'response': response.text,
                })
            except Exception as e:
                print(f"Error storing conversation: {e}")
        
        return ChatResponse(response=response.text)
    
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process chat: {str(e)}"
        )

# Flight search suggestions endpoint (mock data for now)
@app.get("/flight-suggestions")
async def get_flight_suggestions(query: str = ""):
    # This would be replaced with actual flight search API integration
    suggestions = [
        {"city": "Mumbai", "code": "BOM", "airport": "Chhatrapati Shivaji Maharaj International Airport"},
        {"city": "Delhi", "code": "DEL", "airport": "Indira Gandhi International Airport"},
        {"city": "Bangalore", "code": "BLR", "airport": "Kempegowda International Airport"},
        {"city": "Chennai", "code": "MAA", "airport": "Chennai International Airport"},
        {"city": "Kolkata", "code": "CCU", "airport": "Netaji Subhas Chandra Bose International Airport"},
    ]
    
    if query:
        query = query.lower()
        suggestions = [s for s in suggestions if query in s["city"].lower() or query in s["code"].lower()]
    
    return {"suggestions": suggestions}

# Run the app with: uvicorn app.main:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)