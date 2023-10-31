## a269
## Katie Birchard (ApexRMS)
## May 2023
##
## This script creates charts and maps displaying results
## of adding carbon stocks and flows.
## Assumes you have run the preceding scripts in order.

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

### Load Library ----
my_session = ps.Session()
my_session.add_packages("stsim")
my_session.add_packages("stsimsf")

my_library = ps.library(name = os.path.join(LIBRARY_DIR, "Working", "Test", LIBRARY_CARBON_LULC_FILE_NAME))

my_project = my_library.projects(name = "Definitions")

# Save preconfigured charts
chart_info = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "corestime_Charts.csv"))
chart_info["Iteration"] = chart_info["Iteration"].astype("Int64")
my_project.save_datasheet("corestime_Charts", chart_info)

#%%
# Save preconfigured maps
map_info = pd.read_csv(os.path.join(CUSTOM_CARBON_DATA_DIR, "corestime_Maps.csv"))
my_project.save_datasheet("corestime_Maps", map_info)