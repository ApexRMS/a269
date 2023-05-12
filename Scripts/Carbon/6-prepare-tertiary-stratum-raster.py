## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This script creates a tertiary stratum raster that stores
## information on what the forest type origin is for each
## pixel. This raster is used for assigning flow pathways
## after transition from forest to non-forest state class in the
## final model.

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
import rasterio as rio

### Load Library ----
my_session = ps.Session()
my_session.add_packages("stsim")
my_session.add_packages("stsimsf")

my_library = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_CARBON_LULC_FILE_NAME))

my_project = my_library.projects(name = "Definitions")

# Load crosswalk from cbm data to nestweb data
cbm_to_nestweb_crosswalk = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "nestweb_to_cbm_forest_groups.csv"))

# Add tertiary stratum values to project (forest origin)
tertiary_stratum = pd.DataFrame(
    {"Name": cbm_to_nestweb_crosswalk[0:4]["Nestweb Forest State Class"],
     "ID": list(range(1,5))})
tertiary_stratum_datasheet = tertiary_stratum.copy()
tertiary_stratum_datasheet.Name = "Origin " + tertiary_stratum_datasheet.Name
my_project.save_datasheet("stsim_TertiaryStratum", tertiary_stratum_datasheet, append = False, force = True)

# Grab initial conditions spatial datasheet
my_scenario = my_project.scenarios(name = "Initial Conditions - Baseline Ownership")
my_datasheet = my_scenario.datasheets(name = "stsim_InitialConditionsSpatial", show_full_paths=True)

# Load primary stratum and state class rasters
with rio.open(my_datasheet.StratumFileName[0]) as src:
    stratum = src.read(1)
    stratum_meta = src.meta

with rio.open(my_datasheet.StateClassFileName[0]) as src:
    state_class = src.read(1)
    state_class_meta = src.meta

# Create tertiary stratum raster
stratum_datasheet = my_project.datasheets("stsim_Stratum")
sc_datasheet = my_project.datasheets("stsim_StateClass")

# First map by state class
sc_id_crosswalk = tertiary_stratum.merge(sc_datasheet, on= "Name")

# replace ids in state class raster w/ tertiary stratum ids
for i in range(len(sc_id_crosswalk)):
    state_class[state_class == sc_id_crosswalk.ID_y[i]] = sc_id_crosswalk.ID_x[i]

# Then map by stratum
stratum_to_state_class = {"Name": [], "State Class": []}
for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    state_class_cbm = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class_cbm]["Nestweb Forest State Class"].item()
    stratum_to_state_class["Name"].append(primary_stratum)
    stratum_to_state_class["State Class"].append(state_class_nw)

stratum_to_state_class = pd.DataFrame(stratum_to_state_class)
stratum_to_state_class = stratum_to_state_class.merge(stratum_datasheet, on="Name")
stratum_id_crosswalk = tertiary_stratum.merge(stratum_to_state_class, left_on= "Name", right_on="State Class")

for i in range(len(stratum_id_crosswalk)):
    stratum[stratum == stratum_id_crosswalk.ID_y[i]] = stratum_id_crosswalk.ID_x[i]

# Replace values in state class raster that do not correspond to tertiary ID with values
# from the stratum raster - want to mask multiple values
mask = np.logical_or.reduce([state_class == v for v in [20,30,40,50,60,70,90]])
new_array = np.copy(state_class)
new_array[mask] = stratum[mask]

# Write tertiary stratum raster
tertiary_stratum_meta = stratum_meta.copy()
with rio.open(os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "tertiary_stratum.tif"), "w", **tertiary_stratum_meta) as dst:
    dst.write(new_array.astype(rio.uint8), 1)

# Add tertiary stratum raster to project
my_datasheet.TertiaryStratumFileName = os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "tertiary_stratum.tif")
my_scenario.save_datasheet("stsim_InitialConditionsSpatial", my_datasheet)

# Repeat for 2 other scenarios
my_scenario = my_project.scenarios(name = "Initial Conditions - Increased Aspen Protection")
my_datasheet = my_scenario.datasheets(name = "stsim_InitialConditionsSpatial", show_full_paths=True)
my_datasheet.TertiaryStratumFileName = os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "tertiary_stratum.tif")
my_scenario.save_datasheet("stsim_InitialConditionsSpatial", my_datasheet)

my_scenario = my_project.scenarios(name = "Initial Conditions - Military Training Land Protection")
my_datasheet = my_scenario.datasheets(name = "stsim_InitialConditionsSpatial", show_full_paths=True)
my_datasheet.TertiaryStratumFileName = os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "tertiary_stratum.tif")
my_scenario.save_datasheet("stsim_InitialConditionsSpatial", my_datasheet)