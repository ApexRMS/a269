## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This script extracts the outputs from the CBM-CFS3 spinup
## and prepares it to be used in the forecast model.

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

# Set environment vars
result_scenario_ids_harvest = []
result_scenario_ids_fire = []
fire_forest_scn_name = "Generate Flow Multipliers - Fire - Forest"
cbm_output_suffix = "_cbm_output"
SAV_datasheet_name = "stsim_StateAttributeValue"
FM_datasheet_name = "stsimsf_FlowMultiplier"
FP_datasheet_name = "stsimsf_FlowPathway"
TransitionTypesToInclude = [CBM_FOREST_FIRE_TRANSITION,
                            CBM_FOREST_CLEARCUT_TRANSITION]
TransitionGroupsToInclude = [s + " [Type]" for s in TransitionTypesToInclude] + [np.NaN]
ds_names = [SAV_datasheet_name, FM_datasheet_name, FP_datasheet_name]

# Load crosswalk from cbm data to nestweb data
cbm_to_nestweb_crosswalk = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "nestweb_to_cbm_forest_groups.csv"))

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
result_scenario_ids_fire.append(
    get_result_scenario_id(myProject, fire_forest_scn_name))

# Load the data
origin = "_fire"
data = retrieve_generate_multipliers_outputs(myProject, result_scenario_ids_fire)

data[0] = data[0][data[0]["StateClassID"].isin(cbm_to_nestweb_crosswalk["CBM Forest State Class"].unique())]
data[0]["StateClassID"] = data[0]["StateClassID"].replace(cbm_to_nestweb_crosswalk[0:4].set_index(
    "CBM Forest State Class")["Nestweb Forest State Class"].to_dict())
data[0]["StratumID"] = np.NaN

# Should be using a different crosswalk for forest unknown mapping - hardcode for now
forest_unknown_data = pd.DataFrame()
for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    data_new = data[0].copy()
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    data_new = data_new[data_new["StateClassID"] == state_class_nw]
    data_new["StateClassID"] = STATE_CLASS_FOREST_UNKNOWN
    data_new["StratumID"] = primary_stratum
    forest_unknown_data = pd.concat([forest_unknown_data, data_new])

data[0] = pd.concat([data[0], forest_unknown_data])

# Only keep values in data that are contained in the crosswalk
data[1] = data[1][data[1]["StateClassID"].isin(cbm_to_nestweb_crosswalk["CBM Forest State Class"].unique())]
data[1]["StateClassID"] = data[1]["StateClassID"].replace(cbm_to_nestweb_crosswalk[0:4].set_index(
    "CBM Forest State Class")["Nestweb Forest State Class"].to_dict())
data[1]["StratumID"] = np.NaN

# Should be using a different crosswalk for forest unknown mapping - hardcode for now
forest_unknown_data = pd.DataFrame()
for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    data_new = data[1].copy()
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    data_new = data_new[data_new["StateClassID"] == state_class_nw]
    data_new["StateClassID"] = STATE_CLASS_FOREST_UNKNOWN
    data_new["StratumID"] = primary_stratum
    forest_unknown_data = pd.concat([forest_unknown_data, data_new])

data[1] = pd.concat([data[1], forest_unknown_data])

lulc_data = data[2][data[2].FromStateClassID.isnull()]
data[2].FromStateClassID.unique()
data[2] = data[2][data[2]["FromStateClassID"].isin(cbm_to_nestweb_crosswalk["CBM Forest State Class"].unique())]
data[2]["FromStateClassID"] = data[2]["FromStateClassID"].replace(cbm_to_nestweb_crosswalk[0:4].set_index(
    "CBM Forest State Class")["Nestweb Forest State Class"].to_dict())
data[2]["FromStratumID"] = np.NaN

# Should be using a different crosswalk for forest unknown mapping - hardcode for now
forest_unknown_data = pd.DataFrame()
for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    data_new = data[2].copy()
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    data_new = data_new[data_new["FromStateClassID"] == state_class_nw]
    data_new["FromStateClassID"] = STATE_CLASS_FOREST_UNKNOWN
    data_new["FromStratumID"] = primary_stratum
    forest_unknown_data = pd.concat([forest_unknown_data, data_new])

data[2] = pd.concat([lulc_data, data[2], forest_unknown_data])
# data = convert_output_for_forecast(data)
save_spinup_flow_results(data, origin, ds_names, cbm_output_suffix, TransitionGroupsToInclude)