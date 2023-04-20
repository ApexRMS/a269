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
import re
import pandas as pd
import numpy as np
import pysyncrosim as ps

os.chdir("C:/gitprojects/a275/Scripts/CONUS/Carbon Preprocessing/Forest/Spinup + Flows") # remove once done testing

sys.path.append("../../../../.")

# Import helper functions
from helper_functions import *

# Import constants/global variables 
from constants import *

# Create directories for initial conditions and transition targets
create_subscenario_dir("stsim_RunControl", dir_name=CUSTOM_CARBON_SUB_CBM_SPINUP_DIR)


# Set preferences for saving and exporting definitions
saveDatasheets = False # Set to True to save datasheet back to library
exportDatasheets = True # Set to True to export datasheet as csv

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
WetlandLabel = "Wetland"

modelsToInclude = [TreeCoverLabel, WetlandLabel]

# Set myScenario as None - reset if saveDatasheets is True
myScenario = None

# Run Control ---------------------------------------------------------------
# Run Control: Non-spatial 300 years, 1 MC
scenarioName = "Run Control: Non-spatial, 300 yr, 1 MC"
if saveDatasheets:
    myScenario = myProject.scenarios(name = scenarioName)

datasheetName = "stsim_RunControl"
myDatasheet = pd.DataFrame({"MaximumIteration": [1], 
                            "MinimumTimestep": [0], 
                            "MaximumTimestep": [300]})

finalize_datasheets(saveDatasheets,
                    exportDatasheets,
                    myScenario,
                    datasheetName,
                    myDatasheet, 
                    os.path.join(CUSTOM_CARBON_SUB_CBM_SPINUP_DIR,
                                 datasheetName))