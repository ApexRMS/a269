## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This script creates definition datasheets for a269 Wetlands Carbon stsim-sf model
## Definitions datasheets are exported and saved as CSV files
## Option to save definitions to stsim-sf library (used to check for correct datasheet format)
## Note that some definitions files are loaded in from CSV files.

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

# Import modules
import pysyncrosim as ps
import pandas as pd

# Set preferences for saving and exporting definitions
saveDatasheets = True # Set to True to save datasheet back to library
exportDatasheets = True # Set to True to export datasheet as csv
spinup_suffix = "-cbmcfs3"

if saveDatasheets:
    # Set up SyncroSim session if saveDatasheets = True
    mySession = ps.Session()
    mySession.add_packages("stsim")
    mySession.add_packages("stsimsf")
    
    # Uses the default SyncroSim session
    myLibrary = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_FILE_NAME_BARE_LAND_SPINUP),
      session = mySession, package = "stsim", 
      addons = ["stsimsf","stsimcbmcfs3"], overwrite=True)
      
    # Assumes there is only one default project per library
    myProject = myLibrary.projects(name = "Definitions")

# Set local variables
TreeCoverLabel = "Forest"
WetlandLabel = "Wetland"
modelsToInclude = [TreeCoverLabel, WetlandLabel]

## ST-Sim Terminology ---- (updated)
datasheetName = "stsim_Terminology"
myDatasheet = pd.DataFrame({"AmountLabel": ["Area"],
                            "AmountUnits": ["Hectares"],
                            "StateLabelX": [STATE_LABEL_X],
                            "StateLabelY": [STATE_LABEL_Y],
                            "PrimaryStratumLabel": [PRIMARY_STRATUM],
                            "SecondaryStratumLabel": [SECONDARY_STRATUM],
                            "TertiaryStratumLabel": None,
                            "TimestepUnits": ["Year"]})
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Strata ----
datasheetName = "stsim_Stratum"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
    datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim State Class ----
datasheetName = "stsim_StateClass"
myStateClass = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
                         datasheetName + ".csv"))
myStateClass = myStateClass[myStateClass.StateLabelXID.isin(modelsToInclude)].reset_index(drop=True)

# ST-Sim StateLabelX (LULC) ----
datasheetName = "stsim_StateLabelX"
myDatasheet = pd.DataFrame({"Name": myStateClass.StateLabelXID.unique()})
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim StateLabelY (Subclass) ----
datasheetName = "stsim_StateLabelY"
myDatasheet = pd.DataFrame({"Name": myStateClass.StateLabelYID.unique()})
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim State Class saved after StateLabelX and StateLabelY
datasheetName = "stsim_StateClass"
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myStateClass,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Transition Type ----
datasheetName = "stsim_TransitionType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR,
          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Transition Group ----
datasheetName = "stsim_TransitionGroup"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Transition Types by Group ----
datasheetName = "stsim_TransitionTypeGroup"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Age Types  ----
datasheetName = "stsim_AgeType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# ST-Sim Age Groups ----
datasheetName = "stsim_AgeGroup"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# SF Stock Types ------------------------------------------------------------
datasheetName = "stsimsf_StockType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)                                     

# SF Stock Groups ------------------------------------------------------------
datasheetName = "stsimsf_StockGroup"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, 
                          datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)  

# SF Flow Types ------------------------------------------------------------
datasheetName = "stsimsf_FlowType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR) 

# SF Flow Groups ------------------------------------------------------------
datasheetName = "stsimsf_FlowGroup"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)  

# SF Terminology ------------------------------------------------------------
datasheetName = "stsimsf_Terminology"
myDatasheet = pd.DataFrame({"StockUnits": ["metric tons C"]})
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)  

# ST-Sim Attribute Groups ------------------------------------------------------------
datasheetName = "stsim_AttributeGroup"
myDatasheet = pd.DataFrame({"Name": ["Carbon Initial Conditions", "NPP"]})
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)  

# ST-Sim Attribute Types ------------------------------------------------------------
datasheetName = "stsim_StateAttributeType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# CBM Ecological Boundary ------------------------------------------------------------
datasheetName = "stsimcbmcfs3_EcoBoundary" # TODO change for KY-TN?
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# CBM Administrative Boundary ------------------------------------------------------------
datasheetName = "stsimcbmcfs3_AdminBoundary" # TODO change for KY-TN
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# CBM Species Type  ------------------------------------------------------------
datasheetName = "stsimcbmcfs3_SpeciesType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# CBM Disturbance Type ------------------------------------------------------------
datasheetName = "stsimcbmcfs3_DisturbanceType"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)

# CBM Stock  ------------------------------------------------------------
datasheetName = "stsimcbmcfs3_CBMCFS3Stock"
myDatasheet = pd.read_csv(os.path.join(CUSTOM_CARBON_CBM_DATA_DIR, datasheetName + ".csv"))
finalize_datasheets(saveDatasheets, exportDatasheets, myProject, datasheetName, myDatasheet,
                    folder=CUSTOM_DEF_CBM_SPINUP_DIR)