# OncoNutri+ Datasets

## 📁 Directory Structure

```
datasets/
├── cancer_data/          # Cancer patient and food database (excluded from git)
└── nutrition_data/       # USDA FoodData Central (excluded from git)
```

## ⚠️ Large Files Not Included in Repository

Due to GitHub file size limitations, the following large dataset files are excluded from this repository:

### Cancer Data (68+ MB)
- `cancer_data/cancer_patients.csv`
- `cancer_data/comprehensive_food_database.csv`

### USDA FoodData Central (2+ GB total)
- `nutrition_data/FoodData_Central_csv_2025-04-24/`
  - branded_food.csv (896 MB)
  - food_nutrient.csv (1.6 GB)
  - food.csv (205 MB)
  - food_attribute.csv (128 MB)
  - food_update_log_entry.csv (103 MB)
  - And other supporting files

## 📥 How to Obtain the Datasets

### Option 1: USDA FoodData Central (Official Source)
1. Visit [FoodData Central Download](https://fdc.nal.usda.gov/download-datasets.html)
2. Download "Full Download of All Data Types" (CSV format)
3. Extract to `backend/datasets/nutrition_data/FoodData_Central_csv_2025-04-24/`

### Option 2: Contact Project Maintainer
For the processed cancer patient and food databases, please contact the project maintainer.

## 🔄 Alternative: Use Curated Food Database

The ML service uses a curated food database (118 foods) stored in JSON format:
- `backend/fastapi_ml/data/curated_food_database.json` (included in repo)
- This is sufficient for basic functionality without the large CSV files

## 💾 Local Development

1. Create the directory structure:
   ```bash
   mkdir -p backend/datasets/cancer_data
   mkdir -p backend/datasets/nutrition_data
   ```

2. Download and place the datasets in their respective directories

3. The application will automatically load data from these locations

## 📝 Notes

- These files are excluded via `.gitignore` to keep the repository size manageable
- For production deployment, consider using cloud storage (S3, Google Cloud Storage)
- The curated JSON database is optimized for cancer patients and is sufficient for most use cases
