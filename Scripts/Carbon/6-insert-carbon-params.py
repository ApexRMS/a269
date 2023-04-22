## a269
## Katie Birchard (ApexRMS)
## April 2023

## Workspace ----
# Set up environment
import os
import sys

# Load paths to retrieve helper functions and constants
cwd = os.getcwd()
root_dir = cwd.split(r"a275")[0] + "a275"

# Set working directory
os.chdir(os.path.join(root_dir, "Scripts/CONUS/Carbon Preprocessing/Forest/Spinup + Flows"))

# Add Scripts directory to path
sys.path.append(os.path.join(root_dir, "Scripts"))

# Import helper functions
from helper_functions import *

# Import constants/global variables 
from constants import *

# import modules
import pysyncrosim as ps
import pandas as pd

### Load Library ----
my_session = ps.Session()
my_session.add_packages("stsim")
my_session.add_packages("stsimsf")

my_library = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_CARBON_LULC_FILE_NAME))

my_project = my_library.projects(name = "Definitions")

### Modify Definitions ----
# Add Attribute Group
my_datasheet = my_project.datasheets(name = "stsim_AttributeGroup")
my_datasheet["Name"] = ["Carbon Initial Conditions", "NPP"]
my_project.save_datasheet(name = "stsim_AttributeGroup", data = my_datasheet)

# Add Stock Groups
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsimsf_StockGroup.csv"))
my_project.save_datasheet(name = "stsimsf_StockGroup", data = my_datasheet)

# Add Flow Groups
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsimsf_FlowGroup.csv"))
my_project.save_datasheet(name = "stsimsf_FlowGroup", data = my_datasheet)

# Append to State Attribute Types
my_datasheet = my_project.datasheets(name = "stsim_StateAttributeType")
new_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsim_StateAttributeType.csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_project.save_datasheet(name = "stsim_StateAttributeType", data = my_datasheet)

# Append to Stock Types
my_datasheet = my_project.datasheets(name = "stsimsf_StockType")
new_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsimsf_StockType.csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_project.save_datasheet(name = "stsimsf_StockType", data = my_datasheet)

# Append to Flow Types
my_datasheet = my_project.datasheets(name = "stsimsf_FlowType")
new_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsimsf_FlowType.csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_project.save_datasheet(name = "stsimsf_FlowType", data = my_datasheet)

### Modifiy Scenarios ---- should create new scenarios and merge / or just append?
## From CBM
# Append to Flow Pathways
scenario_name = "Flow Pathways"
my_scenario = my_project.scenarios(name = scenario_name)

datasheet_name = "stsimsf_FlowPathwayDiagram"
my_datasheet = my_scenario.datasheets(name = datasheet_name)
new_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
new_values.replace("A1", "F1", inplace=True)
new_values.replace("B1", "F2", inplace=True)
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

datasheet_name = "stsimsf_FlowPathway"
my_datasheet = my_scenario.datasheets(name = datasheet_name)
new_values = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, datasheet_name, 
                                      datasheet_name + "_fire_cbm_output.csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_datasheet.replace(CBM_FOREST_FIRE_TRANSITION + " [Type]", FOREST_FIRE_TRANSITION + " [Type]", inplace=True)
my_datasheet.replace(CBM_FOREST_CLEARCUT_TRANSITION + " [Type]", FOREST_CLEARCUT_TRANSITION + " [Type]", inplace=True)
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Append to Flow Multipliers
scenario_name = "Flow Multipliers"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_FlowMultiplier"
my_datasheet = my_scenario.datasheets(name = datasheet_name)
new_values = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, datasheet_name,
                                        datasheet_name + "_fire_cbm_output.csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_datasheet["AgeMin"] = my_datasheet.AgeMin.astype("Int64")
my_datasheet["AgeMax"] = my_datasheet.AgeMax.astype("Int64")
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Append to State Attribute Values - also need to add this scenario as a dependency and 
# store in correct folder
scenario_name = "State Attribute Values - Carbon Stocks & Flows"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsim_StateAttributeValue"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, datasheet_name,
                                        datasheet_name + "_fire_cbm_output.csv"))
my_datasheet["AgeMin"] = my_datasheet.AgeMin.astype("Int64")
my_datasheet["AgeMax"] = my_datasheet.AgeMax.astype("Int64")
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

## New
# Append to Initial Stocks - both spatial and non-spatial - just do non-spatial for now
scenario_name = "Initial Stocks Non Spatial"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_InitialStockNonSpatial"
my_datasheet = my_scenario.datasheets(name = datasheet_name)
new_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_datasheet = pd.concat([my_datasheet, new_values], ignore_index = True)
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add Stock Group Membership
scenario_name = "Stock Group Membership"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_StockTypeGroupMembership"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add Flow Group Membership
scenario_name = "Flow Group Membership"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_FlowTypeGroupMembership"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add Flow Order
scenario_name = "Flow Order"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_FlowOrder"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)