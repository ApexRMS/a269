## a296
## Sarah Chisholm (ApexRMS)
## June 30 2022
##
## Build cavity nests st-simsf library

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(rsyncrosim)
library(tidyverse)
library(terra)

# Define directories
tabularDataDir <- file.path("Data", "Tabular")
libraryDir <- "Libraries"
modelInputsDir <- "Model-Inputs"

# Connect R to SyncroSim
mySession <- session()

## Create Library ----
myLibrary <- ssimLibrary(name = file.path(libraryDir, "ECCC cavity nests model"),
                         package = "stsim",
                         session = mySession,
                         addon = "stsimsf",
                         overwrite = TRUE)

# Open the default project
myProject <- rsyncrosim::project(ssimObject = myLibrary, project = "Definitions")

## Add Definitions (Project-scope Datasheets) ----
# Strata
# Primary Stratum
primaryStratumValues <- data.frame(Name = c("BGxw", "IDFdk", "IDFxm", "SBPSmk", "SBSdw"),
                                   ID = c(1, 2, 3, 4, 5),
                                   Color = c("255,172,254,1", "255,0,191,0", "255,0,128,0", "255,0,121,121", "255,0,83,70"))

primaryStratum <- datasheet(ssimObject = myProject, 
                            name = "stsim_Stratum",
                            optional = TRUE) %>% 
  addRow(value = primaryStratumValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject,
              data = primaryStratum,
              name = "stsim_Stratum")

# States
# State Label X
stateLabelXValues <- data.frame(Name = c("Urban", "Water", "Forest", "Cropland", "Grassland", "Wetland", "Other"))

stateLabelX <- datasheet(ssimObject = myProject,
                         name = "stsim_StateLabelX") %>% 
  addRow(value = stateLabelXValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateLabelX,
              name = "stsim_StateLabelX")

# State Label Y
stateLabelYValues <- data.frame(Name = c("All", "Aspen", "Fir", "Pine", "Spruce", "Other"))

stateLabelY <- datasheet(ssimObject = myProject,
                         name = "stsim_StateLabelY") %>% 
  addRow(value = stateLabelYValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateLabelY,
              name = "stsim_StateLabelY")

# State Class
stateClassValues <- data.frame(Name = c("Urban:All", "Water:All", "Forest:Other", "Forest:Aspen", "Forest:Pine", "Forest:Fir", "Forest:Spruce", "Cropland:All", "Grassland:All", "Wetland:All", "Other:All"),
                               StateLabelXID = c("Urban", "Water", "Forest", "Forest", "Forest", "Forest", "Forest", "Cropland", "Grassland", "Wetland", "Other"),
                               StateLabelYID = c("All", "All", "Other", "Aspen", "Pine", "Fir", "Spruce", "All", "All", "All", "All"),
                               ID = c(20, 30, 40, 41, 42, 43, 44, 50, 60, 70, 90),
                               Color = c("255,0,0,0", "255,0,74,149", "255,0,53,0", "255,53,255,53", "255,0,185,0", "255,0,117,0", "255,1,78,39", "255,255,255,0", "255,134,204,2", "255,0,193,116", "255,91,46,0"))

stateClass <- datasheet(ssimObject = myProject,
                        name = "stsim_StateClass",
                        optional = TRUE,
                        empty = TRUE) %>% 
  addRow(value = stateClassValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateClass,
              name = "stsim_StateClass")

# Advanced
# Stock Type
stockType <- datasheet(ssimObject = myProject,
                                name = "stsimsf_StockType") %>% 
  addRow(value = "Aspen Cover") %>% 
  addRow(value = "Diameter")

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stockType,
              name = "stsimsf_StockType")

# Flow Type
flowType <- datasheet(ssimObject = myProject,
                       name = "stsimsf_FlowType") %>% 
  addRow(value = "Aspen Cover Growth") %>% 
  addRow(value = "Diameter Growth")

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = flowType,
              name = "stsimsf_FlowType")

# Terminology
terminology <- datasheet(ssimObject = myProject,
                         name = "stsim_Terminology",
                         optional = TRUE) %>% 
  mutate(AmountUnits = str_replace(AmountUnits, pattern = "Acres", replacement = "Hectares")) %>% 
  mutate(PrimaryStratumLabel = str_replace(PrimaryStratumLabel, pattern = "Primary Stratum", replacement = "BEC Variant"))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = terminology,
              name = "stsim_Terminology")

## Create Scenario (Scenario-scope Datasheets) ----
myScenario <- scenario(ssimObject = myProject,
                       scenario = "Spatial - Aspen Cover & Diameter Growth")

# Run Control
# -zzz: IsSpatial is set to NA, not recognizing "Yes"
runControl <- datasheet(ssimObject = myScenario,
                        name = "stsim_RunControl") %>% 
  addRow(value = list(MinimumIteration = 1, MaximumIteration = 1, 
                      MinimumTimestep = 2016, MaximumTimestep = 2046, IsSpatial = "Yes")) 

# Save datasheet to library
saveDatasheet(ssimObject = myScenario, 
              data = runControl,
              name = "stsim_RunControl")

# Deterministic Transitions
deterministicTransitionValues <- data.frame(StratumIDSource = rep(c("BGxw", "IDFdk", "IDFxm", "SBPSmk", "SBSdw"), each = 5),
                                            StateClassIDSource = rep(c("Forest:Other", "Forest:Aspen", "Forest:Pine", "Forest:Fir", "Forest:Spruce"), times = 5),
                                            Location = rep(c("C1", "A1", "A2", "B1", "B2"), times = 5))
  
deterministicTransitions <- datasheet(ssimObject = myScenario,
                                      name = "stsim_DeterministicTransition",
                                      optional = TRUE) %>% 
  addRow(value = deterministicTransitionValues)  

# Save datasheet to library
saveDatasheet(ssimObject = myScenario, 
              data = deterministicTransitions,
              name = "stsim_DeterministicTransition")

# Transition Pathways
# transitionPathwayValues <- 
# 
# transitionPathways <- datasheet(ssimObject = myScenario,
#                                 name = "stsim_Transition",
#                                 optional = TRUE) %>% 
#   addRow(value = transitionPathwayValues)

# Initial Conditions
# Create a list of the input tif files
initialConditionsSpatialValues <- list(StratumFileName = file.path(getwd(), modelInputsDir, "primary-stratum.tif"), 
                                       StateClassFileName = file.path(getwd(), modelInputsDir, "state-class.tif"), 
                                       AgeFileName = file.path(getwd(), modelInputsDir, "age.tif")) 

initialConditionsSpatial <- datasheet(ssimObject = myScenario,
                                      name = "stsim_InitialConditionsSpatial") %>% 
  addRow(value = initialConditionsSpatialValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario, 
              data = initialConditionsSpatial,
              name = "stsim_InitialConditionsSpatial")

# Output Options
# Tabular
outputOptionValues = data.frame(SummaryOutputSC = "Yes",
                                 SummaryOutputSCTimesteps = 1, 
                                 SummaryOutputSCAges = "Yes",
                                 SummaryOutputSA = "Yes",
                                 SummaryOutputSATimesteps = 1,
                                 SummaryOutputSAAges = "Yes")

outputOptions <- datasheet(ssimObject = myScenario,
                           name = "stsim_OutputOptions") %>% 
  addRow(value = outputOptionValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario, 
              data = outputOptions,
              name = "stsim_OutputOptions")

# # Spatial
# outputOptionsSpatialValues = data.frame(RasterOutputSC = "Yes",
#                                         RasterOutputSCTimesteps = 1, 
#                                         RasterOutputAge = "Yes",
#                                         RasterOutputAgeTimesteps = 1)
# 
# outputOptionsSpatial <- datasheet(ssimObject = myScenario,
#                            name = "stsim_OutputOptionsSpatial") %>% 
#   addRow(value = outputOptionsSpatialValues)
# 
# # Save datasheet to library
# saveDatasheet(ssimObject = myScenario, 
#               data = outputOptionsSpatial,
#               name = "stsim_OutputOptionsSpatial")

# Advanced
# Stocks and Flows - Flow Pathway Diagram
flowPathwayDiagramValues <- data.frame(StockTypeID = c("Aspen Cover", "Diameter"),
                                       Location = c("A1", "B1"))

flowPathwayDiagram <- datasheet(ssimObject = myScenario,
                          name = "stsimsf_FlowPathwayDiagram",
                          optional = TRUE) %>% 
  addRow(value = flowPathwayDiagramValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario,
              data = flowPathwayDiagram,
              name = "stsimsf_FlowPathwayDiagram")

# Stocks and Flows - Flow Pathways
flowPathwayValues <- data.frame(ToStockTypeID = c("Aspen Cover", "Diameter"),
                                FlowTypeID = c("Aspen Cover Growth", "Diameter Growth"),
                                Multiplier = c(1,1))

flowPathways <- datasheet(ssimObject = myScenario,
                          name = "stsimsf_FlowPathway",
                          optional = TRUE) %>% 
  addRow(value = flowPathwayValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario,
              data = flowPathways,
              name = "stsimsf_FlowPathway")

# Stocks and Flows - Initial Stocks
# Create a list of the input tif files
initialStockValues <- data.frame(StockTypeID = c("Aspen Cover", "Diameter"),
                                 RasterFileName = c(file.path(getwd(), modelInputsDir, "initial-aspen-cover.tif"),
                                                    file.path(getwd(), modelInputsDir, "initial-diameter.tif"))) 

initialStocks <- datasheet(ssimObject = myScenario,
                                      name = "stsimsf_InitialStockSpatial") %>% 
  addRow(value = initialStockValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario, 
              data = initialStocks,
              name = "stsimsf_InitialStockSpatial")

# Stocks and Flows - Flow Multipliers
# zzz: Remove duplicate rows, add AgeMin column
flowMultiplierValues <- read_csv(file.path(tabularDataDir, "flow-multipliers.csv")) %>% 
  mutate(species = case_when(species == "Douglas Fir" ~ "Forest:Fir",
                             species == "Lodgepole Pine" ~ "Forest:Pine",
                             species == "Trembling Aspen" ~ "Forest:Aspen",
                             species == "Spruce Hybrid" ~ "Forest:Spruce"),
         bec = case_when(bec == "Bunch Grass:warm" ~ "BGxw",
                         bec == "Interior Douglas-fir:dry cool" ~ "IDFdk",
                         bec == "Interior Douglas-fir:mild" ~ "IDFxm",
                         bec == "Sub-Boreal Pine - Spruce:moist cool" ~ "SBPSmk",
                         bec == "Sub-Boreal Spruce:dry warm" ~ "SBSdw")) %>% 
  pivot_longer(cols = deltaAspen:deltaQmd,
               names_to = "FlowGroupID",
               values_to = "Value") %>% 
  mutate(FlowGroupID = case_when(FlowGroupID == "deltaAspen" ~ "Aspen Cover Growth [Type]",
                                 FlowGroupID == "deltaQmd" ~ "Diameter Growth [Type]"),
         Value = round(Value, digits = 4)) %>% 
  rename(StratumID = bec, 
         StateClassID = species,
         AgeMax = age) 

# %>% 
#   group_by(FlowGroupID) %>% 
#   arrange(AgeMax, by_group = TRUE)

flowMultipliers <- datasheet(ssimObject = myScenario,
                             name = "stsimsf_FlowMultiplier",
                             optional = TRUE) %>% 
  addRow(value = flowMultiplierValues)

# Save datasheet to library
saveDatasheet(ssimObject = myScenario,
              data = flowMultipliers,
              name = "stsimsf_FlowMultiplier")
