## a275
## Katie Birchard (ApexRMS)
## April 20, 2023
##
## This script extracts the outputs from the CBM-CFS3 spinup
## and prepares it to be used in the forecast model.

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

# Set environment vars
result_scenario_ids_harvest = []
result_scenario_ids_fire = []
fire_forest_scn_name = "Generate Flow Multipliers - Fire - Forest"
fire_wetforest_scn_name = "Generate Flow Multipliers - Fire - Wetland Forest"
harvest_forest_scn_name = "Generate Flow Multipliers - Harvest - Forest"
harvest_wetforest_scn_name = "Generate Flow Multipliers - Harvest - Wetland Forest"
cbm_output_suffix = "_cbm_output"
SAV_datasheet_name = "stsim_StateAttributeValue"
FM_datasheet_name = "stsimsf_FlowMultiplier"
FP_datasheet_name = "stsimsf_FlowPathway"
TransitionTypesToInclude = ["Fire: High Severity",
                            "Forest Harvest: Forest Clearcut"]
TransitionGroupsToInclude = [s + " [Type]" for s in TransitionTypesToInclude] + [np.NaN]
ds_names = [SAV_datasheet_name, FM_datasheet_name, FP_datasheet_name]

mySession = ps.Session()
mySession.add_packages("stsim")
mySession.add_packages("stsimsf")
mySession.add_packages("stsimcbmcfs3")

# Uses the default SyncroSim session
myLibrary = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_FILE_NAME_BARE_LAND_SPINUP),
    session = mySession, package = "stsim", addons = ["stsimsf", "stsimcbmcfs3"])
    
# Assumes there is only one default project per library
myProject = myLibrary.projects(name = "Definitions")

# Need to grab result scenario ids
result_scenario_ids_harvest.append(
    get_result_scenario_id(myProject, harvest_forest_scn_name))
result_scenario_ids_harvest.append(
    get_result_scenario_id(myProject, harvest_wetforest_scn_name))
result_scenario_ids_fire.append(
    get_result_scenario_id(myProject, fire_forest_scn_name))
result_scenario_ids_fire.append(
    get_result_scenario_id(myProject, fire_wetforest_scn_name))

# Retrieve outputs from each generate multipliers run and combine wetland + forest
origin = "_harvest"
data = retrieve_generate_multipliers_outputs(myProject, result_scenario_ids_harvest)
data = convert_output_for_forecast(data)
save_spinup_flow_results(data, origin, ds_names, cbm_output_suffix, TransitionGroupsToInclude)

origin = "_fire"
data = retrieve_generate_multipliers_outputs(myProject, result_scenario_ids_fire)
data = convert_output_for_forecast(data)
save_spinup_flow_results(data, origin, ds_names, cbm_output_suffix, TransitionGroupsToInclude)