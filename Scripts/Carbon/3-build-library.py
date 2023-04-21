## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This script loads definition and scenario data sheets saved as csvs
## into an st-simsf library
## It creates sub scenarios and full scenarios

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
import pandas as pd
import pysyncrosim as ps

# Set local variables
TreeCoverLabel = "Forest"
WetlandLabel = "Wetland Forested"

modelsToInclude = [TreeCoverLabel, WetlandLabel]

# Load session
mySession = ps.Session()
mySession.add_packages("stsim")
mySession.add_packages("stsimsf")

# Uses the default SyncroSim session
myLibrary = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_FILE_NAME_BARE_LAND_SPINUP),
    session = mySession, package = "stsim", addons = "stsimsf",
    overwrite=True)
myLibrary.enable_addons("stsimcbmcfs3")

# Configure the CBM database in the Library Properties
cbm_db = myLibrary.datasheets(name = "stsimcbmcfs3_Database")
cbm_db.loc[0, "Path"] = CBM_DBASE
myLibrary.save_datasheet(name = "stsimcbmcfs3_Database", data = cbm_db)
    
# Assumes there is only one default project per library
myProject = myLibrary.projects(name = "Definitions")

# Definitions ----
# load all stsim and sf definition datasheets from definitions folder
load_definitions(myProject, CUSTOM_DEF_CBM_SPINUP_DIR, cbmcfs3=True)

# Define the pipeline for each stage in CBM-CFS3
scenarioName = "Pipeline - Load CBM-CFS3 Output"
myScenario = myProject.scenarios(scenarioName)
pipeline = myScenario.datasheets(name = "core_Pipeline")
if (pipeline.empty):
    stages = myProject.datasheets(name = "core_Transformer")
    stage_name = stages[
        stages.TransformerName == "stsimcbmcfs3_LoadCBMCFS3Output"
        ].TransformerDisplayName.item()
    pipeline = pd.concat([pipeline, pd.DataFrame({'StageNameID': [stage_name], "RunOrder": [1]})])
    myScenario.save_datasheet(name = "core_Pipeline", data = pipeline)

# Grab stage name from Project definitions
scenarioName = "Pipeline - Generate Flow Multipliers"
myScenario = myProject.scenarios(scenarioName)
pipeline = myScenario.datasheets(name = "core_Pipeline")
if (pipeline.empty):
    stages = myProject.datasheets(name = "core_Transformer")
    stage_name = stages[
        stages.TransformerName == "stsimcbmcfs3_FlowPathways"
        ].TransformerDisplayName.item()
    pipeline = pd.concat([pipeline, pd.DataFrame({'StageNameID': [stage_name], "RunOrder": [1]})])
    myScenario.save_datasheet(name = "core_Pipeline", data = pipeline)

# Create folders for subscenarios and full scenarios
subscenario_folder_id = create_project_folder(mySession, 
                                              myLibrary,
                                              myProject,
                                              folder_name="Subscenarios")                                   

# Subscenarios ----
# Run Control
# Run Control: Non-spatial 300 years, 1 MC
scenarioName = "Run Control: Non-spatial, 300 yr, 1 MC"
myScenario = myProject.scenarios(scenarioName)
datasheetName = "stsim_RunControl"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + ".csv"))
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# SF Flow Pathways
for model in modelsToInclude:
    scenarioName = "SF Flow Pathways: " + model
    myScenario = myProject.scenarios(scenarioName)
    datasheetName = "stsimsf_FlowPathwayDiagram"
    flowPathwayDiagram = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                     datasheetName,
                                     datasheetName + ".csv"))
    myScenario.save_datasheet(datasheetName, flowPathwayDiagram)
    datasheetName = "stsimsf_FlowPathway"
    flowPathway = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                datasheetName,
                                datasheetName + "_" + model + ".csv"))
    myScenario.save_datasheet(datasheetName, flowPathway)
    add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# SF Initial Stocks -----------------------------
# SF Initial Stocks Merged Model
scenarioName = "SF Initial Stocks: Base"
myScenario = myProject.scenarios(scenarioName)
datasheetName = "stsimsf_InitialStockNonSpatial"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                              datasheetName,
                              datasheetName + ".csv"))
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# SF Output Options -----------------------------
scenarioName = "SF Output Options: Base - Summary Stock & Flow"
myScenario = myProject.scenarios(scenarioName)
datasheetName = "stsimsf_OutputOptions"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + ".csv"))
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# SF Stock Group Membership -----------------------------
# SF Stock Group Membership Merged Model
scenarioName = "SF Stock Group Membership: Base"
myScenario = myProject.scenarios(scenarioName)
datasheetName = "stsimsf_StockTypeGroupMembership"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                              datasheetName, datasheetName + ".csv"))
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# SF Flow Group Membership -----------------------------
# SF Flow Group Membership Merged Model
scenarioName = "SF Flow Group Membership: Base"
myScenario = myProject.scenarios(scenarioName)
datasheetName = "stsimsf_FlowTypeGroupMembership"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                              datasheetName, datasheetName + ".csv"))
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# CBM Crosswalk - Stocks -----------------------------
scenarioName = "CBM Crosswalk - Stocks"
myScenario = myProject.scenarios(scenarioName)

datasheetName = "stsimcbmcfs3_CrosswalkStock"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + ".csv")) 
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# CBM Crosswalk - Spatial Unit and Species Type -----------------------------
# Fire - Forest
scenarioName = "CBM Crosswalk - Spatial Unit and Species Type - Fire - Forest"
myScenario = myProject.scenarios(scenarioName)

datasheetName = "stsimcbmcfs3_CrosswalkSpecies"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + FOREST_SUFFIX + "_Fire.csv")) 
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# Harvest - Forest
scenarioName = "CBM Crosswalk - Spatial Unit and Species Type - Harvest - Forest"
myScenario = myProject.scenarios(scenarioName)

datasheetName = "stsimcbmcfs3_CrosswalkSpecies"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + FOREST_SUFFIX + "_Harvest.csv")) 
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)

# CBM Crosswalk - Disturbance -----------------------------
scenarioName = "CBM Crosswalk - Disturbance"
myScenario = myProject.scenarios(scenarioName)

datasheetName = "stsimcbmcfs3_CrosswalkDisturbance"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                          datasheetName, datasheetName + ".csv")) 
myScenario.save_datasheet(datasheetName, myDatasheet)
add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, subscenario_folder_id)