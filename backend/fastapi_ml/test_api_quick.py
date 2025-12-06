import os
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    print("❌ ERROR: GOOGLE_API_KEY not found in environment variables.")
    exit(1)

print(f"✅ API Key loaded: {GOOGLE_API_KEY[:10]}...{GOOGLE_API_KEY[-5:]}")

# Test 1: List available models
print("\n📋 Testing: List Available Models")
try:
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={GOOGLE_API_KEY}"
    response = requests.get(url, timeout=10)
    
    if response.status_code == 200:
        models = response.json().get('models', [])
        print(f"✅ SUCCESS! Found {len(models)} models:")
        for model in models[:3]:  # Show first 3
            print(f"   - {model.get('name', 'Unknown')}")
    else:
        print(f"❌ FAILED: Status {response.status_code}")
        print(f"Response: {response.text[:200]}")
except Exception as e:
    print(f"❌ ERROR: {e}")

# Test 2: Generate food recommendation
print("\n🍎 Testing: Generate Food Description")
try:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GOOGLE_API_KEY}"
    
    prompt = """Generate a brief cancer-friendly food recommendation for:
Food: Broccoli Soup
Cancer Type: Skin Cancer
Treatment Stage: Pre-treatment

Provide benefits in 1-2 sentences."""

    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 150
        }
    }
    
    response = requests.post(url, json=payload, timeout=30)
    
    if response.status_code == 200:
        result = response.json()
        text = result.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
        print(f"✅ SUCCESS! AI Response:")
        print(f"   {text.strip()}")
    else:
        print(f"❌ FAILED: Status {response.status_code}")
        print(f"Response: {response.text[:300]}")
except Exception as e:
    print(f"❌ ERROR: {e}")

print("\n✅ All tests completed!")
