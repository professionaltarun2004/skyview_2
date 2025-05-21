# backend/app/main.py
from fastapi import FastAPI, HTTPException, Depends, status, Request, Query, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.security import APIKeyHeader
from pydantic import BaseModel
from pydantic_settings import BaseSettings
from typing import Optional, List, Dict
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
import firebase_admin
from firebase_admin import credentials, firestore, auth
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Load environment variables
load_dotenv()

# Environment variables validation
class Settings(BaseSettings):
    GOOGLE_API_KEY: str = "dummy-key"  # Default value for development
    FIREBASE_PROJECT_ID: str = "joystick-dc535"  # Default value for development
    ALLOWED_HOSTS: List[str] = ["*"]
    API_KEY: str = "dev-key"  # Default value for development
    RATE_LIMIT_PER_MINUTE: int = 60

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'

settings = Settings()

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

# Initialize the FastAPI app
app = FastAPI(title="SkyView AI Backend")

# Add rate limiting exception handler
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add security middleware
app.add_middleware(
    TrustedHostMiddleware, 
    allowed_hosts=settings.ALLOWED_HOSTS
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*", "X-API-Key", "Content-Type", "Authorization"],
    expose_headers=["*"],
    max_age=3600,
)

# API Key security
api_key_header = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: str = Depends(api_key_header)):
    if settings.API_KEY != "dev-key" and api_key != settings.API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    return api_key

# Initialize Firebase using the service account JSON file
try:
    # Path to the Firebase service account credentials file
    service_account_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
        "joystick-dc535-firebase-adminsdk-fbsvc-998b2aad07.json"
    )
    
    # Check if the service account file exists
    if os.path.exists(service_account_path):
        # Initialize Firebase with the service account file
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase initialized successfully")
    else:
        print(f"Firebase service account file not found at: {service_account_path}")
        print("Running without Firebase")
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

class RecommendationResponse(BaseModel):
    recommendations: list
    status: str = "success"

class FlightModel(BaseModel):
    id: str
    airlineName: str
    flightNumber: str
    departureCity: str
    arrivalCity: str
    departureAirport: str
    arrivalAirport: str
    departureTime: str
    arrivalTime: str
    price: float
    availableSeats: int
    travelClasses: list
    amenities: list
    status: str
    gate: str = None
    terminal: str = None
    lastUpdated: str = None
    logo: str = None
    isNonStop: bool = True

class BookingModel(BaseModel):
    id: str = None
    user_id: str
    flight_id: str
    passengers: int
    travelClass: str
    totalPrice: float
    bookingTime: str = None
    status: str = "confirmed"

class FlightSearchParams(BaseModel):
    departure_city: Optional[str] = None
    arrival_city: Optional[str] = None
    departure_date: Optional[str] = None
    return_date: Optional[str] = None
    passengers: Optional[int] = 1
    travel_class: Optional[str] = None
    max_price: Optional[float] = None
    page: int = 1
    limit: int = 20

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

@app.get("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(user_id: Optional[str] = Query(None)):
    # Try to fetch from Firestore if available
    try:
        if 'db' in globals():
            # Example: get top 5 popular destinations
            locations_ref = db.collection('locations').where('isPopular', '==', True).order_by('popularity', direction=firestore.Query.DESCENDING).limit(5)
            docs = locations_ref.stream()
            recommendations = []
            for doc in docs:
                data = doc.to_dict()
                recommendations.append({
                    "city": data.get("city"),
                    "country": data.get("country"),
                    "code": data.get("code"),
                    "airportName": data.get("airportName"),
                    "imageUrl": data.get("imageUrl"),
                })
            return RecommendationResponse(recommendations=recommendations)
    except Exception as e:
        print(f"Error fetching recommendations from Firestore: {e}")
    # Fallback: mock data
    recommendations = [
        {"city": "London", "country": "UK", "code": "LHR", "airportName": "Heathrow Airport", "imageUrl": None},
        {"city": "Paris", "country": "France", "code": "CDG", "airportName": "Charles de Gaulle Airport", "imageUrl": None},
        {"city": "New York", "country": "USA", "code": "JFK", "airportName": "John F. Kennedy International Airport", "imageUrl": None},
        {"city": "Dubai", "country": "UAE", "code": "DXB", "airportName": "Dubai International Airport", "imageUrl": None},
        {"city": "Singapore", "country": "Singapore", "code": "SIN", "airportName": "Changi Airport", "imageUrl": None},
    ]
    return RecommendationResponse(recommendations=recommendations)

@app.get("/flights", response_model=List[FlightModel])
async def list_flights():
    try:
        if 'db' in globals():
            flights_ref = db.collection('flights').limit(20)
            docs = flights_ref.stream()
            flights = [FlightModel(**doc.to_dict()) for doc in docs]
            return flights
    except Exception as e:
        print(f"Error fetching flights: {e}")
    # Fallback mock data
    return [
        FlightModel(
            id="1", airlineName="Air India", flightNumber="AI101", departureCity="Delhi", arrivalCity="London", departureAirport="DEL", arrivalAirport="LHR", departureTime="2024-06-01T10:00:00Z", arrivalTime="2024-06-01T14:00:00Z", price=50000, availableSeats=5, travelClasses=["Economy", "Business"], amenities=["meal", "wifi"], status="Scheduled", gate="A1", terminal="T3", lastUpdated=None, logo=None, isNonStop=True
        ),
        FlightModel(
            id="2", airlineName="Emirates", flightNumber="EK202", departureCity="Dubai", arrivalCity="New York", departureAirport="DXB", arrivalAirport="JFK", departureTime="2024-06-02T08:00:00Z", arrivalTime="2024-06-02T16:00:00Z", price=70000, availableSeats=3, travelClasses=["Economy", "Business", "First"], amenities=["meal", "entertainment"], status="Scheduled", gate="B2", terminal="T1", lastUpdated=None, logo=None, isNonStop=True
        ),
    ]

@app.get("/flights/{flight_id}", response_model=FlightModel)
async def get_flight(flight_id: str):
    try:
        if 'db' in globals():
            doc = db.collection('flights').document(flight_id).get()
            if doc.exists:
                return FlightModel(**doc.to_dict())
    except Exception as e:
        print(f"Error fetching flight: {e}")
    # Fallback mock data
    if flight_id == "1":
        return FlightModel(
            id="1", airlineName="Air India", flightNumber="AI101", departureCity="Delhi", arrivalCity="London", departureAirport="DEL", arrivalAirport="LHR", departureTime="2024-06-01T10:00:00Z", arrivalTime="2024-06-01T14:00:00Z", price=50000, availableSeats=5, travelClasses=["Economy", "Business"], amenities=["meal", "wifi"], status="Scheduled", gate="A1", terminal="T3", lastUpdated=None, logo=None, isNonStop=True
        )
    elif flight_id == "2":
        return FlightModel(
            id="2", airlineName="Emirates", flightNumber="EK202", departureCity="Dubai", arrivalCity="New York", departureAirport="DXB", arrivalAirport="JFK", departureTime="2024-06-02T08:00:00Z", arrivalTime="2024-06-02T16:00:00Z", price=70000, availableSeats=3, travelClasses=["Economy", "Business", "First"], amenities=["meal", "entertainment"], status="Scheduled", gate="B2", terminal="T1", lastUpdated=None, logo=None, isNonStop=True
        )
    raise HTTPException(status_code=404, detail="Flight not found")

@app.post("/bookings", response_model=BookingModel)
async def create_booking(booking: BookingModel = Body(...)):
    try:
        if 'db' in globals():
            booking_id = db.collection('bookings').document().id
            booking.id = booking_id
            booking.bookingTime = firestore.SERVER_TIMESTAMP
            db.collection('bookings').document(booking_id).set(booking.dict())
            return booking
    except Exception as e:
        print(f"Error creating booking: {e}")
    # Fallback mock response
    booking.id = "mock123"
    booking.bookingTime = "2024-06-01T12:00:00Z"
    return booking

@app.get("/bookings/{user_id}", response_model=List[BookingModel])
async def get_user_bookings(user_id: str):
    try:
        if 'db' in globals():
            bookings_ref = db.collection('bookings').where('user_id', '==', user_id)
            docs = bookings_ref.stream()
            bookings = [BookingModel(**doc.to_dict()) for doc in docs]
            return bookings
    except Exception as e:
        print(f"Error fetching bookings: {e}")
    # Fallback mock data
    return []

@app.get("/flights/search", response_model=List[FlightModel])
@limiter.limit("60/minute")
async def search_flights(
    request: Request,
    params: FlightSearchParams = Depends(),
    api_key: str = Depends(verify_api_key)
):
    try:
        # For now, return mock data since we don't have a real database
        mock_flights = [
            FlightModel(
                id="1",
                airlineName="Air India",
                flightNumber="AI101",
                departureCity="Delhi",
                arrivalCity="London",
                departureAirport="DEL",
                arrivalAirport="LHR",
                departureTime="2024-06-01T10:00:00Z",
                arrivalTime="2024-06-01T14:00:00Z",
                price=50000,
                availableSeats=5,
                travelClasses=["Economy", "Business"],
                amenities=["meal", "wifi"],
                status="Scheduled",
                gate="A1",
                terminal="T3",
                lastUpdated=None,
                logo=None,
                isNonStop=True
            ),
            FlightModel(
                id="2",
                airlineName="Emirates",
                flightNumber="EK202",
                departureCity="Dubai",
                arrivalCity="New York",
                departureAirport="DXB",
                arrivalAirport="JFK",
                departureTime="2024-06-02T08:00:00Z",
                arrivalTime="2024-06-02T16:00:00Z",
                price=70000,
                availableSeats=3,
                travelClasses=["Economy", "Business", "First"],
                amenities=["meal", "entertainment"],
                status="Scheduled",
                gate="B2",
                terminal="T1",
                lastUpdated=None,
                logo=None,
                isNonStop=True
            ),
            FlightModel(
                id="3",
                airlineName="British Airways",
                flightNumber="BA123",
                departureCity="London",
                arrivalCity="Paris",
                departureAirport="LHR",
                arrivalAirport="CDG",
                departureTime="2024-06-03T09:00:00Z",
                arrivalTime="2024-06-03T11:00:00Z",
                price=45000,
                availableSeats=8,
                travelClasses=["Economy", "Business"],
                amenities=["meal", "wifi", "entertainment"],
                status="Scheduled",
                gate="C3",
                terminal="T2",
                lastUpdated=None,
                logo=None,
                isNonStop=True
            )
        ]

        # Apply filters to mock data
        filtered_flights = mock_flights

        if params.departure_city:
            filtered_flights = [f for f in filtered_flights if f.departureCity.lower() == params.departure_city.lower()]
        if params.arrival_city:
            filtered_flights = [f for f in filtered_flights if f.arrivalCity.lower() == params.arrival_city.lower()]
        if params.travel_class:
            filtered_flights = [f for f in filtered_flights if params.travel_class in f.travelClasses]
        if params.max_price:
            filtered_flights = [f for f in filtered_flights if f.price <= params.max_price]
        if params.passengers:
            filtered_flights = [f for f in filtered_flights if f.availableSeats >= params.passengers]

        # Apply pagination
        start_idx = (params.page - 1) * params.limit
        end_idx = start_idx + params.limit
        paginated_flights = filtered_flights[start_idx:end_idx]

        return paginated_flights

    except Exception as e:
        print(f"Error searching flights: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to search flights: {str(e)}"
        )

# Run the app with: uvicorn app.main:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)