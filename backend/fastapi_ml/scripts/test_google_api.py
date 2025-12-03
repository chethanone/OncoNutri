import os
import requests
from dotenv import load_dotenv

# Load environment variables
# Script is in backend/fastapi_ml/scripts/
# .env is in backend/datasets/cancer_data/
# We need to go up 3 levels to backend/
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'datasets', 'cancer_data', '.env')
print(f"Loading .env from: {env_path}")
load_dotenv(dotenv_path=env_path)

GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    print("Error: GOOGLE_API_KEY not found in environment variables.")
    exit(1)

print(f"API Key found: {GOOGLE_API_KEY[:5]}...{GOOGLE_API_KEY[-5:]}")

def list_models():
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={GOOGLE_API_KEY}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print("\nAvailable Models:")
            for m in models:
                if 'generateContent' in m.get('supportedGenerationMethods', []):
                    print(f"- {m['name']}")
            return models
        else:
            print(f"\nError listing models: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"\nException listing models: {e}")
        return []

def test_generation(model_name):
    url = f"https://generativelanguage.googleapis.com/v1beta/{model_name}:generateContent?key={GOOGLE_API_KEY}"
    data = {
        "contents": [{"parts": [{"text": "Hello, are you working?"}]}]
    }
    headers = {'Content-Type': 'application/json'}
    
    print(f"\nTesting generation with {model_name}...")
    try:
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            print("Success! Response:")
            print(response.json()['candidates'][0]['content']['parts'][0]['text'])
            return True
        else:
            print(f"Failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"Exception testing generation: {e}")
        return False

if __name__ == "__main__":
    models = list_models()
    
    # Try to find a suitable model to test
    test_models = ['models/gemini-1.5-flash', 'models/gemini-pro', 'models/gemini-1.0-pro']
    
    worked = False
    for tm in test_models:
        if any(m['name'] == tm for m in models):
            if test_generation(tm):
                worked = True
                break
    
    if not worked and models:
        # If none of the preferred ones worked or were found, try the first available generateContent model
        for m in models:
            if 'generateContent' in m.get('supportedGenerationMethods', []):
                if test_generation(m['name']):
                    break
