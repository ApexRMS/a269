# These are helper functions creating project definitions, subscenarios, and 
# building libraries

# Remove unnecessary warnings
import pandas as pd
import numpy as np
import os
import re
import io
import subprocess
from dask.distributed import Client, Lock
import glob
from win32api import GetFileVersionInfo, LOWORD, HIWORD
from constants import *
pd.options.mode.chained_assignment = None  # default='warn'

# Load rioxarray
gdal_installations = []
if "PATH" in os.environ:
  for p in os.environ["PATH"].split(os.pathsep):
    if p and glob.glob(os.path.join(p, "gdal*.dll")):
      gdal_installations.append(os.path.abspath(p))

if len(gdal_installations) > 1:
    for folder in gdal_installations:
        filenames = [f for f in os.listdir(folder) if f.startswith("gdal") & f.endswith(".dll")]

        for filename in filenames:
            filename = os.path.join(folder, filename)
        
            if not os.path.exists(filename):           
                print("no gdal dlls found in " + folder)
                os.environ['PATH'] = os.pathsep.join(
                        [p for p in os.environ['PATH'].split(os.pathsep) if folder not in p])
                continue
            try:
                info = GetFileVersionInfo (filename, "\\")
            except:
                continue
            
            major_version = HIWORD (info['FileVersionMS'])
            minor_version = LOWORD (info['FileVersionMS'])

            if (major_version < 3) | (minor_version < 6):
                os.environ['PATH'] = os.pathsep.join(
                    [p for p in os.environ['PATH'].split(os.pathsep) if folder not in p])
                
import rioxarray as rxr

# General functions ------------------------------------------------------------

def flatten(l):
  """
  Flatten a list of lists.
  
  Parameters
  ----------
  l : list  
    List of lists
  
  Returns
  -------
  list
    Flattened list
  """
  return [i for sl in l for i in sl]

# Make more sophisticated later
def sav_unit_converter(data, src_units="t/ha", dest_units="t/km2"):
    if src_units == "t/ha" and dest_units == "t/km2":
        data = data * 100
    if src_units == "t/km2" and dest_units == "t/ha":
        data = data / 100
    if src_units == "t/km2" and dest_units == "t/a":
        data = data / (2.471 * 100)
    if src_units == "t/a" and dest_units == "t/km2":
        data = data * (2.471 * 100)
    if src_units == "t/ha" and dest_units == "t/a":
        data = data / 2.471
    if src_units == "t/a" and dest_units == "t/ha":
        data = data * 2.471
    return data

# Functions for all scripts -----------------------------------------------------

def export_datasheets(datasheetName, datasheet, folder=CONUS_DEFINITIONS_DIR,
                      csv_append = ""):
    
    if not os.path.exists(folder):
        os.makedirs(folder)

    filepath = os.path.join(folder, datasheetName + csv_append + ".csv")
    datasheet.to_csv(filepath, index = False, float_format="%.10f")

def finalize_datasheets(save, export, ssimObject, datasheetName, datasheet, 
                        folder=CONUS_DEFINITIONS_DIR, csv_append = ""):
    """
    Finalize datasheet by writing to library and/or exporting to csv.
    
    Parameters
    ----------
    save : bool
        Save datasheet to library
    export : bool
        Export datasheet to csv
    ssimObject : pysyncrosim.Library, pysyncrosim.Project, pysyncrosim.Scenario
        pysyncrosim object of class Library, Project, or Scenario
    datasheetName : str
        Name of datasheet
    datasheet : pandas.DataFrame
        Datasheet dataframe
    folder : str
        Folder to export csv to
    csv_append : str
        String to append to csv name
    
    Returns
    -------
    None
    """
    if save: 
        ssimObject.save_datasheet(name = datasheetName, data = datasheet)
    if export:
        if not os.path.exists(folder):
            os.makedirs(folder)
        filepath = os.path.join(folder, datasheetName + csv_append + ".csv")
        datasheet.to_csv(filepath, index = False, float_format="%.10f")

def create_project_folder(session, library, project, folder_name):
  """
  Create a folder within a SyncroSim project
  
  Parameters
  ----------
  session : pysyncrosim.Session
    pysyncrosim session object
  library : pysyncrosim.Library
    pysyncrosim library object
  project : pysyncrosim.Project
    pysyncrosim project object
  
  Returns
  -------
  str
    Folder id
  """

  command = "\"" + os.path.join(session.location, "SyncroSim.Console.exe\"") \
    + " --create --folder --lib=\"" + library.location + "\"" \
        + " --name=\"" + folder_name + "\"" + " --tpid=" + str(project.pid)
  out = subprocess.run(command, stdout=subprocess.PIPE, shell=True)
  folder_id = re.findall(r'\d+', out.stdout.decode('utf-8'))[0]

  return folder_id

def create_nested_folder(session, library, parent_folder_id, folder_name):
  """
  Create a folder within an existing folder.
  
  Parameters
  ----------
  session : pysyncrosim.Session
    pysyncrosim session object
  library : pysyncrosim.Library
    pysyncrosim library object
  parent_folder_id : str
    Parent folder id
  folder_name : str
    Name of folder to create
  
  Returns
  -------
  str
    Folder id
  """

  command = "\"" + os.path.join(session.location, "SyncroSim.Console.exe\"") \
    + " --create --folder --lib=\"" + library.location + "\"" \
        + " --name=\"" + folder_name + "\"" + " --tfid=" + parent_folder_id
  out = subprocess.run(command, stdout=subprocess.PIPE, shell=True)
  folder_id = re.findall(r'\d+', out.stdout.decode('utf-8'))[0]

  return folder_id

def add_scenario_to_folder(session, library, project, scenario, folder_id):
  """
  Add a scenario to a folder within a SyncroSim project
  
  Parameters
  ----------
  session : pysyncrosim.Session
    pysyncrosim session object
  library : pysyncrosim.Library
    pysyncrosim library object
  project : pysyncrosim.Project
    pysyncrosim project object
  scenario : pysyncrosim.Scenario
    pysyncrosim scenario object
  folder_id : str 
    Folder id
  
  Returns
  -------
  None
  """

  command = "\"" + os.path.join(session.location, "SyncroSim.Console.exe\"") \
    + " --move --scenario --lib=\"" + library.location + "\"" \
        + " --sid=" + str(scenario.sid) + " --tfid=" + folder_id + " --tpid=" \
            + str(project.pid)
  subprocess.call(command, stdout=subprocess.PIPE, shell=True)


def get_result_scenario_id(myProject, scenario_name):
  """
  Get the scenario id of a result scenario
  
  Parameters
  ----------
  myProject : pysyncrosim.Project
    pysyncrosim project object
  scenario_name : str
    Name of the result scenario
  
  Returns
  -------
  int
    Scenario id of the result scenario
  """
  myScenario = myProject.scenarios(name = scenario_name)
  myResultScenarios = myScenario.results()
  return myResultScenarios[
      myResultScenarios["Name"].str.contains(scenario_name, regex=False)
      ].ScenarioID.values[-1]

# Load definitions ------------------------------------------------------------
# This function loads definitions into an stsim sf library.
# Definitions to be loaded are stored as csvs in a definitions folder. 
def load_definitions(project, datasheetFolder, tag="", 
                     loadingOrder = None, cbmcfs3 = False):
  """
  Load definitions into an stsim sf library. Definitions to be loaded are 
  stored as csvs in a definitions folder.
  
  Parameters
  ----------
  project : pysyncrosim.Project
    pysyncrosim project object
  datasheetFolder : str
    Folder containing csvs of definitions to load
  tag : str
    Tag to append to datasheet names
  loadingOrder : list
    List of datasheet names in order to load
  
  Returns
  -------
  None
  """
  
  if loadingOrder is None:
    loadingOrder = ["stsim_Terminology", "stsim_Stratum", 
                    "stsim_SecondaryStratum", "stsim_TertiaryStratum",
                    "stsim_StateLabelX", "stsim_StateLabelY",
                    "stsim_StateClass", "stsim_TransitionType",
                    "stsim_TransitionGroup", "stsim_TransitionTypeGroup",
                    "stsim_AttributeGroup","stsim_StateAttributeType", 
                    "stsim_AgeType", "stsim_AgeGroup",
                    "corestime_DistributionType", 
                    "corestime_ExternalVariableType", "stsimsf_StockType", 
                    "stsimsf_StockGroup", "stsimsf_FlowType",
                    "stsimsf_FlowGroup", "stsimsf_Terminology"]

    cbmcfs3_datasheets = ["stsimcbmcfs3_AdminBoundary",
                          "stsimcbmcfs3_CBMCFS3Stock",
                          "stsimcbmcfs3_DisturbanceType",
                          "stsimcbmcfs3_EcoBoundary",
                          "stsimcbmcfs3_SpeciesType"]
    
    if cbmcfs3:
      loadingOrder += cbmcfs3_datasheets

  # Loop through sheets in the definitions folder by loading order
  for datasheetName in loadingOrder:

    if (len(tag) > 0):
      definitionFileName = datasheetName + "_" + tag + ".csv"
    else:
      definitionFileName = datasheetName + ".csv"
      
    definitionFile = os.path.join(datasheetFolder, definitionFileName)

    if (os.path.exists(definitionFile)):
      myDatasheet = pd.read_csv(definitionFile)
      project.save_datasheet(datasheetName, myDatasheet)

# Functions for definitions.py -------------------------------------------------

def find_top_forest_type_group(tertiary_stratum, primary_stratum):

    num_threads = 6
    client = Client(threads_per_worker = num_threads, n_workers = 1)
    tertiary_stratum.rio.write_nodata(TERTIARY_STRATUM_NO_DATA_VALUE, inplace=True)
    top_forest_group_dict = {PRIMARY_STRATUM_NAME_FIELD: [],
                            "Top Forest Type Group": []}

    for stratum in primary_stratum[PRIMARY_STRATUM_NAME_FIELD].unique():

        primary_stratum_temp = primary_stratum[primary_stratum[PRIMARY_STRATUM_NAME_FIELD] == stratum]
        aoi = primary_stratum_temp.geometry.values

        def mask(block, aoi = aoi):
            return block.rio.clip(aoi, drop = False)

        temp = tertiary_stratum.rio.clip_box(*aoi.total_bounds)

        out = temp.map_blocks(mask, template=temp)

        output_filename = os.path.join(CUSTOM_INTERMEDIATES_DIR, f"tertiary-stratum-{stratum}-clip.tif")
        out.rio.to_raster(output_filename, tiled=True, lock=Lock("rio", client=client),  windowed = True, overwrite= True, compress = 'lzw')

        # Mask tertiary stratum raster
        tertiary_stratum_clip = rxr.open_rasterio(output_filename)
        tertiary_stratum_clip = tertiary_stratum_clip.astype(np.uint16).squeeze().to_numpy()
        tertiary_stratum_clip = np.reshape(tertiary_stratum_clip, tertiary_stratum_clip.size)
        tertiary_stratum_clip = tertiary_stratum_clip[tertiary_stratum_clip != TERTIARY_STRATUM_NO_DATA_VALUE]
        top_forest_type_group = np.bincount(tertiary_stratum_clip).argmax()

        top_forest_group_dict[PRIMARY_STRATUM_NAME_FIELD].append(stratum)
        top_forest_group_dict["Top Forest Type Group"].append(top_forest_type_group)

    pd.DataFrame(top_forest_group_dict).to_csv(
        os.path.join(CUSTOM_INTERMEDIATES_DIR, "top_forest_type_group.csv"), index=False)

def generate_transition_types(stateClasses):
  """
  Generate all possible LULC Transition Types between pairs of non-identical 
  State Classes. Also shorten the names of the Transition Types.
  
  Parameters
  ----------
  stateClasses : pandas.DataFrame
    State classes dataframe
    
  Returns
  -------
  transitionTypes : pandas.DataFrame
    Transition types dataframe
    
  """
  # Wetland state classes - named as Class:Subclass
  srcClassesWetland = stateClasses[stateClasses['StateLabelXID'] == 'Wetland']
  srcClassesWetland['srcName'] = "Wetland:" + srcClassesWetland['StateLabelYID']
  srcClassesWetland['srcID'] = srcClassesWetland['ID']
  
  # Non-wetland state classes - named as Class only
  srcClassesOther = stateClasses[stateClasses['StateLabelXID'] != 'Wetland']
  srcClassesOther['srcName'] = srcClassesOther['StateLabelXID']
  srcClassesOther['srcID'] = srcClassesOther['ID']
  
  # Bring all state classes back together
  srcClasses = pd.concat([srcClassesWetland, srcClassesOther])
  srcClasses.rename(columns={'StateLabelXID': 'srcClass'}, inplace=True)
  srcClasses = srcClasses[['srcClass', 'srcName', 'srcID']]
  
  # Setup a dataframe with all combinations of to/from state classes
  nrows = len(srcClasses)
  transitionTypes = srcClasses.loc[srcClasses.index.repeat(nrows)]  
  transitionTypes['destClass'] = ""
  transitionTypes['destName'] = ""
  transitionTypes['destID'] = np.nan
  
  for i in range(0, nrows):
    for j in range(0, nrows):
        row = ((i - 1) * nrows) + j
        transitionTypes['destClass'].iloc[row] = srcClasses.iloc[j]['srcClass']
        transitionTypes['destName'].iloc[row] = srcClasses.iloc[j]['srcName']
        transitionTypes['destID'].iloc[row] = srcClasses.iloc[j]['srcID'].astype(int)

  transitionTypes['destID'] = transitionTypes['destID'].astype(int)
  
  # Remove the rows with same source and destination Class
  transitionTypes = transitionTypes[transitionTypes['srcID'] != transitionTypes['destID']]
  
  # Add columns with Name and ID for Transition Types. Note that TransitionTypeID = (srcID * 100) + destID
  transitionTypes['Name'] = transitionTypes['srcName'] + "->" + transitionTypes['destName']
  transitionTypes['ID'] = (transitionTypes['srcID'].astype(str) + transitionTypes['destID'].astype(str)).astype(int)

  # Write Transition Types back to library
  transitionTypesMinimalColumns = transitionTypes[['Name', 'ID']]
  
  return transitionTypesMinimalColumns

def generate_transition_groups(stateClasses):
  """
  Generate transition groups from state classes.
  
  Parameters
  ----------
  stateClasses : pandas.DataFrame
    State classes dataframe
  
  Returns
  -------
  transitionGroups : pandas.DataFrame
    Transition groups dataframe
  """

  # Wetland state classes - named as Class:Subclass
  srcClassesWetland = stateClasses[stateClasses['StateLabelXID'] == 'Wetland']
  srcClassesWetland['srcName'] = "Wetland:" + srcClassesWetland['StateLabelYID']
  srcClassesWetland['srcID'] = srcClassesWetland['ID']
  
  # Non-wetland state classes - named as Class only
  srcClassesOther = stateClasses[stateClasses['StateLabelXID'] != 'Wetland']
  srcClassesOther['srcName'] = srcClassesOther['StateLabelXID']
  srcClassesOther['srcID'] = srcClassesOther['ID']
  
  # Bring all state classes back together
  srcClasses = pd.concat([srcClassesWetland, srcClassesOther])
  srcClasses.rename(columns={'StateLabelXID': 'srcClass'}, inplace=True)
  srcClasses = srcClasses[['srcClass', 'srcName', 'srcID']]
  
  # Generate a transition group for every source and destination state class
  transitionGroupsSrc = srcClasses.copy()
  transitionGroupsSrc['Name'] = transitionGroupsSrc['srcName'] + "->"
  transitionGroupsSrc['ID'] = transitionGroupsSrc['srcID']
  transitionGroupsDest = srcClasses.copy()
  transitionGroupsDest['Name'] = "->" + transitionGroupsDest['srcName']
  transitionGroupsDest['ID'] = transitionGroupsDest['srcID']
  transitionGroups = pd.concat([transitionGroupsSrc, transitionGroupsDest])
  transitionGroups = transitionGroups[['Name', 'ID']]
  
  # Add in source and destination groups for Wetland summary LULC classes
  transitionGroupsNoID = transitionGroups[['Name']]
  wetlandSummaryGroups = pd.DataFrame({'Name':["Wetland->", "->Wetland"]})
  lulcSummaryGroups = pd.DataFrame({'Name':["LULC Change"]})
  otherGroups = pd.DataFrame({"Name": ["Other->Wetland:Herb", "Other->Wetland:For",
                                       "Wetland:Herb->Other", "Wetland:For->Other"]})
  transitionGroupsNoID = pd.concat([transitionGroupsNoID, wetlandSummaryGroups, otherGroups, lulcSummaryGroups])

  return transitionGroupsNoID

# Generate transition types by groups from state classes
def generate_transition_types_by_groups(stateClasses):
  """
  Generate transition types by groups from state classes. Generate all 
  possible LULC Transition Types between pairs of non-identical State 
  Classes. Also shorten the names of the Transition Types.
  
  Parameters
  ----------
  stateClasses : pandas.DataFrame
    State classes dataframe
    
  Returns
  -------
  transitionTypesByGroups : pandas.DataFrame
    Transition types by groups dataframe
  """
  # Wetland state classes - named as Class:Subclass
  srcClassesWetland = stateClasses[stateClasses['StateLabelXID'] == 'Wetland']
  srcClassesWetland['srcName'] = "Wetland:" + srcClassesWetland['StateLabelYID']
  srcClassesWetland['srcName2'] = srcClassesWetland['srcName'].str.split(expand=True)[0]
  srcClassesWetland['srcID'] = srcClassesWetland['ID']
  
  # Non-wetland state classes - named as Class only
  srcClassesOther = stateClasses[stateClasses['StateLabelXID'] != 'Wetland']
  srcClassesOther['srcName'] = srcClassesOther['StateLabelXID']
  srcClassesOther['srcName2'] = srcClassesOther['srcName'].str.split(expand=True)[0]
  srcClassesOther['srcID'] = srcClassesOther['ID']
  
  # Bring all state classes back together
  srcClasses = pd.concat([srcClassesWetland, srcClassesOther])
  srcClasses.rename(columns={'StateLabelXID': 'srcClass'}, inplace=True)
  srcClasses = srcClasses[['srcClass', 'srcName', 'srcName2', 'srcID']]
  
  # Setup a dataframe with all combinations of to/from state classes
  nrows = len(srcClasses)
  transitionTypes = srcClasses.loc[srcClasses.index.repeat(nrows)]  
  transitionTypes['destClass'] = ""
  transitionTypes['destName'] = ""
  transitionTypes['destName2'] = ""
  transitionTypes['destID'] = np.nan

  for i in range(0, nrows):
    for j in range(0, nrows):
        row = ((i - 1) * nrows) + j
        transitionTypes['destClass'].iloc[row] = srcClasses.iloc[j]['srcClass']
        transitionTypes['destName'].iloc[row] = srcClasses.iloc[j]['srcName']
        transitionTypes['destName2'].iloc[row] = srcClasses.iloc[j]['srcName2'] # check this
        transitionTypes['destID'].iloc[row] = srcClasses.iloc[j]['srcID'].astype(int)

  transitionTypes['destID'] = transitionTypes['destID'].astype(int)
  
  # Remove the rows with same source and destination Class
  transitionTypes = transitionTypes[transitionTypes['srcID'] != transitionTypes['destID']]
  
  # Add columns with Name and ID for Transition Types. Note that TransitionTypeID = (srcID * 100) + destID
  transitionTypes['Name'] = transitionTypes['srcName'] + "->" + transitionTypes['destName']
  transitionTypes['ID'] = (transitionTypes['srcID'].astype(str) + transitionTypes['destID'].astype(str)).astype(int)
  
  transitionTypes.rename(columns={'Name': 'TransitionType', 'ID': 'TransitionTypeID'}, inplace=True)  
  
  # Associate Types with source Groups
  transitionTypesSrc = transitionTypes.copy()
  transitionTypesSrc['TransitionGroup'] = transitionTypesSrc['TransitionType'].str.split(r"->", expand=True)[0] + "->"

  # Associate Types with destination Groups
  transitionTypesDest = transitionTypes.copy()
  transitionTypesDest['TransitionGroup'] = "->" + transitionTypesSrc['TransitionType'].str.split(r"->", expand=True)[1]
  
  # Bring all types by group together
  transitionTypesByGroup = pd.concat([transitionTypesSrc, transitionTypesDest])
  
  # Add in Wetland summary Groups
  wetlandSummaryTypesSrc = transitionTypesByGroup[transitionTypesByGroup['srcClass'].str.contains("Wetland")]
  wetlandSummaryTypesSrc = wetlandSummaryTypesSrc[wetlandSummaryTypesSrc['TransitionGroup'].str.contains("Wetland")]
  wetlandSummaryTypesSrc = wetlandSummaryTypesSrc[~wetlandSummaryTypesSrc['TransitionGroup'].str.contains("->Wetland")]
  wetlandSummaryTypesSrc = wetlandSummaryTypesSrc[wetlandSummaryTypesSrc['TransitionType'].str.findall("Wetland").str.len() < 2]
  wetlandSummaryTypesSrc['TransitionGroup'] = "Wetland->"

  wetlandSummaryTypesDest = transitionTypesByGroup[transitionTypesByGroup['destClass'].str.contains("Wetland")]
  wetlandSummaryTypesDest = wetlandSummaryTypesDest[wetlandSummaryTypesDest['TransitionGroup'].str.contains("Wetland")]
  wetlandSummaryTypesDest = wetlandSummaryTypesDest[~wetlandSummaryTypesDest['TransitionGroup'].str.contains("Wetland->")]
  wetlandSummaryTypesDest = wetlandSummaryTypesDest[wetlandSummaryTypesDest['TransitionType'].str.findall("Wetland").str.len() < 2]
  wetlandSummaryTypesDest['TransitionGroup'] = "->Wetland"

  # # Add in other summary Groups
  otherSummaryTypesSrc = transitionTypesByGroup[~transitionTypesByGroup['srcClass'].str.contains("Wetland")]
  otherSummaryTypesSrc = otherSummaryTypesSrc[~otherSummaryTypesSrc['srcClass'].str.contains("Shore")]
  otherSummaryTypesSrc = otherSummaryTypesSrc[~otherSummaryTypesSrc['srcClass'].str.contains("Water")]
  otherSummaryTypesSrc = otherSummaryTypesSrc[otherSummaryTypesSrc['TransitionGroup'].str.contains("Wetland")]
  otherSummaryTypesSrc[otherSummaryTypesSrc['TransitionGroup'].str.contains("Herb")]["TransitionGroup"] = "Other->Wetland:Herb"
  otherSummaryTypesSrc[otherSummaryTypesSrc['TransitionGroup'].str.contains("For")]["TransitionGroup"] = "Other->Wetland:For"

  otherSummaryTypesDest = transitionTypesByGroup[~transitionTypesByGroup['destClass'].str.contains("Wetland")]
  otherSummaryTypesDest = otherSummaryTypesDest[~otherSummaryTypesDest['destClass'].str.contains("Shore")]
  otherSummaryTypesDest = otherSummaryTypesDest[~otherSummaryTypesDest['destClass'].str.contains("Water")]
  otherSummaryTypesDest = otherSummaryTypesDest[otherSummaryTypesDest['TransitionGroup'].str.contains("Wetland")]
  otherSummaryTypesDest[otherSummaryTypesDest['TransitionGroup'].str.contains("Herb")]["TransitionGroup"] = "Wetland:Herb->Other"
  otherSummaryTypesDest[otherSummaryTypesDest['TransitionGroup'].str.contains("For")]["TransitionGroup"] = "Wetland:For->Other"

  wetlandSummaryTypesByGroup = pd.concat([wetlandSummaryTypesSrc, wetlandSummaryTypesDest, otherSummaryTypesSrc, otherSummaryTypesDest])
  
  # Combine and save to library
  transitionTypesByGroupAll = pd.concat([transitionTypesByGroup, wetlandSummaryTypesByGroup])
  transitionTypesByGroupNoID = transitionTypesByGroupAll[['TransitionType', 'TransitionGroup']]
  transitionTypesByGroupNoID.rename(columns={'TransitionType': 'TransitionTypeID', 'TransitionGroup': 'TransitionGroupID'}, inplace=True) 
  
  return transitionTypesByGroupNoID

# Functions for subscenarios scripts --------------------------------------

def create_subscenario_dir(folder_name, dir_name=CONUS_CARBON_SUBSCENARIOS_DIR):
  """
  Create a subscenario folder in the current directory

  Parameters
  ----------
  folder_name : str
    Name of the subscenario folder to create
  
  Returns
  -------
  None
  """
  full_path = os.path.join(dir_name, folder_name)
  if not os.path.exists(full_path):
      os.mkdir(full_path)

def impute_forest_type_groups(my_datasheet, tertiary_stratum_datasheet):
    
    top_forest_type_group = pd.read_csv(os.path.join(CUSTOM_INTERMEDIATES_DIR, 
                                                    "top_forest_type_group.csv"))
    for stratum in my_datasheet["StratumID"].unique():

        top_forest_type_group.replace({PRIMARY_STRATUM_NAME_FIELD: PRIMARY_STRATUM_IDS}, inplace=True)
        top_forest_type_group_value = top_forest_type_group[
            top_forest_type_group[PRIMARY_STRATUM_NAME_FIELD] == stratum]["Top Forest Type Group"].iloc[0].item()
        top_forest_type_group_name = tertiary_stratum_datasheet[tertiary_stratum_datasheet["ID"] == top_forest_type_group_value]["Name"].item()
        my_datasheet[(my_datasheet["StratumID"] == stratum) &\
                    (my_datasheet["TertiaryStratumID"] == "Imputed")]["TertiaryStratumID"] = top_forest_type_group_name
        my_datasheet.groupby(['StratumID', 'SecondaryStratumID', "TertiaryStratumID", 
                            'StateClassID', 'AgeMin', 'AgeMax']).sum().reset_index()

def create_initial_conditions_data(stateClasses, stateClassToForestDict, 
                                   output_folder=CONUS_CARBON_SUBSCENARIOS_DIR):

  init_cond_num = 0
  init_cond_crosswalk = {"init_cond_num": [],
                         "init_cond_state_class": []}

  datasheetName = "stsim_InitialConditionsNonSpatial"
  myDatasheet = pd.DataFrame({"TotalAmount": [1],
                              "NumCells": [1], 
                              "CalcFromDist": [True]})
  myDatasheet.to_csv(os.path.join(output_folder,
                                  datasheetName,
                                  datasheetName + "_state_class.csv"),
                      index=False)

  for stateClass in stateClasses["Name"]:

    datasheetName = "stsim_InitialConditionsNonSpatialDistribution"
    myDatasheet = pd.DataFrame({"StateClassID": [stateClass],
                                "StratumID": [PRIMARY_STRATUM_VALUE],
                                "SecondaryStratumID": [SECONDARY_STRATUM_VALUE],
                                "TertiaryStratumID": stateClassToForestDict[stateClass],
                                "RelativeAmount": [1]})

    myDatasheet.to_csv(os.path.join(output_folder,
                                    datasheetName,
                                    datasheetName + "_" + str(init_cond_num) + ".csv"),
                        index=False)

    init_cond_crosswalk["init_cond_num"].append(init_cond_num)
    init_cond_crosswalk["init_cond_state_class"].append(stateClass)

    init_cond_num += 1

  pd.DataFrame(init_cond_crosswalk).to_csv(os.path.join(CUSTOM_INTERMEDIATES_DIR,
                                                        "init_cond_crosswalk.csv"),
                                                        mode="w", index=False)

def generate_state_class_initial_conditions(init_cond_crosswalk, session,
                                            library, project,
                                            subscenario_folder_id=None,
                                            output_folder=CONUS_CARBON_SUBSCENARIOS_DIR):
  for i in range(len(init_cond_crosswalk)):

    state_class = init_cond_crosswalk.loc[i, "init_cond_state_class"]
    # if "Forest" in state_class:
    #    state_class = state_class + " [Age 0]"

    scenarioName = "Initial Conditions: Single Cell - {0}".format(state_class)
    myScenario = project.scenarios(scenarioName)

    datasheetName = "stsim_InitialConditionsNonSpatial"
    myDatasheet = pd.read_csv(os.path.join(output_folder,
                                datasheetName,                          
                                datasheetName + "_state_class.csv"))
    myScenario.save_datasheet(datasheetName, myDatasheet)

    datasheetName = "stsim_InitialConditionsNonSpatialDistribution"
    myDatasheet = pd.read_csv(os.path.join(output_folder,
                                datasheetName,                          
                                datasheetName + "_" + str(i) + ".csv"))
    myScenario.save_datasheet(datasheetName, myDatasheet)

    if subscenario_folder_id is not None:
        add_scenario_to_folder(session, library, project,
                                myScenario, subscenario_folder_id)

def create_lulc_transition_pathway_data(transitionTypes, transitionDicts = None,
                                        output_folder=CUSTOM_MERGED_SUBSCENARIOS_DIR):

  transDatasheetFinal = pd.DataFrame()

  if transitionDicts is None:
     all_transitions = transitionTypes.Name
  else:
     if not isinstance(transitionDicts, list):
        transitionDicts = [transitionDicts]
     all_transitions = []
     for transitionDict in transitionDicts:
        for src in transitionDict["FromStateClass"]:
          for dest in transitionDict["ToStateClass"]:
            if src != dest:
              all_transitions.append(src + " -> " + dest)

  for transitionType in all_transitions:

      if "->" not in transitionType:
          continue

      stateClassSource = transitionType.split(' -> ')[0]
      stateClassDest = transitionType.split(' -> ')[1]

      # Transition information
      transDatasheetName = "stsim_Transition"
      transDatasheet = pd.DataFrame({"StateClassIDSource": [stateClassSource],
                                    "StateClassIDDest": [stateClassDest],
                                    "TransitionTypeID": ["LULCC: " + transitionType],
                                    "Probability": [1],
                                    "AgeReset": [None]})
      
      if ("Forest" in stateClassSource) and ("Forest" in stateClassDest):
         transDatasheet["AgeReset"] = "No"
      
      transDatasheetFinal = pd.concat([transDatasheetFinal, transDatasheet])

  transDatasheetFinal.to_csv(os.path.join(output_folder, transDatasheetName,
                                          transDatasheetName + ".csv"),
                                          index = False)

def create_lulc_transition_multiplier_data(transition_years=TRANSITION_YEARS,
                                           start_year=START_YEAR, 
                                           output_folder=CUSTOM_MERGED_SUBSCENARIOS_DIR):

  transPathDatasheet = pd.read_csv(os.path.join(output_folder,
                                               "stsim_Transition", "stsim_Transition.csv"))

  all_transitions = transPathDatasheet["TransitionTypeID"].unique()

  transition_num = 0
  transition_type_crosswalk = {"transition_num": [],
                              "transition_type": [],
                              "transition_age": []}

  for transitionType in all_transitions:

      if "->" not in transitionType:
          continue

      for transitionAge in transition_years:

          transition_type_crosswalk["transition_num"].append(transition_num)
          transition_type_crosswalk["transition_type"].append(transitionType)
          transition_type_crosswalk["transition_age"].append(transitionAge)

          # Transition multipliers
          transMultDatasheetName = "stsim_TransitionMultiplierValue"

          # Set all transitions to 0 at start year
          transMultDatasheet = pd.DataFrame({"TransitionGroupID": all_transitions + " [Type]"})
          transMultDatasheet["Timestep"] = start_year
          transMultDatasheet["Amount"] = 0

          # Add transition multiplier for current transition  
          transitionMultiplier = pd.DataFrame({"Timestep": [start_year + transitionAge],
                                               "TransitionGroupID": [transitionType + " [Type]"],
                                               "Amount": [1]})
          
          transMultDatasheet = pd.concat([transMultDatasheet, transitionMultiplier], ignore_index=True)

          transMultDatasheet.to_csv(os.path.join(output_folder,
                                  transMultDatasheetName,
                                  transMultDatasheetName + "_" + str(transition_num) + ".csv"),
                                  index = False)

          transition_num += 1

  pd.DataFrame(transition_type_crosswalk).to_csv(os.path.join(CUSTOM_INTERMEDIATES_DIR,
                                                             "transition_type_crosswalk.csv"),
                                                              mode="w", index=False)

def generate_lulc_transition_pathways(transition_type_crosswalk, session,
                                      library, project,
                                      folder = CUSTOM_MERGED_SUBSCENARIOS_DIR,
                                      transition_multiplier_folder_id=None):
  
  for i in range(len(transition_type_crosswalk)):

      transMultScnName = "Transition Multipliers: Single Cell - {0} (Year {1})".format(
          transition_type_crosswalk.loc[i, "transition_type"],
          str(START_YEAR + transition_type_crosswalk.loc[i, "transition_age"]))
      transMultScn = project.scenarios(transMultScnName)

      datasheetName = "stsim_TransitionMultiplierValue"
      myDatasheet = pd.read_csv(os.path.join(folder,
                                  datasheetName,                          
                                  datasheetName + "_" + str(i) + ".csv"))
      transMultScn.save_datasheet(datasheetName, myDatasheet)

      if transition_multiplier_folder_id is not None:
          add_scenario_to_folder(session, library, project,
                                 transMultScn, transition_multiplier_folder_id)


def assign_flow_group_membership(flowTypeDF, flowID):
  """
  Assign a flow group membership to a flow type
  
  Parameters
  ----------
  flowTypeDF : pandas.DataFrame
    DataFrame containing flow types and their group memberships
  flowID : int
    ID of the flow type to assign a group membership to
  
  Returns
  -------
  flowGroup : str
    Group membership of the flow type
  """
  flowTypeDF = flowTypeDF[flowTypeDF.FlowTypeID.str.contains(flowID)]
  flowTypeDF["FlowGroupID"] = flowID
  
  return flowTypeDF[["FlowTypeID", "FlowGroupID"]]

def assign_flow_type_multipliers(flowTypesDF, stateClassID):
  """
  Assign flow type multipliers to a flow type
  
  Parameters
  ----------
  flowTypesDF : pandas.DataFrame
    DataFrame containing flow types and their multipliers
  stateClassID : int
    ID of the state class associated with the flow type
    
  Returns
  -------
  flowTypeMultipliers : pandas.DataFrame
    DataFrame containing flow types and their multipliers
  """
  flowTypesDF['StateClassID'] = stateClassID
  flowTypesDF['DistributionType'] = stateClassID + flowTypesDF.FlowTypeID
  flowTypesDF['FlowGroupID'] = flowTypesDF.FlowTypeID + "[Type]"
  flowTypesDF['DistributionFrequencyID'] = "Iteration and Timestep"

  return flowTypesDF[['StateClassID', 'FlowGroupID', 'DistributionType',
                      'DistributionFrequencyID']]

def assign_flow_group_multipliers(flowGroupsDF, stateClassID):
  """
  Assign flow group multipliers to a flow type
  
  Parameters
  ----------
  flowGroupsDF : pandas.DataFrame
    DataFrame containing flow group information
  stateClassID : int
    ID of the state class associated with the flow group
    
  Returns
  -------
  flowGroupMultipliers : pandas.DataFrame
    DataFrame containing flow groups and their multipliers
  """
  flowGroupsDF = flowGroupsDF[flowGroupsDF.FlowGroupID.str.contains("Out")]
  flowGroupsDF['StateClassID'] = stateClassID
  flowGroupsDF['DistributionType'] = stateClassID + flowGroupsDF.FlowGroupID
  flowGroupsDF['DistributionFrequencyID'] = "Iteration and Timestep"

  return flowGroupsDF[['StateClassID', 'FlowGroupID', 'DistributionType',
                        'DistributionFrequencyID']] 

# Functions for building library ----------------------------------------
def create_folder_structure(mySession, myLibrary, myProject):

    folder_name_list = []
    folder_id_list = []

    fname = "Subscenarios"
    subscenario_folder_id = create_project_folder(
        mySession, myLibrary, myProject, folder_name=fname)
    folder_name_list.append(fname)
    folder_id_list.append(subscenario_folder_id)

    fname = "01 Run Control"
    runcontrol_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(runcontrol_folder_id)

    fname = "02 Transition Pathways"
    transpaths_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(transpaths_folder_id)

    fname = "03 Initial Conditions"
    initconds_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(initconds_folder_id)

    fname = "Landscape"
    ls_initconds_folder_id = create_nested_folder(mySession, myLibrary,
        initconds_folder_id, fname)
    folder_name_list.append(fname + " [Initial Conditions]")
    folder_id_list.append(ls_initconds_folder_id)

    fname = "Single Cell"
    sc_initconds_folder_id = create_nested_folder(mySession, myLibrary,
        initconds_folder_id, fname)
    folder_name_list.append(fname + " [Initial Conditions]")
    folder_id_list.append(sc_initconds_folder_id)

    fname = "04 ST-Sim Output Options"
    outoptions_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(outoptions_folder_id)

    fname = "05 Transition Multipliers"
    transmults_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(transmults_folder_id)

    fname = "Landscape"
    ls_transmults_folder_id = create_nested_folder(mySession, myLibrary,
        transmults_folder_id, fname)
    folder_name_list.append(fname + " [Transition Multipliers]")
    folder_id_list.append(ls_transmults_folder_id)

    fname = "Single Cell"
    sc_transmults_folder_id = create_nested_folder(mySession, myLibrary,
        transmults_folder_id, fname)
    folder_name_list.append(fname + " [Transition Multipliers]")
    folder_id_list.append(sc_transmults_folder_id)

    fname = "06 State Attribute Values"
    stateattrvals_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(stateattrvals_folder_id)

    fname = "07 Stocks and Flows"
    stocks_flows_folder_id = create_nested_folder(mySession, myLibrary,
        subscenario_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(stocks_flows_folder_id)

    fname = "01 Flow Pathways"
    flowpaths_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(flowpaths_folder_id)

    fname = "02 Initial Stocks"
    initialstock_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(initialstock_folder_id)

    fname = "03 ST-Sim SF Output Options"
    sfoutoptions_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(sfoutoptions_folder_id)

    fname = "04 ST-Sim SF Output Filters"
    sfoutfilters_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(sfoutfilters_folder_id)

    fname = "05 Stock Group Membership"
    stockgroup_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(stockgroup_folder_id)

    fname = "06 Flow Group Membership"
    flowgroup_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(flowgroup_folder_id)

    fname = "07 Flow Multipliers"
    flowmults_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(flowmults_folder_id)

    fname = "08 Flow Order"
    floworder_folder_id = create_nested_folder(mySession, myLibrary,
        stocks_flows_folder_id, fname)
    folder_name_list.append(fname)
    folder_id_list.append(floworder_folder_id)

    fname = "Single Cell Scenarios"
    sc_scenario_folder_id = create_project_folder(
        mySession, myLibrary, myProject, folder_name=fname)
    folder_name_list.append(fname)
    folder_id_list.append(sc_scenario_folder_id)

    fname = "Base"
    sc_base_folder_id = create_nested_folder(mySession, myLibrary,
        sc_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Single Cell]")
    folder_id_list.append(sc_base_folder_id)

    fname = "LULC Change"
    sc_lulc_folder_id = create_nested_folder(mySession, myLibrary,
        sc_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Single Cell]")
    folder_id_list.append(sc_lulc_folder_id)

    fname = "No LULC Change"
    sc_nolulc_folder_id = create_nested_folder(mySession, myLibrary,
        sc_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Single Cell]")
    folder_id_list.append(sc_nolulc_folder_id)

    fname = "Init C Stock Equilibrium"
    eqm_scenario_folder_id = create_nested_folder(mySession, myLibrary, 
        sc_nolulc_folder_id, fname)
    folder_name_list.append(fname + " [No LULC; Single Cell]")
    folder_id_list.append(eqm_scenario_folder_id)

    fname = "Init C Stock 0"
    init0_scenario_folder_id = create_nested_folder(mySession, myLibrary, 
        sc_nolulc_folder_id, fname)
    folder_name_list.append(fname + " [No LULC; Single Cell]")
    folder_id_list.append(init0_scenario_folder_id)

    fname = "Spinup"
    sc_spinup_folder_id = create_nested_folder(mySession, myLibrary,
        sc_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Single Cell]")
    folder_id_list.append(sc_spinup_folder_id)
    
    fname = "Landscape Scenarios"
    ls_scenario_folder_id = create_project_folder(
        mySession, myLibrary, myProject, folder_name=fname)
    folder_name_list.append(fname)
    folder_id_list.append(ls_scenario_folder_id)

    fname = "Base"
    ls_base_folder_id = create_nested_folder(mySession, myLibrary,
        ls_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Landscape]")
    folder_id_list.append(ls_base_folder_id)

    fname = "Full Resolution 2001-2022"
    ls_fullres_folder_id = create_nested_folder(mySession, myLibrary,
        ls_scenario_folder_id, fname)
    folder_name_list.append(fname + " [Landscape]")
    folder_id_list.append(ls_fullres_folder_id)

    folder_ids = pd.DataFrame({"folder_name": folder_name_list,
                               "folder_id": folder_id_list})
    folder_ids.to_csv(os.path.join(CUSTOM_INTERMEDIATES_DIR,
                                   "folder_ids.csv"), index=False)
    
def retrieve_folder_id(name):
    folder_ids = pd.read_csv(os.path.join(CUSTOM_INTERMEDIATES_DIR, "folder_ids.csv"))
    folder_id = str(folder_ids[folder_ids.folder_name == name].folder_id.iloc[0])
    return folder_id

def list_folders_in_library(session, library):
    """
    List folders in a library

    Parameters
    ----------
    session : pysyncrosim.Session
        Session object
    library : pysyncrosim.Library
        Library object

    Returns
    -------
    None.
    """
    command = "\"" + os.path.join(session.location, "SyncroSim.Console.exe\"") \
      + " --list --folders --lib=\"" + library.location + "\" --csv"
    out = subprocess.run(command, stdout=subprocess.PIPE, shell=True)
    out = out.stdout.decode("utf-8")
    out = pd.read_csv(io.StringIO(out))

    return out

# Functions for extracting results ----------------------------------------
def convert_stock_outputs_to_sav(myProject, scenarioName, initial_stock_data, 
                                 spinup_end_year=2001):
    """
    Convert stock outputs to State Attribute Values

    Parameters
    ----------
    myProject : pysyncrosim.Project
        Project object
    scenarioName : str
        Name of the scenario to extract results from
    initial_stock_data : pandas.DataFrame
        DataFrame containing initial stock values

    Returns
    -------
    myDatasheet : pandas.DataFrame
        DataFrame containing State Attribute Values
    """
    result_id = get_result_scenario_id(myProject, scenarioName)
    result_scenario = myProject.scenarios(sid = result_id)
    stock_outputs = result_scenario.datasheets(name = "stsimsf_OutputStock")

    stock_outputs = stock_outputs[stock_outputs["Timestep"] == spinup_end_year]
    stock_outputs = stock_outputs.drop(columns = ["Timestep", "Iteration"])

    # Create SAV datasheet
    myDatasheet = stock_outputs.copy()
    myDatasheet["StockGroupID"] = myDatasheet[
        "StockGroupID"].str.replace(" [Type]", "", regex=False)
    myDatasheet = myDatasheet.rename(columns = {"StockGroupID": "StockTypeID",
                                                    "Amount": "Value"})
    myDatasheet = pd.merge(myDatasheet, initial_stock_data, on = ["StockTypeID"])
    myDatasheet = myDatasheet.drop(columns = ["StockTypeID"])
    myDatasheet = myDatasheet[['StateClassID', 'StateAttributeTypeID', 'Value']]

    return myDatasheet

def retrieve_generate_multipliers_outputs(myProject,
                                          result_scenario_ids,
                                          SAV_datasheet_name="stsim_StateAttributeValue",
                                          FM_datasheet_name="stsimsf_FlowMultiplier",
                                          FP_datasheet_name="stsimsf_FlowPathway"):
  """
  Retrieve the outputs from the Generate Multipliers tool

  Parameters
  ----------
  myProject : ps.Project
    Project object
  result_scenario_ids : list
    List of scenario IDs to retrieve results from
  SAV_datasheet_name : str
    Name of the State Attribute Value datasheet
  FM_datasheet_name : str
    Name of the Flow Multiplier datasheet
  FP_datasheet_name : str
    Name of the Flow Pathway datasheet
  
  Returns
  -------
  data : list of pandas.DataFrames
    List of DataFrames containing the results from the CBM-CFS3 Model run
  """
  for sid in result_scenario_ids:
      myResultScenario = myProject.scenarios(sid=sid)
      sav = myResultScenario.datasheets(name = SAV_datasheet_name)
      fm = myResultScenario.datasheets(name = FM_datasheet_name)
      fp = myResultScenario.datasheets(name = FP_datasheet_name)
      if sid == result_scenario_ids[0]:
          sav_all = sav
          fm_all = fm
          fp_all = fp
      else:
          sav_all = pd.concat([sav_all, sav])
          fm_all = pd.concat([fm_all, fm])
          fp_all = fp_all.merge(fp, how="outer")

  return [sav_all, fm_all, fp_all]

def convert_output_for_forecast(data):
    for i in range(len(data)):
        stateClassColumn = "FromStateClassID" \
            if "FromStateClassID" in data[i].columns.tolist() else \
                "StateClassID"
        tertiaryStratumColumn = "FromTertiaryStratumID" \
            if "FromTertiaryStratumID" in data[i].columns.tolist() \
                else "TertiaryStratumID"
        data[i][tertiaryStratumColumn] = data[i][stateClassColumn].str.split(":", expand = True)[1]
        data[i][tertiaryStratumColumn] = data[i][tertiaryStratumColumn].str.replace("Palustrine Forested", "")
        data[i][stateClassColumn] = data[i][stateClassColumn].str.split(":", expand = True)[0]
        data[i][stateClassColumn] = np.where(data[i][stateClassColumn] == "Forest",
                                             STATE_CLASS_FOREST, data[i][stateClassColumn])
        data[i][stateClassColumn] = np.where(data[i][stateClassColumn] == "Wetland",
                                             STATE_CLASS_WET_FOREST,
                                              data[i][stateClassColumn])
        
        # Add estuarine forested state class (same as palustrine forested)
        data2 = data[i].copy()
        data2 = data2[data2[stateClassColumn] == STATE_CLASS_WET_FOREST]
        data2[stateClassColumn] = STATE_CLASS_WET_FOREST_EST
        data[i] = pd.concat([data[i], data2])

    return data

def save_spinup_flow_results(data, origin, ds_names, csv_suffix,
  transition_groups, folder=CUSTOM_CARBON_SUBSCENARIOS_DIR):
  """
  Save the results from the CBM-CFS3 Model run

  Parameters
  ----------
  data : list of pandas.DataFrames
    List of DataFrames containing the results from the CBM-CFS3 Model run
  origin : str
    Name of originating transition (e.g. "_Fire" or "_Harvest")
  ds_names : list
    List of datasheet names
  csv_suffix : str
    Suffix to add to the CSV filename
  transition_groups : list
    List of transition groups to include in output
  """

  for i in range(0, len(data)):

      folderpath = os.path.join(folder, "Forecast Model", ds_names[i])

      if not os.path.exists(folderpath):
          os.makedirs(folderpath)
          
      filename = ds_names[i] + origin + csv_suffix + ".csv"
      filepath = os.path.join(folderpath, filename)

      if "TransitionGroupID" in data[i].columns:
          data[i] = data[i][data[i].TransitionGroupID.isin(transition_groups)]

      data[i].to_csv(filepath,index=False)

# Legacy functions below -------------------------------------------------------

# Compute transition matrix
# def computeTransitionMatrix(source, destination, zones, outputDir):
#   options(scipen=999) # To suppress scientific notation (GRASS does not recognize scientific notation)
  
#   # Get maximum values
#   # Destination
#   execGRASS('r.stats', input=destination, output=os.path.join(outputDir, 'Tabular', 'DestinationIDs.csv'),
#              flags=c('n', 'overwrite'))
#   maxDestination = pd.read_csv(os.path.join(
#     outputDir, 'Tabular', 'DestinationIDs.csv'), header=None).V1.max()

#   maxDestination <- floor(log10(maxDestination)) + 1 # Get number of digits
#   unlink(file.path(outputDir, 'Tabular', 'DestinationIDs.csv'))
  
#   # Zones
#   execGRASS('r.stats', input=zones, output=file.path(outputDir, 'Tabular', 'ZoneIDs.csv'), flags=c('n', 'overwrite'))
#   maxZone <- read.csv(file.path(outputDir, 'Tabular', 'ZoneIDs.csv'), header=F) %>%
#     pull(V1) %>%
#     max()
#   maxZone <- floor(log10(maxZone)) + 1 # Get number of digits
#   unlink(file.path(outputDir, 'Tabular', 'ZoneIDs.csv'))
  
#   # Overlay rasters
#   execGRASS('r.mapcalc', expression=paste('transition = ', 10^maxDestination * 10^maxZone, '*', source, '+', 10^maxZone, '*', destination, '+', zones), flags='overwrite')
  
#   # Get number of cells per category
#   execGRASS('r.stats', input='transition', output=file.path(outputDir, 'Tabular', 'Transition.csv'), separator=',', c('a', 'c', 'overwrite'))
  
#   # Format output
#   transitionMatrix <- read.csv(file.path(outputDir, 'Tabular', 'Transition.csv'), header=F) %>%
#     rename(cat = V1, Area = V2, NCells = V3) %>%
#     filter(!cat == "*") %>%
#     mutate(Zone = substr(cat, start=nchar(cat)-(maxZone-1), stop=nchar(cat)),
#            Source = substr(cat, start=1, stop=nchar(cat)-maxZone-maxDestination),
#            Destination = substr(cat, start=nchar(cat)-maxZone-(maxDestination-1), stop=nchar(cat)-maxZone)) %>%
#     mutate(Zone = as.integer(Zone),
#            Source = as.integer(Source),
#            Destination = as.integer(Destination)) %>%
#     select(c(Zone, Source, Destination, NCells, Area))
  
#   # Remove intermediate products
#   execGRASS('g.remove', type='raster', name='transition', 'f')
#   unlink(file.path(outputDir, 'Tabular', 'Transition.csv'))
  
#   # Return matrix
#   return transitionMatrix
