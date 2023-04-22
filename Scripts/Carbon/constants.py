# a275
# Katie Birchard, ApexRMS
# Run with python-3.8
#
# This script is used to define constants and global variables
# in a reproducible way across scripts

# Workspace ----
# Import modules
import os

## User configured inputs ----
CBM_DBASE = "C:/Program Files (x86)/Operational-Scale CBM-CFS3/Admin/DBs/ArchiveIndex_Beta_Install.mdb"
CUSTOM_FOLDER_NAME = "Carbon"

# Tabular file names
STATE_CLASS_TABLE = "ccap-state-class-crosswalk"

# Spatial file names - shapefiles
PRIMARY_STRATUM_FILE = "primary-stratum-coastal"
SECONDARY_STRATUM_FILE = "analysis-area-coastal"
TERTIARY_STRATUM_FILE = "tertiary-stratum-coastal"
FOREST_AGE_FILE = "forest-age-2000-coastal"

# Rasters
PRIMARY_STRATUM_RASTER = "primary-stratum-coastal-300m.tif"
SECONDARY_STRATUM_RASTER = "secondary-stratum-coastal-300m.tif"
TERTIARY_STRATUM_RASTER = "tertiary-stratum-coastal-300m.tif"
FOREST_AGE_RASTER = "forest-age-2000-coastal-300m.tif"
STATE_CLASS_RASTER = "state-class-coastal-300m.tif"

# Spatial file column names
PRIMARY_STRATUM_ID_FIELD = "US_L3CODE"
PRIMARY_STRATUM_NAME_FIELD = "US_L3NAME"
SECONDARY_STRATUM_ID_FIELD = "Id"
SECONDARY_STRATUM_NAME_FIELD = "Coastal"

# Run Control
RUN_CONTROL = {"Start Year": [1600, 2001, 2001, 2001, 1800, 1800],
               "End Year": [2001, 2301, 2022, 2004, 2004, 2300]}

# Initial Conditions
SPATIAL = True
IC_NON_SPATIAL_LANDSCAPE = {"Resolution": [0.025, 0.5, 5, 5, 40],
                            "Year": [2001, 2001, 2001, 1800, 1800]}

## Directories ----
### Core directories
cwd = os.getcwd()
ROOT_DIR = cwd.split(r"nestweb")[0] + "nestweb"
SCRIPTS_DIR = os.path.join(ROOT_DIR, "Scripts")
WORKING_DIR = os.path.join(SCRIPTS_DIR, "Carbon")

# TODO: put cbm cfs3 output in here as well (currently writes to custom model inputs dir)
CARBON_PREPROCESSING_DIR = os.path.join(SCRIPTS_DIR, "CONUS/Carbon Preprocessing")

DATA_DIR = os.path.join(ROOT_DIR, "Data")
LIBRARY_DIR = os.path.join(ROOT_DIR, "Libraries")
MODEL_INPUTS_DIR = os.path.join(ROOT_DIR, "Model Inputs")
MODEL_OUTPUTS_DIR = os.path.join(ROOT_DIR, "Model Outputs")
INTERMEDIATES_DIR = os.path.join(ROOT_DIR, "Intermediates")

### Composite directories ----
#### CONUS ---- 
# Raw data
# CONUS
CONUS_LULC_DATA_DIR   = os.path.join(DATA_DIR, "CONUS", "LULC")           
CONUS_CARBON_DATA_DIR = os.path.join(DATA_DIR, "CONUS", "Carbon")  
CONUS_CARBON_CBM_OUTPUT_DIR = os.path.join(CONUS_CARBON_DATA_DIR, "Tabular", "CBM Output Files")

# Custom
CUSTOM_CARBON_DATA_DIR = os.path.join(DATA_DIR, "Tabular")
CUSTOM_CARBON_CBM_DATA_DIR = os.path.join(CUSTOM_CARBON_DATA_DIR, "CBMCFS3 Spinup")
CUSTOM_CARBON_DATASHEET_DIR = os.path.join(CUSTOM_CARBON_DATA_DIR, "Datasheets")

# CBM output files
CONUS_CARBON_CBM_OUTPUT_DIR = os.path.join(CUSTOM_CARBON_DATA_DIR, "CBM Output Files")

# Intermediates
CONUS_LULC_INTERMEDIATES_DIR = os.path.join(INTERMEDIATES_DIR, "CONUS", "LULC")           
CONUS_CARBON_INTERMEDIATES_DIR = os.path.join(INTERMEDIATES_DIR, "CONUS", "Carbon")         
LA_INTERMEDIATES_DIR = os.path.join(INTERMEDIATES_DIR, "LA")
CUSTOM_INTERMEDIATES_DIR = os.path.join(INTERMEDIATES_DIR, CUSTOM_FOLDER_NAME)

# Model Inputs
CONUS_INPUTS_DIR = os.path.join(MODEL_INPUTS_DIR, "CONUS")
CUSTOM_INPUTS_DIR = os.path.join(MODEL_INPUTS_DIR, CUSTOM_FOLDER_NAME)

# Model Inputs - CONUS
CONUS_DEFINITIONS_DIR = os.path.join(CONUS_INPUTS_DIR, "Definitions")      
CONUS_CARBON_SUBSCENARIOS_DIR = os.path.join(CONUS_INPUTS_DIR, "Subscenarios Carbon")
CONUS_LULC_SUBSCENARIOS_DIR = os.path.join(CONUS_INPUTS_DIR, "Subscenarios LULC")

# Model Inputs - Custom
CUSTOM_DEFINITIONS_DIR = os.path.join(CUSTOM_INPUTS_DIR, "Definitions")
CUSTOM_LULC_SUBSCENARIOS_DIR = os.path.join(CUSTOM_INPUTS_DIR, "Subscenarios LULC")
CUSTOM_CARBON_SUBSCENARIOS_DIR = os.path.join(CUSTOM_INPUTS_DIR, "Subscenarios Carbon")

# Models Inputs - Custom - Definitions
CUSTOM_DEF_CBM_SPINUP_DIR = os.path.join(CUSTOM_DEFINITIONS_DIR, "CBMCFS3 Spinup")
CUSTOM_DEF_MERGED_DIR = os.path.join(CUSTOM_DEFINITIONS_DIR, "Forecast Model")

# Model Inputs - Custom - Subscenarios
CUSTOM_CARBON_SUB_CBM_SPINUP_DIR = os.path.join(CUSTOM_CARBON_SUBSCENARIOS_DIR, "CBMCFS3 Spinup")
CUSTOM_MERGED_SUBSCENARIOS_DIR = os.path.join(CUSTOM_CARBON_SUBSCENARIOS_DIR, "Forecast Model")

## Library information ----
LIBRARY_CARBON_LULC_FILE_NAME = "ECCC cavity nests model.ssim"
LIBRARY_FILE_NAME_BARE_LAND_SPINUP = "cbm-cfs3-spinup-flows.ssim"

## Model Terminology ----
AREA_UNITS = "Hectares"

# Changed for LA
PRIMARY_STRATUM = "BEC Variant"
SECONDARY_STRATUM = "Ownership"
#

TERTIARY_STRATUM = "Forest Type Group"
STATE_LABEL_X = "LULC Class"
STATE_LABEL_Y = "Sub Class"
STATE_CLASS = "State Class"
STOCK_GROUP = "Stock Group"

# State Classes ----
STATE_CLASS_FOREST = "Forest:All"
STATE_CLASS_WET_FOREST = "Wetland:Palustrine Forested"
STATE_CLASS_WET_HERB = "Wetland:Palustrine Emergent"
STATE_CLASS_GRASS = "Grassland:All"
STATE_CLASS_SHRUB = "Shrubland:All"
STATE_CLASS_BARREN = "Barren:All"
STATE_CLASS_DEVELOPED = "Developed:All"
STATE_CLASS_WATER = "Water:All"
STATE_CLASS_AGRICULTURE = "Cropland:All"

# Added for LA
STATE_CLASS_SHORE = "Unconsolidated Shore:All"
STATE_CLASS_WET_FOREST_EST = "Wetland:Estuarine Forested"
STATE_CLASS_WET_HERB_EST = "Wetland:Estuarine Emergent"

# Added for a269
STATE_CLASS_FOREST_ASPEN = "Forest:Aspen"
STATE_CLASS_FOREST_FIR = "Forest:Fir"
STATE_CLASS_FOREST_PINE = "Forest:Pine"
STATE_CLASS_FOREST_SPRUCE = "Forest:Spruce"
STATE_CLASS_FOREST_UNKNOWN = "Forest:Unknown"
STATE_CLASS_OTHER = "Other:All"
STATE_CLASS_WETLAND = "Wetland:All"
# 

STATE_SAV_DICT = {STATE_CLASS_FOREST: ["Init C Stocks 0"],
                  STATE_CLASS_WET_FOREST: ["Init C Stocks 0"],
                  STATE_CLASS_WET_HERB: ["Init C Stocks 0"],
                  STATE_CLASS_GRASS: ["Init C Stocks 0"],
                  STATE_CLASS_SHRUB: ["Init C Stocks 0"],
                  STATE_CLASS_BARREN: ["Init C Stocks Equilibrium"],
                  STATE_CLASS_DEVELOPED: ["Init C Stocks Equilibrium"],
                  STATE_CLASS_WATER: ["Init C Stocks Equilibrium"],
                  STATE_CLASS_AGRICULTURE: ["Init C Stocks Equilibrium"],
                  # Added for LA
                  STATE_CLASS_SHORE: ["Init C Stocks Equilibrium"],
                  STATE_CLASS_WET_FOREST_EST: ["Init C Stocks 0"],
                  STATE_CLASS_WET_HERB_EST: ["Init C Stocks Equilibrium"],
                  # Added for a269 - only want forest
                  STATE_CLASS_FOREST_ASPEN: ["Init C Stocks 0"],
                  STATE_CLASS_FOREST_FIR: ["Init C Stocks 0"],
                  STATE_CLASS_FOREST_PINE: ["Init C Stocks 0"],
                  STATE_CLASS_FOREST_SPRUCE: ["Init C Stocks 0"],
                  STATE_CLASS_FOREST_UNKNOWN: ["Init C Stocks 0"]}

STATE_CLASSES_TO_INCLUDE = [STATE_CLASS_GRASS, STATE_CLASS_WATER, STATE_CLASS_AGRICULTURE,
                            STATE_CLASS_DEVELOPED, STATE_CLASS_FOREST_ASPEN, STATE_CLASS_FOREST_FIR,
                            STATE_CLASS_FOREST_PINE, STATE_CLASS_FOREST_SPRUCE, STATE_CLASS_FOREST_UNKNOWN,
                            STATE_CLASS_OTHER, STATE_CLASS_WETLAND]

# Transitions ----
CBM_FOREST_CLEARCUT_TRANSITION = "Forest Harvest: Forest Clearcut"
CBM_FOREST_FIRE_TRANSITION = "Fire: High Severity"
FOREST_CLEARCUT_TRANSITION = "Disturbance: Clearcut"
FOREST_FIRE_TRANSITION = "Disturbance: Fire"
TRANSITIONS_TO_INCLUDE = [FOREST_CLEARCUT_TRANSITION, FOREST_FIRE_TRANSITION]
CUSTOM_LULC_TRANSITIONS = ["Wetland -> Wetland", "Wetland -> Water", "Wetland -> Shore",
                           "Wetland -> Other", "Water -> Wetland", "Shore -> Wetland"]

# Age groups ----
NUM_AGE_GROUPS = 11
AGE_GROUP_COLORS = ["255,186,253,106","255,167,231,99","255,149,209,92",
                    "255,130,187,85","255,111,165,78","255,93,144,71",
                    "255,74,122,64","255,55,100,57","255,37,78,50",
                    "255,18,56,43","255,49,52,37"]
MIN_FOREST_AGE = 10
MAX_FOREST_AGE = 300

# Primary Stratum ----
# Crosswalk from raster ID to primary stratum names in model
PRIMARY_STRATUM_IDS = {"KY": "Kentucky", 
                       "TN": "Tennessee",
                       "LA": "Louisiana"}

# Tertiary Stratum ----
TERTIARY_STRATUM_NO_DATA_VALUE = 55537
IMPUTED_FOREST_TYPE_GROUPS = True

# State Attribute Values ----
NET_GROWTH_SA = "NPP"
INITIAL_CARBON_BG_SLOW_SA = "Carbon Initial Conditions: Belowground Slow"

# Transition pathways ----
START_YEAR = 2001
TRANSITION_YEARS = [50]

# Flow Groups Output Filters ----
# For landscape scenarios
FLOW_GROUPS_FILTER_ON = ["Annual Net Emissions (CO2e)", "Annual Net Removals (CO2e)",
                         "Emission: Total", "Emission: Total (CO2e)",
                         "Net Biome Productivity", "Net Biome Productivity (CO2e)",
                         "Net Growth: Total", "Net Growth: Total (CO2e)"]

# CSV File suffixes
FOREST_SUFFIX = "_Forest"
WETLAND_EMERGENT_SUFFIX = "_WetlandHerb"
WETLAND_FOREST_SUFFIX = "_WetlandForested"
SHRUB_GRASS_SUFFIX = "_ShrubGrass"
AGRICULTURE_SUFFIX = "_Agriculture"
BARREN_DEVELOPED_SUFFIX = "_BarrenDeveloped"
WATER_SHORE_SUFFIX = "_WaterShore"
OTHER_SUFFIX = "_Other"

# For single stratum
PRIMARY_STRATUM_VALUE = "Mississippi Alluvial Plain"
SECONDARY_STRATUM_VALUE = None
TERTIARY_STRATUM_VALUE = "Oak/Gum/Cypress Group"

# Scenario Names
RUN_CONTROL_1600_2001_SCN = "Run Control [Non-Spatial; 1600-2001; 1 MC]"
RUN_CONTROL_2001_2301_SCN = "Run Control [Non-Spatial; 2001-2301; 1 MC]"
SAV_MEAN_FIRE_EQM_SCN = ["SAV: Mean Fire [Init C Stocks Equilibrium]"]
