## a269
## Katie Birchard (ApexRMS)
## April 2023

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

# Run single cell scenarios
for scn in SINGLE_CELL_SCENARIO_NAMES:
    my_scenario = my_project.scenarios(name = scn)
    my_scenario.run()

#%%
# Run spatial scenarios
for scn in SPATIAL_SCENARIO_NAMES:
    my_scenario = my_project.scenarios(name = scn)
    my_scenario.run()