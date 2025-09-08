#excecute py file in jupyter_venv
from pathlib import Path
import pandas as pd

# absolute path to the workbook [INSERT WORKBOOK PATH HERE]
wb = Path('/Users/douglas/Library/CloudStorage/OneDrive-UniversityCollegeCork/Master Plan/Personal Projects/Mallow - Liscarroll Landscaping/landscaping_schema.xlsx')

# check the file exists before proceeding
if not wb.exists():
    raise FileNotFoundError(wb)

# iterate through every sheet
for sheet in pd.ExcelFile(wb).sheet_names:
    df = pd.read_excel(wb, sheet_name=sheet, engine="openpyxl")
    csv_path = wb.parent / f"{sheet.lower()}.csv"
    df.to_csv(csv_path, index=False)
    print("Exported", csv_path)
