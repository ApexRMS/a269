## a275
## Katie Birchard (ApexRMS)
## November 2022
##
## This script creates CBM-CFS3 datasheets and saves them as .csvs
## Option to save datasheets directly to library
## Assumes that 1-definitions.py script is run first (to generate project 
## datasheets)
## Many of the datasheets are read in from a275/Data/CONUS/Carbon/Tabular/Datasheets
## and are suffixed with "_TreeCover".
## To edit these datasheets, edit the csvs in the above folder and re-run this script

## Workspace ----
# import modules
import os
import sys
import pandas as pd
import pysyncrosim as ps

os.chdir("C:/gitprojects/a275/Scripts/CONUS/Carbon Preprocessing/Forest/Spinup + Flows") # remove once done testing

sys.path.append("../../../../.")

# Import helper functions
from helper_functions import *

# Import constants/global variables 
from constants import *

# Create directories for initial conditions and transition targets
create_subscenario_dir("stsimsf_FlowPathwayDiagram", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR)
create_subscenario_dir("stsimsf_FlowPathway", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR)
create_subscenario_dir("stsimsf_InitialStockNonSpatial", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR) 
create_subscenario_dir("stsimsf_OutputOptions", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR) 
create_subscenario_dir("stsimsf_StockTypeGroupMembership", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR) 
create_subscenario_dir("stsimsf_FlowTypeGroupMembership", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR) 

# Set preferences for saving and exporting definitions
saveDatasheets = False # Set to True to save datasheet back to library
exportDatasheets = True # Set to True to export datasheet as csv

# Tabular data - Load from definitions
stateAttributeTypes = pd.read_csv(os.path.join(CUSTOM_DEF_CBM_SPINUP_DIR,
                                               "stsim_StateAttributeType.csv"))
stateClasses = pd.read_csv(os.path.join(CUSTOM_DEF_CBM_SPINUP_DIR,
                                        "stsim_StateClass-cbmcfs3.csv"))

if saveDatasheets:
    # Set up SyncroSim session if saveDatasheets = True
    mySession = ps.Session()
    mySession.add_packages("stsim")
    mySession.add_packages("stsimsf")
    mySession.add_packages("stsimcbmcfs3")
    
    # Uses the default SyncroSim session
    myLibrary = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_FILE_NAME_BARE_LAND_SPINUP),
      session = mySession, package = "stsim", addons = "stsimsf")
    myLibrary.enable_addons("stsimcbmcfs3")
      
    # Assumes there is only one default project per library
    myProject = myLibrary.projects(name = "Definitions")

# Set local variables
TreeCoverLabel = "Forest"
WetlandLabel = "Wetland Forested"

modelsToInclude = [TreeCoverLabel, WetlandLabel]

# Set myScenario as None - reset if saveDatasheets is True
myScenario = None

# Flow Pathways--------------------------------
scenarioName = "SF Flow Pathways: Base"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

# Flow Pathway Diagram
datasheetName = "stsimsf_FlowPathwayDiagram"

# SF Stocks
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
                                       datasheetName + ".csv"))

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))

# Flow Pathway
datasheetName = "stsimsf_FlowPathway"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
                                datasheetName + ".csv"))

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))

# Separate flow pathways for Forest + wetland for running stsimcbmcfs3
for model in modelsToInclude:
    scenarioName = "SF Flow Pathways: " + model
    subset = myDatasheet[myDatasheet.FlowTypeID.str.contains(model+":") \
        | ~myDatasheet.StateAttributeTypeID.str.contains("NPP", na=False)]
    finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    subset, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName),
                    csv_append="_" + model)

# Initial Stocks--------------------------------
scenarioName = "SF Initial Stocks: Base (Spinup + Flows)"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

datasheetName = "stsimsf_InitialStockNonSpatial"

newStateAttributeTypes = stateAttributeTypes.replace(
                     "Carbon Initial Conditions:",
                     "Carbon Initial Conditions DOM:",
                     regex=True)
for attr in ["Foliage", "Fine Roots", "Coarse Roots", "Merchantable", "Other Wood"]:
    if attr == "Fine Roots":
        newStateAttributeTypes.replace("DOM: " + attr, "Biomass: Fine Root", regex=True, inplace=True)
    elif attr == "Coarse Roots":
        newStateAttributeTypes.replace("DOM: " +  attr, "Biomass: Coarse Root", regex=True, inplace=True)
    else:
        newStateAttributeTypes.replace("DOM: " + attr, "Biomass: " + attr, regex=True, inplace=True)

myDatasheet = stateAttributeTypes[
    stateAttributeTypes["AttributeGroupID"] == "Carbon Initial Conditions"
    ].rename(columns={"Name": "StateAttributeTypeID"})

myDatasheet['StockTypeID'] = newStateAttributeTypes['Name'
    ].str.replace('Carbon Initial Conditions ', '')

myDatasheet = myDatasheet[["StockTypeID", "StateAttributeTypeID"]]

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))

# Output Options ------------------------------
scenarioName = "SF Output Options: Base - Summary Stock & Flow"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

datasheetName = "stsimsf_OutputOptions"

myDatasheet = pd.DataFrame({"SummaryOutputST": [True],
                          "SummaryOutputFL": [True],
                          "SummaryOutputSTTimesteps": [1],
                          "SummaryOutputFLTimesteps": [1]})

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))

# Stock Group Membership ------------------------------
scenarioName = "SF Stock Group Membership: Base (Spinup + Flows)"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

datasheetName = "stsimsf_StockTypeGroupMembership"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
                          datasheetName + ".csv"))[["StockTypeID", "StockGroupID"]]
finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))

# Flow Group Membership--------------------------
scenarioName = "SF Flow Group Membership: Base (Spinup + Flows)"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

datasheetName = "stsimsf_FlowTypeGroupMembership" 
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
                                datasheetName + ".csv"))

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))