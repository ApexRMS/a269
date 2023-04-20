## a269
## Katie Birchard (ApexRMS)
## April 2023

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