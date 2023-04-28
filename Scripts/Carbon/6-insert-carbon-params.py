## a269
## Katie Birchard (ApexRMS)
## April 2023

## Workspace ----
# Set up environment
import os
import sys

# Load paths to retrieve helper functions and constants
cwd = os.getcwd()
root_dir = cwd.split(r"nestweb")[0] + "nestweb"

# Set working directory
os.chdir(os.path.join(root_dir, "Scripts/Carbon"))

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

folder_df = list_folders_in_library(my_session, my_library)

# Load crosswalk from cbm data to nestweb data
cbm_to_nestweb_crosswalk = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "nestweb_to_cbm_forest_groups.csv"))

new_dependencies = []

### Modify Definitions ----
# Add Attribute Group
my_datasheet = my_project.datasheets(name = "stsim_AttributeGroup")
my_datasheet["Name"] = ["Carbon Initial Conditions", "NPP"]
my_project.save_datasheet(name = "stsim_AttributeGroup", data = my_datasheet)

# Add Stock Groups
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, "stsimsf_StockGroup.csv"))
my_datasheet = my_datasheet[~my_datasheet.Name.str.contains("tons C/ha")]
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

### Modifiy Scenarios ----
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
grass_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
grass_values = grass_values[grass_values["FromStateClassID"] == STATE_CLASS_GRASS]
my_datasheet = pd.concat([my_datasheet, grass_values], ignore_index = True)

# Add some transition triggered flows - when LULC: Forest -> Cropland/Developed, add forest fps for cropland/developed
new_values[~new_values.FromStateClassID.isnull()]
new_values[new_values.FromStateClassID.str.contains("Forest")]

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

# Add tertiary stratum to forest flow multipliers
tertiary_stratum = my_project.datasheets("stsim_TertiaryStratum")
new_values.TertiaryStratumID = "Origin " + new_values.StateClassID

for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    
    new_values.loc[new_values["StratumID"] == primary_stratum, "TertiaryStratumID"] = "Origin " + state_class_nw

# Add cropland/developed flow multipliers for when transitioning from forest
forest_origins = cbm_to_nestweb_crosswalk[0:4]["Nestweb Forest State Class"].unique()
cropland_values = new_values[new_values.StateClassID.isin(forest_origins)]
cropland_values["StateClassID"] = STATE_CLASS_AGRICULTURE
developed_values = new_values[new_values.StateClassID.isin(forest_origins)]
developed_values["StateClassID"] = STATE_CLASS_DEVELOPED

# Add grassland multipliers
grass_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
grass_values = grass_values[grass_values["StateClassID"] == STATE_CLASS_GRASS]
grass_values["StratumID"] = np.NaN

my_datasheet = pd.concat([my_datasheet, new_values, cropland_values, developed_values, grass_values], ignore_index = True)
my_datasheet["AgeMin"] = my_datasheet.AgeMin.astype("Int64")
my_datasheet["AgeMax"] = my_datasheet.AgeMax.astype("Int64")
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Append to State Attribute Values - also need to add this scenario as a dependency and 
scenario_name = "State Attribute Values - Carbon Stocks & Flows"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsim_StateAttributeValue"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, datasheet_name,
                                        datasheet_name + "_fire_cbm_output.csv"))
grass_values = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + "_ShrubGrass.csv"))
grass_values = grass_values[grass_values["StateClassID"] == STATE_CLASS_GRASS]
my_datasheet = pd.concat([my_datasheet, grass_values], ignore_index = True)
my_datasheet["AgeMin"] = my_datasheet.AgeMin.astype("Int64")
my_datasheet["AgeMax"] = my_datasheet.AgeMax.astype("Int64")
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add scenario to state attribute values folder
fid = str(folder_df[folder_df.Name.str.contains("State Attribute Values")].iloc[0].ID)
add_scenario_to_folder(my_session, my_library, my_project, my_scenario, fid)
new_dependencies.append(scenario_name)

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
my_datasheet = my_datasheet[~my_datasheet.StockGroupID.str.contains("tons C/ha")]
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add scenario to stock flow folder
fid = str(folder_df[folder_df.Name.str.contains("Stocks & Flows")].iloc[0].ID)
add_scenario_to_folder(my_session, my_library, my_project, my_scenario, fid)
new_dependencies.append(scenario_name)

# Add Flow Group Membership
scenario_name = "Flow Group Membership"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_FlowTypeGroupMembership"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add scenario to stock flow folder
fid = str(folder_df[folder_df.Name.str.contains("Stocks & Flows")].iloc[0].ID)
add_scenario_to_folder(my_session, my_library, my_project, my_scenario, fid)
new_dependencies.append(scenario_name)

# Add Flow Order
scenario_name = "Flow Order"
my_scenario = my_project.scenarios(name = scenario_name)
datasheet_name = "stsimsf_FlowOrderOptions"
my_datasheet= pd.DataFrame({"ApplyBeforeTransitions": [True], 
                           "ApplyEquallyRankedSimultaneously": [True]})
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)
datasheet_name = "stsimsf_FlowOrder"
my_datasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_DATASHEET_DIR, datasheet_name + ".csv"))
my_scenario.save_datasheet(name = datasheet_name, data = my_datasheet)

# Add scenario to stock flow folder
fid = str(folder_df[folder_df.Name.str.contains("Stocks & Flows")].iloc[0].ID)
add_scenario_to_folder(my_session, my_library, my_project, my_scenario, fid)
new_dependencies.append(scenario_name)

# Add new scenarios as dependencies to full scenarios - 
# state attribute values, flow group membership, stock group membership, & flow order
scenario_name = "Single Cell - No Disturbance"
my_scenario = my_project.scenarios(name = scenario_name)
my_scenario.dependencies(new_dependencies)

scenario_name = "Single Cell - Fire"
my_scenario = my_project.scenarios(name = scenario_name)
my_scenario.dependencies(new_dependencies)