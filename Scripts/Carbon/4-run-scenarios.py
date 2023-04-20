## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This script loads definition and scenario data sheets saved as csvs
## into cbm-cfs3 Scenarios within an stsimsf Library.
## The Result Scenarios from running this script are then used to 
## build the stsimsf Library.

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

mySession = ps.Session()
mySession.add_packages("stsim")
mySession.add_packages("stsimsf")
mySession.add_packages("stsimcbmcfs3")

# Uses the default SyncroSim session
myLibrary = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_FILE_NAME_BARE_LAND_SPINUP))

# Assumes there is only one default project per library
myProject = myLibrary.projects(name = "Definitions")

cbmcfs3_folder_id = create_project_folder(mySession,
                                          myLibrary,
                                          myProject,
                                          folder_name="CBM-CFS3 Scenarios")

#### CBM-CFS3 Scenarios #### -----------------------------
# Load CBM Output ------
# Fire - Forest
scenarioName = "Load CBM Output - Fire - Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["CBM Crosswalk - Stocks",
                                      "CBM Crosswalk - Spatial Unit and Species Type - Fire - Forest",
                                      "Run Control: Non-spatial, 300 yr, 1 MC",
                                      "Pipeline - Load CBM-CFS3 Output"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myScenario.run(jobs=1)

# Fire - Wetland Forest
scenarioName = "Load CBM Output - Fire - Wetland Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["CBM Crosswalk - Stocks",
                                      "CBM Crosswalk - Spatial Unit and Species Type - Fire - Wetland Forest",
                                      "Run Control: Non-spatial, 300 yr, 1 MC",
                                      "Pipeline - Load CBM-CFS3 Output"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myScenario.run(jobs=1)

# Harvest - Forest
scenarioName = "Load CBM Output - Harvest - Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["CBM Crosswalk - Stocks",
                                      "CBM Crosswalk - Spatial Unit and Species Type - Harvest - Forest",
                                      "Run Control: Non-spatial, 300 yr, 1 MC",
                                      "Pipeline - Load CBM-CFS3 Output"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myScenario.run(jobs=1)

# Harvest - Wetland Forest
scenarioName = "Load CBM Output - Harvest - Wetland Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["CBM Crosswalk - Stocks",
                                      "CBM Crosswalk - Spatial Unit and Species Type - Harvest - Wetland Forest",
                                      "Run Control: Non-spatial, 300 yr, 1 MC",
                                      "Pipeline - Load CBM-CFS3 Output"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myScenario.run(jobs=1)

# Generate Flow Multipliers ------
# Fire - Forest
scenarioName = "Generate Flow Multipliers - Fire - Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["SF Flow Group Membership: Base",
                                      "SF Stock Group Membership: Base",
                                      "SF Output Options: Base - Summary Stock & Flow",
                                      "SF Initial Stocks: Base",
                                      "SF Flow Pathways: Forest",
                                      "CBM Crosswalk - Disturbance",
                                      "Load CBM Output - Fire - Forest",
                                      "Pipeline - Generate Flow Multipliers"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myResultScenario = myScenario.run(jobs=1)

# Fire - Wetland Forest
scenarioName = "Generate Flow Multipliers - Fire - Wetland Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["SF Flow Group Membership: Base",
                                      "SF Stock Group Membership: Base",
                                      "SF Output Options: Base - Summary Stock & Flow",
                                      "SF Initial Stocks: Base",
                                      "SF Flow Pathways: Wetland Forested",
                                      "CBM Crosswalk - Disturbance",
                                      "Load CBM Output - Fire - Wetland Forest",
                                      "Pipeline - Generate Flow Multipliers"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myResultScenario = myScenario.run(jobs=1)

# Harvest - Forest
scenarioName = "Generate Flow Multipliers - Harvest - Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["SF Flow Group Membership: Base",
                                      "SF Stock Group Membership: Base",
                                      "SF Output Options: Base - Summary Stock & Flow",
                                      "SF Initial Stocks: Base",
                                      "SF Flow Pathways: Forest",
                                      "CBM Crosswalk - Disturbance",
                                      "Load CBM Output - Harvest - Forest",
                                      "Pipeline - Generate Flow Multipliers"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myResultScenario = myScenario.run(jobs=1)

# Harvest - Wetland Forest
scenarioName = "Generate Flow Multipliers - Harvest - Wetland Forest"
myScenario = myProject.scenarios(scenarioName)
myScenario.dependencies(dependency = ["SF Flow Group Membership: Base",
                                      "SF Stock Group Membership: Base",
                                      "SF Output Options: Base - Summary Stock & Flow",
                                      "SF Initial Stocks: Base",
                                      "SF Flow Pathways: Wetland Forested",
                                      "CBM Crosswalk - Disturbance",
                                      "Load CBM Output - Harvest - Wetland Forest",
                                      "Pipeline - Generate Flow Multipliers"])

add_scenario_to_folder(mySession, myLibrary, myProject, myScenario, cbmcfs3_folder_id)

myResultScenario = myScenario.run(jobs=1)
