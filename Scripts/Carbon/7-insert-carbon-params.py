## a269
## Katie Birchard (ApexRMS)
## April 2023
##
## This scripts modifies existing datasheets and creates new datasheets
## in the ECCC library to add carbon stocks and flows to the model.

#%%
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
import rioxarray
import rasterio as rio

### Load Library ----
my_session = ps.Session()
my_session.add_packages("stsim")
my_session.add_packages("stsimsf")

my_library = ps.library(name = os.path.join(LIBRARY_DIR, LIBRARY_CARBON_LULC_FILE_NAME))

my_project = my_library.projects(name = "Definitions")

folder_df = list_folders_in_library(my_session, my_library)

# Load crosswalk from cbm data to nestweb data
cbm_to_nestweb_crosswalk = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "nestweb_to_cbm_forest_groups.csv"))

# Local vars
no_data = -9999

# Create folder for storing rasters
create_subscenario_dir("stsimsf_InitialStockSpatial", dir_name=CUSTOM_MERGED_SUBSCENARIOS_DIR)

# Create empty list to store new scenario dependencies
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

#%%
### Spatial ---
# Update Initial Stocks Spatial
# Load all required rasters
my_scenario = my_project.scenarios(SPATIAL_SCENARIO_NAMES[0])
scn_deps = my_scenario.dependencies()
scn_name = scn_deps[scn_deps.Name.str.contains("Initial Conditions - ")].iloc[0].Name
ic_spatial_scn = my_project.scenarios(name = scn_name)
ic_spatial = ic_spatial_scn.datasheets("stsim_InitialConditionsSpatial", show_full_paths=True)

forest_age_raster = rioxarray.open_rasterio(ic_spatial.AgeFileName.iloc[0])
forest_type_raster = rioxarray.open_rasterio(ic_spatial.TertiaryStratumFileName.iloc[0])
state_class_raster = rioxarray.open_rasterio(ic_spatial.StateClassFileName.iloc[0])

# Grab raster metadata
with rio.open(ic_spatial.StratumFileName.iloc[0]) as src:
    crs = src.crs
    meta = src.profile
    

meta.update(dtype=rio.float32)
raster_dims = forest_age_raster.shape
raster_length = forest_age_raster.size

cell_info = pd.DataFrame({"age": forest_age_raster.values.reshape(raster_length, -1).squeeze(),
                          "forest_type_group": forest_type_raster.values.reshape(raster_length, -1).squeeze(),
                          "state_class": state_class_raster.values.reshape(raster_length, -1).squeeze()})

# Load state attribute values as lookup table
sav_lookup_fire = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, 
                                           "stsim_StateAttributeValue", 
                                           "stsim_StateAttributeValue_fire_cbm_output.csv"))
sav_lookup_fire["origin"] = "fire"
sav_lookup_fire.TertiaryStratumID = "Origin " + sav_lookup_fire.StateClassID

for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    
    sav_lookup_fire.loc[sav_lookup_fire["StratumID"] == primary_stratum, "TertiaryStratumID"] = "Origin " + state_class_nw

sav_lookup_harvest = pd.read_csv(os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR,
                                              "stsim_StateAttributeValue",
                                              "stsim_StateAttributeValue_harvest_cbm_output.csv"))
sav_lookup_harvest["origin"] = "harvest"
sav_lookup_harvest.TertiaryStratumID = "Origin " + sav_lookup_harvest.StateClassID

for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    
    sav_lookup_harvest.loc[sav_lookup_harvest["StratumID"] == primary_stratum, "TertiaryStratumID"] = "Origin " + state_class_nw

sav_lookup = pd.concat([sav_lookup_fire, sav_lookup_harvest])

# Convert age, forest type group, and state class to IDs for merging with cell info
state_class_datasheet = my_project.datasheets("stsim_StateClass", optional=True)
forest_type_datasheet = my_project.datasheets("stsim_TertiaryStratum", optional=True)

sav_lookup["age"] = sav_lookup["AgeMin"].astype("Int64")
sav_lookup = sav_lookup.merge(forest_type_datasheet[["Name", "ID"]], 
                              left_on="TertiaryStratumID", right_on="Name")
sav_lookup.rename(columns = {"ID": "forest_type_group"}, inplace=True)
sav_lookup = sav_lookup.merge(state_class_datasheet[["Name", "ID"]], 
                              left_on="StateClassID", right_on="Name")
sav_lookup.rename(columns = {"ID": "state_class"}, inplace=True)

# Turn time since most recent disturbance rasters into binary arrays
tst_fire_path = os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "time-since-fire.tif")
tst_harvest_path = os.path.join(CUSTOM_CARBON_SPATIAL_DATA_DIR, "time-since-cut-update.tif")

with rio.open(tst_fire_path) as src:
    tst_fire = src.read(1)
with rio.open(tst_harvest_path) as src:
    tst_harvest = src.read(1)

tst_fire = tst_fire.astype(float)
tst_fire[tst_fire == -9999] = np.NaN
tst_harvest = tst_harvest.astype(float)
tst_harvest[tst_harvest == -9999] = np.NaN
cell_info["tst_fire"] = tst_fire.reshape(raster_length, -1).squeeze()
cell_info["tst_harvest"] = tst_harvest.reshape(raster_length, -1).squeeze()

# compare harvest and fire columns, set higher value to Nan
cell_info["tst_harvest"] = np.where(cell_info["tst_harvest"] > cell_info["tst_fire"], np.NaN, cell_info["tst_harvest"])
cell_info["tst_fire"] = np.where(cell_info["tst_fire"] > cell_info["tst_harvest"], np.NaN, cell_info["tst_fire"])

# Set all non NaN values to 1
cell_info["tst_fire"] = np.where(cell_info["tst_fire"].notnull(), 1, cell_info["tst_fire"])
cell_info["tst_harvest"] = np.where(cell_info["tst_harvest"].notnull(), 1, cell_info["tst_harvest"])

# Set all NaN values to 0
cell_info["tst_fire"] = np.where(cell_info["tst_fire"].isnull(), 0, cell_info["tst_fire"])
cell_info["tst_harvest"] = np.where(cell_info["tst_harvest"].isnull(), 0, cell_info["tst_harvest"])

# Retrieve datasheet with initial stocks
stock_non_spatial_scenario_name = "Initial Stocks Non Spatial"
stock_non_spatial_scenario = my_project.scenarios(stock_non_spatial_scenario_name)
initial_stocks = stock_non_spatial_scenario.datasheets("stsimsf_InitialStockNonSpatial")
initial_stocks_spatial = pd.DataFrame({"StockTypeID": [], "RasterFileName": []})

# Loop through all available state attribute ids to create all input rasters
for row in initial_stocks.itertuples():

    sa_id = row.StateAttributeTypeID

    if not sa_id.startswith("Carbon"):
        continue

    stock_id = row.StockTypeID
    stock_id_clean = stock_id.split(":")[1].strip(" ")

    initial_stock_data = cell_info.copy()

    # Create initial stock fire and harvest rasters
    for origin in ["fire", "harvest"]:

        sav_lookup_temp = sav_lookup[sav_lookup.StateAttributeTypeID == sa_id]
        sav_lookup_temp = sav_lookup_temp[sav_lookup_temp.origin == origin]
        sav_lookup_temp = sav_lookup_temp[["age", "forest_type_group", "state_class", "Value"]]
        sav_lookup_temp = sav_lookup_temp.drop_duplicates()

        sav_lookup_temp.fillna(-9999, inplace=True)
        no_data_row = pd.DataFrame({"age": [-9999],
                                    "forest_type_group": [-9999],
                                    "state_class": [-9999],
                                    "Value": [-9999]})
        sav_lookup_temp = pd.concat([sav_lookup_temp, no_data_row])

        # Merge state attribute value information with cell info and write to raster
        initial_stock_data = initial_stock_data.merge(sav_lookup_temp, on=["age", "forest_type_group", "state_class"], how="left")
        initial_stock_data.rename(columns = {"Value": origin}, inplace=True)
        initial_stock_data[origin] = initial_stock_data[origin] * initial_stock_data[f"tst_{origin}"]

    initial_stock_data["Value"] = initial_stock_data["fire"] + initial_stock_data["harvest"]
    initial_stock_data["Value"] = np.where(initial_stock_data["Value"] == 0, -9999, initial_stock_data["Value"])
    initial_stock_data["Value"] = np.where(initial_stock_data["Value"].isnull(), -9999, initial_stock_data["Value"])
    raster_data = np.array(initial_stock_data.Value).reshape(1, raster_dims[1], -1)
    filepath = os.path.join(CUSTOM_MERGED_SUBSCENARIOS_DIR, "stsimsf_InitialStockSpatial", f"{stock_id_clean}.tif")

    with rio.open(filepath, 'w', **meta) as dst:
        dst.crs = crs
        dst.write(raster_data)

    # Fill datasheet with initial stocks
    initial_stocks_spatial = pd.concat([initial_stocks_spatial, pd.DataFrame({"StockTypeID": [stock_id], "RasterFileName": [filepath]})])

# Save datasheet with initial stocks
scenario_name = "Initial Stocks Spatial"
my_scenario = my_project.scenarios(name = scenario_name)
my_scenario.save_datasheet("stsimsf_InitialStockSpatial", initial_stocks_spatial, append=True)

### Modifiy Scenarios ----
### Single Cell ---
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

my_datasheet.ToStockTypeID.replace("Biomass: Coarse Roots", "Biomass: Coarse Root", inplace=True)
my_datasheet.ToStockTypeID.replace("Biomass: Fine Roots", "Biomass: Fine Root", inplace=True)

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
my_datasheet.TertiaryStratumID = "Origin " + my_datasheet.StateClassID

for primary_stratum in cbm_to_nestweb_crosswalk["BEC Variant"].dropna().unique():
    state_class = cbm_to_nestweb_crosswalk[cbm_to_nestweb_crosswalk["BEC Variant"] == primary_stratum]["CBM Forest State Class"].item()
    state_class_nw = cbm_to_nestweb_crosswalk[0:4][cbm_to_nestweb_crosswalk[0:4][
        "CBM Forest State Class"] == state_class]["Nestweb Forest State Class"].item()
    
    my_datasheet.loc[my_datasheet["StratumID"] == primary_stratum, "TertiaryStratumID"] = "Origin " + state_class_nw

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
# %%

# Add all new datasheets as dependencies to existing scenarios
# state attribute values, flow group membership, stock group membership, & flow order
for scn in SINGLE_CELL_SCENARIO_NAMES:
    my_scenario = my_project.scenarios(name = scn)
    my_scenario.dependencies(new_dependencies)

for scn in SPATIAL_SCENARIO_NAMES:
    my_scenario = my_project.scenarios(name = scn)
    my_scenario.dependencies(new_dependencies)