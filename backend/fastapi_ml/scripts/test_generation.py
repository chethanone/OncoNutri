import os
import json
import requests
from dotenv import load_dotenv

# Load environment variables
script_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(script_dir, '..', '..', 'datasets', 'cancer_data', '.env')
load_dotenv(dotenv_path=env_path)
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

print(f"API Key loaded: {GOOGLE_API_KEY[:10]}...")

GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GOOGLE_API_KEY}"

prompt = """Generate exactly 5 cancer-fighting breakfast foods for pure vegetarian diet (no meat, fish, eggs. Dairy OK).

Output ONLY valid JSON in this exact format:
[{"name":"Oatmeal with Berries","cuisine":"Western","calories":250,"protein":8.0,"carbs":45.0,"fiber":6.0,"preparation":"Rolled oats cooked with milk, topped with mixed berries","cancer_benefits_general":"High in fiber and antioxidants","cancer_specific_benefits":{"breast":"Fiber reduces estrogen levels","lung":"Antioxidants protect cells","colorectal":"Fiber promotes gut health","prostate":"Beta-glucan supports immunity","stomach":"Gentle and easy to digest"}}]

Generate 5 unique vegetarian breakfast foods:"""

data = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 2048
    }
}

print("\nSending request...")
try:
    response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, json=data, timeout=30)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        if 'candidates' in result:
            text = result['candidates'][0]['content']['parts'][0]['text']
            print(f"\nRaw response:\n{text}\n")
            
            # Clean and parse
            text = text.strip().replace('```json', '').replace('```', '')
            start_idx = text.find('[')
            end_idx = text.rfind(']')
            if start_idx != -1 and end_idx != -1:
                text = text[start_idx:end_idx + 1]
            
            try:
                foods = json.loads(text)
                print(f"✓ Successfully parsed {len(foods)} foods")
                print(json.dumps(foods, indent=2))
            except json.JSONDecodeError as e:
                print(f"✗ JSON error: {e}")
                print(f"Cleaned text: {text[:500]}...")
    else:
        print(f"Error: {response.text}")
except Exception as e:
    print(f"Exception: {e}")
