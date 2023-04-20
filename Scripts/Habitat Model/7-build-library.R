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
spatialDataDir <- file.path("Data", "Spatial")
tabularModelInputsDir <- file.path("Model-Inputs", "Tabular")
spatialModelInputsDir <- file.path("Model-Inputs", "Spatial")
libraryDir <- "Libraries"

# Connect R to SyncroSim
mySession <- session()

## Create Library ----
myLibrary <- ssimLibrary(name = file.path(libraryDir, "ECCC cavity nests model"),
                         package = "stsim",
                         session = mySession,
                         addon = "stsimsf",
                         overwrite = TRUE)

# Connect to existing library
# myLibrary <- ssimLibrary(name = file.path(libraryDir, "ECCC cavity nests model"))

# Open the default project
myProject <- rsyncrosim::project(ssimObject = myLibrary, project = "Definitions")

## Project-scope Datasheets ----
# zzz: Add 'enable multi-processing' to library (core datasheet?)
### Strata ----
## Primary Stratum
primaryStratumValues <- data.frame(
  Name = c("BGxw", "IDFdk", "IDFxm", "SBPSmk", "SBSdw"),
  ID = c(1, 2, 3, 4, 5),
  Color = c("255,172,254,1", "255,0,191,0", "255,0,128,0", 
            "255,0,121,121", "255,0,83,70"),
  Description = c("Bunch Grass: very dry warm", 
                  "Interior Douglas Fir: dry cool", 
                  "Interior Douglas Fir: very dry mild", 
                  "Sub-Boreal Pine-Spruce: moist cool", 
                  "Sub-Boreal Spruce: dry warm"))

primaryStratum <- datasheet(ssimObject = myProject, 
                            name = "stsim_Stratum",
                            optional = TRUE) %>% 
  addRow(value = primaryStratumValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject,
              data = primaryStratum,
              name = "stsim_Stratum")

## Secondary Stratum 
secondaryStratumValues <- data.frame(
  Name = c("Protected", "Private", "Public"),
  ID = c(1, 2, 3))

secondaryStratum <- datasheet(ssimObject = myProject,
                              name = "stsim_SecondaryStratum", 
                              optional = TRUE) %>% 
  addRow(value = secondaryStratumValues)

# Save datasheet to library
saveDatasheet(ssimObject = myProject,
              data = secondaryStratum,
              name = "stsim_SecondaryStratum")

### States ----
## State Label X
stateLabelXValues <- data.frame(
  Name = c("Developed", "Water", "Forest", "Cropland", 
           "Grassland", "Wetland", "Other"))

stateLabelX <- datasheet(ssimObject = myProject,
                         name = "stsim_StateLabelX") %>% 
  addRow(value = stateLabelXValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateLabelX,
              name = "stsim_StateLabelX")

## State Label Y
stateLabelYValues <- data.frame(
  Name = c("All", "Aspen", "Fir", "Pine", "Spruce", "Unknown"))

stateLabelY <- datasheet(ssimObject = myProject,
                         name = "stsim_StateLabelY") %>% 
  addRow(value = stateLabelYValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateLabelY,
              name = "stsim_StateLabelY")

## State Class
stateClassValues <- data.frame(
  Name = c("Developed:All", "Water:All", "Forest:Unknown", "Forest:Aspen", 
           "Forest:Pine", "Forest:Fir", "Forest:Spruce", "Cropland:All", 
           "Grassland:All", "Wetland:All", "Other:All"),
  StateLabelXID = c("Developed", "Water", "Forest", "Forest", "Forest", "Forest", 
                    "Forest", "Cropland", "Grassland", "Wetland", "Other"),
  StateLabelYID = c("All", "All", "Unknown", "Aspen", "Pine", "Fir", "Spruce", 
                    "All", "All", "All", "All"),
  ID = c(20, 30, 40, 41, 42, 43, 44, 50, 60, 70, 90),
  Color = c("255,0,0,0", "255,0,74,149", "255,0,53,0", "255,53,255,53", 
            "255,0,185,0", "255,0,117,0", "255,1,78,39", "255,255,255,0", 
            "255,134,204,2", "255,0,193,116", "255,141,141,141"))

stateClass <- datasheet(ssimObject = myProject,
                        name = "stsim_StateClass",
                        optional = TRUE,
                        empty = TRUE) %>% 
  addRow(value = stateClassValues) 

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateClass,
              name = "stsim_StateClass")

### Transitions ----
## Transition Type
transitionType <- datasheet(ssimObject = myProject,
                            name = "stsim_TransitionType",
                            optional = TRUE, 
                            empty = TRUE) %>% 
  addRow(value = data.frame(Name = c("Disturbance: Fire", 
                                     "Disturbance: Clearcut",
                                     "LULC: -> Developed",
                                     "LULC: -> Cropland")))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = transitionType,
              name = "stsim_TransitionType")

## Transition Group
transitionGroup <- datasheet(ssimObject = myProject,
                            name = "stsim_TransitionGroup",
                            optional = TRUE, 
                            empty = TRUE) %>% 
  addRow(value = data.frame(Name = c("LULC Disturbances", 
                                     "Replacement Disturbances")))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = transitionGroup,
              name = "stsim_TransitionGroup")

## Transition Type by Group
transitionTypeGroup <- datasheet(
  ssimObject = myProject,
  name = "stsim_TransitionTypeGroup",
  optional = TRUE, 
  empty = TRUE) %>%
  addRow(value = data.frame(
    TransitionTypeID = c("Disturbance: Fire", 
                         "Disturbance: Clearcut",
                         "LULC: -> Developed",
                         "LULC: -> Cropland"),
    TransitionGroupID = rep(c("Replacement Disturbances", 
                              "LULC Disturbances"), each = 2)))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = transitionTypeGroup,
              name = "stsim_TransitionTypeGroup")

## Transition Multiplier Type
transitionMultiplierType <- datasheet(ssimObject = myProject,
                                      name = "stsim_TransitionMultiplierType",
                                      optional = TRUE, 
                                      empty = TRUE) %>% 
  addRow(value = data.frame(Name = c("Base Probability", "Variability")))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = transitionMultiplierType,
              name = "stsim_TransitionMultiplierType")

## Transition Multiplier Type
transitionMultiplierType <- datasheet(ssimObject = myProject,
                            name = "stsim_TransitionMultiplierType",
                            optional = TRUE, 
                            empty = TRUE) %>% 
  addRow(value = data.frame(Name = c("Base Probability", "Variability")))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = transitionMultiplierType,
              name = "stsim_TransitionMultiplierType")

### Advanced ----
#### State Attribute Type ----
stateAttributeType <- datasheet(
  ssimObject = myProject,
  name = "stsim_StateAttributeType",
  empty = TRUE) %>% 
  addRow(value = data.frame(
    Name = c("Aspen Cover Growth Rate", 
             "Diameter Growth Rate",
             "Non Spatial Initial Aspen Cover",
            # "Non Spatial Initial Diameter",
             "Post LULC",
             "Post Replacement Aspen Cover (%)",
             "Post Replacement Diameter (cm)")))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stateAttributeType,
              name = "stsim_StateAttributeType")

#### Distributions ----
distributions <- datasheet(
  ssimObject = myProject,
  name = "corestime_DistributionType") %>% 
  addRow(value = data.frame(Name = c("Historic Fire",
                                     "Historic Logging",
                                     "Historic LULC: -> Cropland",
                                     "Historic LULC: -> Developed")))

saveDatasheet(ssimObject = myProject,
              data = distributions,
              name = "corestime_DistributionType", 
              append = FALSE)

#### External Variables ----
externalVariables <- datasheet(
  ssimObject = myProject,
  name = "corestime_ExternalVariableType") %>% 
  addRow(value = data.frame(Name = c("Historic Logging Years",
                                     "Historic LULC 5 Year Period")))

saveDatasheet(ssimObject = myProject,
              data = externalVariables,
              name = "corestime_ExternalVariableType", 
              append = FALSE)

#### Stock Type ----
stockType <- datasheet(ssimObject = myProject,
                                name = "stsimsf_StockType") %>% 
  addRow(value = "Aspen Cover (%)") %>% 
  addRow(value = "Diameter (cm)")

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = stockType,
              name = "stsimsf_StockType")

#### Flow Type ----
flowType <- datasheet(ssimObject = myProject,
                       name = "stsimsf_FlowType") %>% 
  addRow(value = "Aspen Cover Growth") %>% 
  addRow(value = "Diameter Growth") %>% 
  addRow(value = "LULC") %>% 
  addRow(value = "Replacement (Aspen Cover)") %>% 
  addRow(value = "Replacement (Diameter)")

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = flowType,
              name = "stsimsf_FlowType")

### Terminology ----
terminology <- datasheet(ssimObject = myProject,
                         name = "stsim_Terminology",
                         optional = TRUE) %>% 
  mutate(AmountUnits = str_replace(AmountUnits, pattern = "Acres", replacement = "Hectares"),
         PrimaryStratumLabel = str_replace(PrimaryStratumLabel, pattern = "Primary Stratum", replacement = "BEC Variant"),
         SecondaryStratumLabel = str_replace(SecondaryStratumLabel, pattern = "Secondary Stratum", replacement = "Ownership"),
         TimestepUnits = str_replace(TimestepUnits, pattern = "Timestep", replacement = "Year"))

# Save datasheet to library
saveDatasheet(ssimObject = myProject, 
              data = terminology,
              name = "stsim_Terminology")

# Memory management
rm(primaryStratumValues, primaryStratum, secondaryStratumValues, 
   secondaryStratum, stateLabelXValues, stateLabelX, stateLabelYValues, 
   stateLabelY, stateClassValues, stateClass, transitionType, transitionGroup,
   transitionTypeGroup, transitionMultiplierType, stateAttributeType,
   distributions, externalVariables, stockType, flowType, terminology)

## Scenario-scope Datasheets ----
## Create Sub-Scenarios (dependencies) for each scenario-scoped datasheet
### Run Control ----
#### Spatial ----
# Create run control sub scenario
runControlSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Run Control Spatial, 2016 to 2046, 1 Iteration")

# Populate datasheet
runControlDatasheet <- datasheet(
  ssimObject = runControlSubScenario,
  name = "stsim_RunControl",
  empty = TRUE) %>% 
  addRow(value = list(MinimumIteration = 1, 
                      MaximumIteration = 1, 
                      MinimumTimestep = 2016, 
                      MaximumTimestep = 2046,
                      IsSpatial = "TRUE")) 

# Save datasheet to library
saveDatasheet(ssimObject = runControlSubScenario, 
              data = runControlDatasheet,
              name = "stsim_RunControl")

# Memory management
rm(runControlSubScenario, runControlDatasheet)

#### Non-Spatial ----
# Create run control sub scenario
runControlSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Run Control Non-Spatial, 250 yr, 40 it")

# Populate datasheet
runControlDatasheet <- datasheet(
  ssimObject = runControlSubScenario,
  name = "stsim_RunControl") %>% 
  addRow(value = list(MinimumIteration = 1, 
                      MaximumIteration = 40, 
                      MinimumTimestep = 0, 
                      MaximumTimestep = 250,
                      IsSpatial = "FALSE")) 

# Save datasheet to library
saveDatasheet(ssimObject = runControlSubScenario, 
              data = runControlDatasheet,
              name = "stsim_RunControl")

# Memory management
rm(runControlSubScenario, runControlDatasheet)

### Transition Pathways ----
## Deterministic Transitions
# Define deterministic transitions
deterministicTransitionValues <- data.frame(
  StateClassIDSource = c("Forest:Aspen", "Grassland:All", "Water:All",
                         "Forest:Fir",  "Wetland:All", "Other:All", "Forest:Spruce",
                         "Cropland:All", "Forest:Pine", "Developed:All", "Forest:Unknown"),
  Location = c("A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "D1", "D2", "E1"))

# Define probabilistic transitions
probabilisticTransitionValues <- data.frame(
  StateClassIDSource = c(rep(c("Forest:Unknown", "Forest:Aspen", "Forest:Pine", "Forest:Fir", "Forest:Spruce"), times = 2), 
                         rep(c("Forest:Unknown", "Forest:Aspen", "Forest:Pine", "Forest:Fir", "Forest:Spruce", "Grassland:All", "Wetland:All"), times = 2)),
  
  
  StateClassIDDest = c(rep(c("Forest:Unknown", "Forest:Aspen", "Forest:Pine", "Forest:Fir", "Forest:Spruce"), times = 2),
                       rep(c("Cropland:All", "Developed:All"), each = 7)),
  TransitionTypeID = c(rep(c("Disturbance: Fire", "Disturbance: Clearcut"), each = 5),
                       rep(c("LULC: -> Cropland", "LULC: -> Developed"), each = 7)),
  Probability = 1) %>%
  mutate(AgeMin = case_when(TransitionTypeID == "Disturbance: Clearcut" ~ 60))

# Create transition pathway sub scenario
transitionPathwaySubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Pathways")

# Create deterministic transitions datasheet
deterministicTransitionsDatasheet <- datasheet(
  ssimObject = transitionPathwaySubScenario,
  name = "stsim_DeterministicTransition",
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(value = deterministicTransitionValues)  

# Create probabilistic transitions datasheet
probabilisticTransitionsDatasheet <- datasheet(
  ssimObject = transitionPathwaySubScenario,
  name = "stsim_Transition",
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(value = probabilisticTransitionValues) 

# Save datasheet to library
saveDatasheet(ssimObject = transitionPathwaySubScenario, 
              data = deterministicTransitionsDatasheet,
              name = "stsim_DeterministicTransition",
              append = FALSE)

saveDatasheet(ssimObject = transitionPathwaySubScenario, 
              data = probabilisticTransitionsDatasheet,
              name = "stsim_Transition",
              append = FALSE)

# Memory management
rm(deterministicTransitionValues, transitionPathwaySubScenario, 
   deterministicTransitionsDatasheet, probabilisticTransitionsDatasheet, 
   probabilisticTransitionValues)

### Initial Conditions ----
#### Spatial ----
##### Initial TST Spatial ----
initialTstSpatialValues <- list(
  TransitionGroupID = "Disturbance: Clearcut [Type]",
  TSTFileName = file.path(getwd(), spatialModelInputsDir, "time-since-cut.tif"))

# Create initial conditions sub scenario
initialTstSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Initial Conditions - TST Spatial")

# Populate initial conditions datasheet
initialTstDatasheet <- datasheet(
  ssimObject = initialTstSubScenario,
  name = "stsim_InitialTSTSpatial", 
  optional = TRUE) %>% 
  addRow(value = initialTstSpatialValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialTstSubScenario, 
              data = initialTstDatasheet,
              name = "stsim_InitialTSTSpatial")

# Memory management
rm(initialTstSpatialValues, initialTstSubScenario, initialTstDatasheet)

##### Baseline Ownership ----
# Create a list of the input tif files
initialConditionsSpatialValues <- list(
  StratumFileName = file.path(getwd(), spatialModelInputsDir, "primary-stratum.tif"), 
  SecondaryStratumFileName = file.path(getwd(), spatialModelInputsDir, "secondary-stratum-baseline.tif"),
  StateClassFileName = file.path(getwd(), spatialModelInputsDir, "state-class.tif"), 
  AgeFileName = file.path(getwd(), spatialModelInputsDir, "age.tif")) 

# Create initial conditions sub scenario
initialConditionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Initial Conditions - Baseline Ownership")

# Populate initial conditions datasheet
initialConditionsSpatialDatasheet <- datasheet(
  ssimObject = initialConditionsSubScenario,
  name = "stsim_InitialConditionsSpatial") %>% 
  addRow(value = initialConditionsSpatialValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialConditionsSubScenario, 
              data = initialConditionsSpatialDatasheet,
              name = "stsim_InitialConditionsSpatial")

##### Increased Aspen Protection ----
# Create a list of the input tif files
initialConditionsSpatialValues <- list(
  StratumFileName = file.path(getwd(), spatialModelInputsDir, "primary-stratum.tif"), 
  SecondaryStratumFileName = file.path(getwd(), spatialModelInputsDir, "secondary-stratum-aspen-protection.tif"),
  StateClassFileName = file.path(getwd(), spatialModelInputsDir, "state-class.tif"), 
  AgeFileName = file.path(getwd(), spatialModelInputsDir, "age.tif")) 

# Create initial conditions sub scenario
initialConditionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Initial Conditions - Increased Aspen Protection")

# Edit initial conditions datasheet
initialConditionsSpatialDatasheet <- datasheet(
  ssimObject = initialConditionsSubScenario,
  name = "stsim_InitialConditionsSpatial",
  empty = TRUE) %>% 
  addRow(value = initialConditionsSpatialValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialConditionsSubScenario, 
              data = initialConditionsSpatialDatasheet,
              name = "stsim_InitialConditionsSpatial")

##### Military Training Land Protection ----
# Create a list of the input tif files
initialConditionsSpatialValues <- list(
  StratumFileName = file.path(getwd(), spatialModelInputsDir, "primary-stratum.tif"), 
  SecondaryStratumFileName = file.path(getwd(), spatialModelInputsDir, "secondary-stratum-military-training-land-protection.tif"),
  StateClassFileName = file.path(getwd(), spatialModelInputsDir, "state-class.tif"), 
  AgeFileName = file.path(getwd(), spatialModelInputsDir, "age.tif")) 

# Create initial conditions sub scenario
initialConditionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Initial Conditions - Military Training Land Protection")

# Edit initial conditions datasheet
initialConditionsSpatialDatasheet <- datasheet(
  ssimObject = initialConditionsSubScenario,
  name = "stsim_InitialConditionsSpatial",
  empty = TRUE) %>% 
  addRow(value = initialConditionsSpatialValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialConditionsSubScenario, 
              data = initialConditionsSpatialDatasheet,
              name = "stsim_InitialConditionsSpatial")

# Memory management
rm(initialConditionsSpatialValues, initialConditionsSubScenario, 
   initialConditionsSpatialDatasheet)

#### Non-Spatial ----
initialConditionsNonSpatialValues <- data.frame(
  TotalAmount = 12,
  NumCells = 12,
  CalcFromDist = "TRUE")

initialConditionsNonSpatialDistribution <- data.frame(
  StratumID = rep(c("IDFdk", "SBPSmk", "SBSdw"), each = 4),
  StateClassID = rep(c("Forest:Aspen", "Forest:Fir", "Forest:Pine", "Forest:Spruce"), times = 3),
  RelativeAmount = 1)

# Create initial conditions sub scenario
initialConditionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Initial Conditions Non-Spatial")

# Populate initial conditions datasheet
initialConditionsNonSpatialDatasheet <- datasheet(
  ssimObject = initialConditionsSubScenario,
  name = "stsim_InitialConditionsNonSpatial", 
  optional = TRUE) %>% 
  addRow(value = initialConditionsNonSpatialValues)

# Populate initial conditions distribution datasheet
initialConditionsDistributionDatasheet <- datasheet(
  ssimObject = initialConditionsSubScenario,
  name = "stsim_InitialConditionsNonSpatialDistribution", 
  optional = TRUE) %>% 
  addRow(value = initialConditionsNonSpatialDistribution)

# Save datasheets to library
saveDatasheet(ssimObject = initialConditionsSubScenario, 
              data = initialConditionsNonSpatialDatasheet,
              name = "stsim_InitialConditionsNonSpatial")

saveDatasheet(ssimObject = initialConditionsSubScenario, 
              data = initialConditionsDistributionDatasheet,
              name = "stsim_InitialConditionsNonSpatialDistribution")

# Memory management
rm(initialConditionsNonSpatialValues, initialConditionsNonSpatialDistribution, 
   initialConditionsSubScenario, initialConditionsNonSpatialDatasheet,
   initialConditionsDistributionDatasheet)

### Transition Targets ----
#### Historic Logging ----
# Define transition targets
transitionTargetValues <- data.frame(
  TransitionGroupID = "Disturbance: Clearcut [Type]",
  DistributionType = "Historic Logging",
  DistributionFrequencyID = "Iteration and Timestep")

# Create transition targets sub scenario
transitionTargetsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Targets - Historic Logging")

# Populate transition targets datasheet
transitionTargetsDatasheet <- datasheet(
  ssimObject = transitionTargetsSubScenario,
  name = "stsim_TransitionTarget", 
  optional = TRUE) %>% 
  addRow(value = transitionTargetValues)

# Save datasheet to library
saveDatasheet(ssimObject = transitionTargetsSubScenario, 
              data = transitionTargetsDatasheet,
              name = "stsim_TransitionTarget")

#### LULC ----
# Define transition targets
transitionTargetValues <- data.frame(
  Timestep = rep(c(2016, 2021, 2026, 2031, 2036, 2041, 2046), each = 2),
  TransitionGroupID = rep(c("LULC: -> Cropland [Type]", "LULC: -> Developed [Type]"), times = 7),
  DistributionType = rep(c("Historic LULC: -> Cropland", "Historic LULC: -> Developed"), times = 7),
  DistributionFrequencyID = "Iteration and Timestep")

# Create transition targets sub scenario
transitionTargetsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Targets - LULC")

# Populate transition targets datasheet
transitionTargetsDatasheet <- datasheet(
  ssimObject = transitionTargetsSubScenario,
  name = "stsim_TransitionTarget", 
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(value = transitionTargetValues)

# Save datasheet to library
saveDatasheet(ssimObject = transitionTargetsSubScenario, 
              data = transitionTargetsDatasheet,
              name = "stsim_TransitionTarget",append = F)

# Memory management
rm(transitionTargetValues, transitionTargetsSubScenario, 
   transitionTargetsDatasheet)

### Output Options ----
#### Spatial ----
# Define tabular output options
outputOptionValues = data.frame(
  SummaryOutputSC = "TRUE",
  SummaryOutputSCTimesteps = 1, 
  SummaryOutputSCAges = "TRUE",
  SummaryOutputTR = "TRUE",
  SummaryOutputTRTimesteps = 1,
  SummaryOutputSA = "TRUE",
  SummaryOutputSATimesteps = 1,
  SummaryOutputSAAges = "TRUE")

# Define spatial output options
outputOptionsSpatialValues = data.frame(
  RasterOutputSC = "TRUE",
  RasterOutputSCTimesteps = 1,
  RasterOutputAge = "TRUE",
  RasterOutputAgeTimesteps = 30,
  RasterOutputST = "TRUE",
  RasterOutputSTTimesteps = 30,
  RasterOutputTR = "TRUE",
  RasterOutputTRTimesteps = 1, 
  RasterOutputTST = "TRUE", 
  RasterOutputTSTTimesteps = 1)

# Create output options sub scenario
outputOptionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Output Options")

# Populate datasheets
outputOptionsDatasheet <- datasheet(
  ssimObject = outputOptionsSubScenario,
  name = "stsim_OutputOptions",
  empty = TRUE) %>% 
  addRow(value = outputOptionValues)

outputOptionsSpatialDatasheet <- datasheet(
  ssimObject = outputOptionsSubScenario,
  name = "stsim_OutputOptionsSpatial",
  empty = TRUE) %>%
  addRow(value = outputOptionsSpatialValues)

# Save datasheets to library
saveDatasheet(ssimObject = outputOptionsSubScenario, 
              data = outputOptionsDatasheet,
              name = "stsim_OutputOptions")

saveDatasheet(ssimObject = outputOptionsSubScenario,
              data = outputOptionsSpatialDatasheet,
              name = "stsim_OutputOptionsSpatial")

# Memory management
rm(outputOptionValues, outputOptionsSpatialValues, outputOptionsDatasheet, 
   outputOptionsSpatialDatasheet, outputOptionsSubScenario)

#### Non-Spatial ----
# Define tabular output options
outputOptionValues = data.frame(
  SummaryOutputSC = "TRUE",
  SummaryOutputSCTimesteps = 1, 
  SummaryOutputSCAges = "TRUE",
  SummaryOutputTR = "TRUE",
  SummaryOutputTRTimesteps = 1,
  SummaryOutputTRAges = "TRUE")

# Define stock flow output options
sfOutputOptionValues <- data.frame(
  SummaryOutputST = "TRUE",
  SummaryOutputSTTimesteps = 1, 
  SummaryOutputFL = "TRUE",
  SummaryOutputFLTimesteps = 1)

# Create output options sub scenario
outputOptionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Output Options Non-Spatial")

# Populate datasheets
outputOptionsDatasheet <- datasheet(
  ssimObject = outputOptionsSubScenario,
  name = "stsim_OutputOptions",
  empty = TRUE) %>% 
  addRow(value = outputOptionValues)

outputOptionsSFDatasheet <- datasheet(
  ssimObject = outputOptionsSubScenario,
  name = "stsimsf_OutputOptions",
  empty = TRUE) %>%
  addRow(value = sfOutputOptionValues)

# Save datasheets to library
saveDatasheet(ssimObject = outputOptionsSubScenario, 
              data = outputOptionsDatasheet,
              name = "stsim_OutputOptions")

saveDatasheet(ssimObject = outputOptionsSubScenario,
              data = outputOptionsSFDatasheet,
              name = "stsimsf_OutputOptions")

# Memory management
rm(outputOptionValues, sfOutputOptionValues, outputOptionsDatasheet, 
   outputOptionsSFDatasheet, outputOptionsSubScenario)

### Advanced ----
#### Transition Multipliers ----
##### No Fire ----
# Create transition multiplier no fire subscenario
transitionMultiplierSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Multiplier - No Fire")

# Create transition multiplier datasheet
transitionMultiplierDatasheet <- datasheet(
  ssimObject = transitionMultiplierSubScenario,
  name = "stsim_TransitionMultiplierValue",
  optional = TRUE) %>% 
  addRow(data.frame(TransitionGroupID = "Disturbance: Fire [Type]",
                    # Value or Multiplier?
                    Amount = 0)) %>% 
  mutate(TSTGroupID = NA) 

# Save datasheets to library
saveDatasheet(ssimObject = transitionMultiplierSubScenario, 
              data = transitionMultiplierDatasheet,
              name = "stsim_TransitionMultiplierValue")

##### Historic Fire ----
# Load historic fire base probability values
transitionMultiplierValues <- read_csv(
  file.path(tabularModelInputsDir, "Transition Multipliers - Historic Fire.csv")) %>% 
  mutate(bec = case_when(bec == "Bunch Grass:very dry warm" ~ "BGxw",
                         bec == "Interior Douglas-fir:dry cool" ~ "IDFdk",
                         bec == "Interior Douglas-fir:very dry mild" ~ "IDFxm",
                         bec == "Sub-Boreal Pine - Spruce:moist cool" ~ "SBPSmk",
                         bec == "Sub-Boreal Spruce:dry warm" ~ "SBSdw")) %>% 
  rename(StratumID = bec,
         Amount = meanAnnualFireProbability) %>% 
  mutate(TransitionGroupID = "Disturbance: Fire [Type]",
         TransitionMultiplierTypeID = "Base Probability") %>% 
  select(StratumID, TransitionGroupID, TransitionMultiplierTypeID, Amount) %>% 
  as.data.frame()

# Create transition multiplier subscenario
transitionMultiplierSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Multiplier - Historic Fire")

# Create transition multiplier datasheet
transitionMultiplierDatasheet <- datasheet(
  ssimObject = transitionMultiplierSubScenario,
  name = "stsim_TransitionMultiplierValue",
  optional = TRUE) %>% 
  addRow(transitionMultiplierValues) %>% 
  mutate(TSTGroupID = NA) %>% 
  # Add a row for variability multiplier
  addRow(data.frame(TransitionGroupID = "Disturbance: Fire [Type]",
                    TransitionMultiplierTypeID = "Variability",
                    DistributionType = "Historic Fire",
                    DistributionFrequencyID = "Iteration and Timestep"))

# Save datasheets to library
saveDatasheet(ssimObject = transitionMultiplierSubScenario, 
              data = transitionMultiplierDatasheet,
              name = "stsim_TransitionMultiplierValue")

##### LULC ----
# Load historic LULC transitions
transitionMultiplierValues <- read_csv(
  file.path(tabularModelInputsDir, "Transition Multipliers - LULC Proportions.csv")) %>% 
  as.data.frame()

# Create transition multiplier subscenario
transitionMultiplierSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Multipliers - LULC")

# Create transition multiplier datasheet
transitionMultiplierDatasheet <- datasheet(
  ssimObject = transitionMultiplierSubScenario,
  name = "stsim_TransitionMultiplierValue",
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(transitionMultiplierValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionMultiplierSubScenario, 
              data = transitionMultiplierDatasheet,
              name = "stsim_TransitionMultiplierValue")

# Memory management
rm(transitionMultiplierValues, transitionMultiplierSubScenario,
   transitionMultiplierDatasheet)

##### Non-Spatial No Disturbance ----
# Load historic LULC transitions
transitionMultiplierValues <- data.frame(
  TransitionGroupID = c("Disturbance: Clearcut [Type]", "Disturbance: Fire [Type]", "LULC Disturbances"),
  Amount = 0
)

# Create transition multiplier subscenario
transitionMultiplierSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Multipliers Non-Spatial - No Disturbance")

# Create transition multiplier datasheet
transitionMultiplierDatasheet <- datasheet(
  ssimObject = transitionMultiplierSubScenario,
  name = "stsim_TransitionMultiplierValue") %>% 
  addRow(transitionMultiplierValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionMultiplierSubScenario, 
              data = transitionMultiplierDatasheet,
              name = "stsim_TransitionMultiplierValue")

# Memory management
rm(transitionMultiplierValues, transitionMultiplierSubScenario,
   transitionMultiplierDatasheet)

##### Non-Spatial Year 100 Fire ----
# Load historic LULC transitions
transitionMultiplierValues <- data.frame(
  Timestep = c(0,0,0,100,101),
  TransitionGroupID = c("Disturbance: Clearcut [Type]", "Disturbance: Fire [Type]", "LULC Disturbances",
                        "Disturbance: Fire [Type]", "Disturbance: Fire [Type]"),
  Amount = c(0,0,0,1,0)
)

# Create transition multiplier subscenario
transitionMultiplierSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Multipliers Non-Spatial - Year 100 Fire")

# Create transition multiplier datasheet
transitionMultiplierDatasheet <- datasheet(
  ssimObject = transitionMultiplierSubScenario,
  name = "stsim_TransitionMultiplierValue",
  optional = TRUE) %>% 
  addRow(transitionMultiplierValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionMultiplierSubScenario, 
              data = transitionMultiplierDatasheet,
              name = "stsim_TransitionMultiplierValue")

# Memory management
rm(transitionMultiplierValues, transitionMultiplierSubScenario,
   transitionMultiplierDatasheet)

#### Transition Size ----
##### Historic Fire ----
# Load historic fire transition size values
transitionSizeValues <- read_csv(
  file.path(tabularModelInputsDir, "Transition Size Distribution - Historic Fire.csv")) %>%
  mutate(TransitionGroupID = "Disturbance: Fire [Type]") %>% 
  select(TransitionGroupID, MaximumArea, RelativeAmount) %>% 
  as.data.frame()

# Create transition size subscenario
transitionSizeSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Size - Fire")

# Create transition multiplier datasheet
transitionSizeDatasheet <- datasheet(
  ssimObject = transitionSizeSubScenario,
  name = "stsim_TransitionSizeDistribution",
  optional = TRUE) %>% 
  addRow(transitionSizeValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionSizeSubScenario, 
              data = transitionSizeDatasheet,
              name = "stsim_TransitionSizeDistribution")

##### Historic Logging ----
# Load historic logging size values
transitionSizeValues <- read_csv(
  file.path(tabularModelInputsDir, "Transition Size Distribution - Historic Logging.csv")) %>%
  as.data.frame()

# Create transition size subscenario
transitionSizeSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Size - Clearcut")

# Create transition multiplier datasheet
transitionSizeDatasheet <- datasheet(
  ssimObject = transitionSizeSubScenario,
  name = "stsim_TransitionSizeDistribution",
  optional = TRUE) %>% 
  addRow(transitionSizeValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionSizeSubScenario, 
              data = transitionSizeDatasheet,
              name = "stsim_TransitionSizeDistribution")

# Memory management
rm(transitionSizeValues, transitionSizeSubScenario,
   transitionSizeDatasheet)

#### Transition Adjacency ----
# Define LULC adjacency settings
transitionAdjacencySettings <- data.frame(
  TransitionGroupID = c("LULC: -> Cropland [Type]", "LULC: -> Developed [Type]"),
  StateClassID = c("Cropland:All", "Developed:All"))

# Define LULC adjacency multipliers
transitionAdjacencyValues <- data.frame(
  TransitionGroupID = rep(c("LULC: -> Cropland [Type]", "LULC: -> Developed [Type]"), each = 2),
  AttributeValue = rep(c(0, 0.88), times = 2),
  Amount = rep(c(0, 1), times = 2))

# Create transition size subscenario
transitionAdjacencySubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Transition Adjacency - LULC")

# Create transition multiplier datasheets
transitionAdjacencySettingsDatasheet <- datasheet(
  ssimObject = transitionAdjacencySubScenario,
  name = "stsim_TransitionAdjacencySetting",
  optional = TRUE) %>% 
  addRow(transitionAdjacencySettings)

transitionAdjacencyDatasheet <- datasheet(
  ssimObject = transitionAdjacencySubScenario,
  name = "stsim_TransitionAdjacencyMultiplier",
  optional = TRUE) %>% 
  addRow(transitionAdjacencyValues)

# Save datasheets to library
saveDatasheet(ssimObject = transitionAdjacencySubScenario, 
              data = transitionAdjacencySettings,
              name = "stsim_TransitionAdjacencySetting")

saveDatasheet(ssimObject = transitionAdjacencySubScenario, 
              data = transitionAdjacencyDatasheet,
              name = "stsim_TransitionAdjacencyMultiplier")

# Memory management
rm(transitionAdjacencyValues, transitionAdjacencySubScenario, 
   transitionAdjacencyDatasheet, transitionAdjacencySettings, 
   transitionAdjacencySettingsDatasheet)

#### State Attribute Values ----
##### Growth Rates ----
# Prep growth rate values
growthRateValues <- read_csv(file.path(tabularDataDir, "state-attribute-values.csv")) %>% 
  # Get values for bec == Interior Douglas Fir (IDF)
  # Assign rows to one subzone of IDF (dry cool)
  filter(bec == "Interior Douglas Fir") %>% 
  mutate(bec = "IDFdk") %>% 
  bind_rows(read_csv(file.path(tabularDataDir, "state-attribute-values.csv"))) %>% 
  mutate(species =  str_c("Forest:", species),
         # Assign duplicate IDF rows to the other IDF subzone (very dry mild)
         bec = case_when(bec == "IDFdk" ~ "IDFdk",
                         bec == "Interior Douglas Fir" ~ "IDFxm",
                         bec == "Sub-Boreal Pine - Spruce" ~ "SBPSmk",
                         bec == "Sub-Boreal Spruce" ~ "SBSdw")) %>% 
  pivot_longer(cols = deltaAspen:deltaQmd,
               names_to = "StateAttributeTypeID",
               values_to = "Value") %>% 
  mutate(StateAttributeTypeID = case_when(
               StateAttributeTypeID == "deltaAspen" ~ "Aspen Cover Growth Rate",
               StateAttributeTypeID == "deltaQmd" ~ "Diameter Growth Rate"),
         Value = round(Value, digits = 4),
         AgeMin = age) %>% 
  rename(StratumID = bec, 
         StateClassID = species,
         AgeMax = age) %>% 
  mutate(AgeMax = na_if(AgeMax, 299),
         AgeMin = na_if(AgeMin, 1)) %>% 
  select(StratumID, StateClassID, StateAttributeTypeID, AgeMin, AgeMax, Value) %>% 
  as.data.frame()

# Create state attribute value sub scenario
stateAttributeSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "State Attribute Values - Growth Rate")

# Create datasheet
stateAttributeDatasheet <- datasheet(
  ssimObject = stateAttributeSubScenario,
  name = "stsim_StateAttributeValue",
  optional = TRUE, 
  empty = TRUE) %>% 
  addRow(value = growthRateValues) %>% 
  mutate(TSTGroupID = NA)

# Save datasheet to library
saveDatasheet(ssimObject = stateAttributeSubScenario,
              data = stateAttributeDatasheet,
              name = "stsim_StateAttributeValue", 
              append = FALSE)

# Memory management
rm(growthRateValues, stateAttributeSubScenario, 
   stateAttributeDatasheet)

##### Post Replacement Diameter ----
# Prep values
postReplacementValues <- read_csv(file.path(tabularDataDir, "diameter-post-fire.csv")) %>%
  # Get values for bec == Interior Douglas Fir (IDF)
  # Assign rows to one subzone of IDF (dry cool)
  filter(bec == "Interior Douglas Fir") %>% 
  mutate(bec = "IDFdk") %>% 
  bind_rows(read_csv(file.path(tabularDataDir, "diameter-post-fire.csv"))) %>%
  mutate(StateAttributeTypeID = "Post Replacement Diameter (cm)",
         AgeMin = NA,
         AgeMax = NA,
         Value = intercept) %>% 
  select(bec, species, StateAttributeTypeID, AgeMin, AgeMax, Value) %>% 
  mutate(
    # Assign duplicate IDF rows to the other IDF subzone (very dry mild)
    bec = case_when(bec == "IDFdk" ~ "IDFdk",
                    bec == "Interior Douglas Fir" ~ "IDFxm",
                    bec == "Sub-Boreal Pine - Spruce" ~ "SBPSmk",
                    bec == "Sub-Boreal Spruce" ~ "SBSdw"),
    species =  str_c("Forest:", species)) %>% 
  rename(StratumID = bec, 
         StateClassID = species) %>%
  mutate(DistributionType = "Uniform",
         DistributionFrequencyID = "Always",
         DistributionMin = Value * 0.9,
         DistributionMax = Value * 1.1) %>% 
  # zzz: manually add Distribution min and max values??
  select(StratumID, StateClassID, StateAttributeTypeID, AgeMin, AgeMax, Value, 
         DistributionType, DistributionFrequencyID, DistributionMin, DistributionMax) %>% 
  as.data.frame()

# Create state attribute value sub scenario
stateAttributeSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "State Attribute Values - Post Replacement Diameter")

# Create datasheet
stateAttributeDatasheet <- datasheet(
  ssimObject = stateAttributeSubScenario,
  name = "stsim_StateAttributeValue",
  optional = TRUE, 
  empty = TRUE) %>% 
  addRow(value = postReplacementValues) 

# Save datasheet to library
saveDatasheet(ssimObject = stateAttributeSubScenario,
              data = stateAttributeDatasheet,
              name = "stsim_StateAttributeValue", 
              append = FALSE)

# Memory management
rm(postReplacementValues, stateAttributeSubScenario, 
   stateAttributeDatasheet)

##### Non-Spatial Initial Aspen Cover ----
stateAttributeValues <- data.frame(
  StratumID = rep(c("IDFdk", "IDFxm", "SBPSmk", "SBSdw"), each = 4),
  StateClassID = rep(c("Forest:Aspen", "Forest:Fir", "Forest:Pine", "Forest:Spruce"), times = 4),
  StateAttributeTypeID = "Non Spatial Initial Aspen Cover",
  Value = c(75,20,25,30,75,20,25,30,63,20,25,20,63,20,20,25),
  DistributionType = "Uniform",
  DistributionFrequencyID = "Iteration Only") %>%
  mutate(DistributionMin = Value * 0.9, 
         DistributionMax = Value * 1.1)

# Create state attribute value sub scenario
stateAttributeSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "State Attribute Values Non-Spatial - Inital Aspen Cover")

# Create datasheet
stateAttributeDatasheet <- datasheet(
  ssimObject = stateAttributeSubScenario,
  name = "stsim_StateAttributeValue",
  optional = TRUE) %>% 
  addRow(value = stateAttributeValues)

# Save datasheet to library
saveDatasheet(ssimObject = stateAttributeSubScenario,
              data = stateAttributeDatasheet,
              name = "stsim_StateAttributeValue", 
              append = FALSE)

# Memory management
rm(stateAttributeValues, stateAttributeSubScenario, 
   stateAttributeDatasheet)

#### Distributions ----
##### Historic Fire ----
# Load historic fire distribution values
distributionValues <- read_csv(
  file.path(tabularModelInputsDir, "Distribution - Historic Fire.csv")) %>% 
  rename(DistributionTypeID = Distribution,
         ValueDistributionRelativeFrequency = `Relative Frequency`) %>% 
  as.data.frame()

# Create transition size subscenario
distributionSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Distributions - Historic Fire")

# Create transition multiplier datasheet
distributionDatasheet <- datasheet(
  ssimObject = distributionSubScenario,
  name = "stsim_DistributionValue",
  optional = TRUE) %>% 
  addRow(distributionValues)

# Save datasheets to library
saveDatasheet(ssimObject = distributionSubScenario, 
              data = distributionDatasheet,
              name = "stsim_DistributionValue")

##### Historic Logging ----
distributionValues <- read_csv(
  file.path(tabularModelInputsDir, "Distributions - Historic Logging.csv")) %>% 
  as.data.frame()

# Create transition size subscenario
distributionSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Distributions - Historic Logging")

# Create transition multiplier datasheet
loggingDistributionDatasheet <- datasheet(
  ssimObject = distributionSubScenario,
  name = "stsim_DistributionValue",
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(distributionValues)

# Save datasheets to library
saveDatasheet(ssimObject = distributionSubScenario, 
              data = loggingDistributionDatasheet,
              name = "stsim_DistributionValue")

##### LULC ----
distributionValues <- read_csv(
  file.path(tabularModelInputsDir, "Distributions - LULC.csv")) %>% 
  mutate(DistributionTypeID = str_replace(DistributionTypeID, "C ", "C: ")) %>% 
  as.data.frame()

# Create transition size subscenario
distributionSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Distributions - LULC")

# Create transition multiplier datasheet
distributionDatasheet <- datasheet(
  ssimObject = distributionSubScenario,
  name = "stsim_DistributionValue",
  optional = TRUE,
  empty = TRUE) %>% 
  addRow(distributionValues)

# Save datasheets to library
saveDatasheet(ssimObject = distributionSubScenario, 
              data = distributionDatasheet,
              name = "stsim_DistributionValue")

# Memory management
rm(distributionValues, distributionSubScenario,
   distributionDatasheet, externalVariableValues, externalVariablesDatasheet)

#### External Variables ----
# Historic Logging Year and Historic LULC 5 Year Period
externalVariableValues <- tibble(
  Timestep = max(loggingDistributionDatasheet$ExternalVariableMin) + 1,
  ExternalVariableTypeID = "Historic Logging Years",
  ExternalVariableValue = NA,
  DistributionTypeID = "Uniform Integer",
  DistributionFrequency = "Iteration and Timestep",
  DistributionMin = min(loggingDistributionDatasheet$ExternalVariableMin),
  DistributionMax = max(loggingDistributionDatasheet$ExternalVariableMin)) %>% 
  bind_rows(tibble(
    Timestep = seq(2016, max(loggingDistributionDatasheet$ExternalVariableMin)),
    ExternalVariableTypeID = "Historic Logging Years",
    ExternalVariableValue = seq(2016, max(loggingDistributionDatasheet$ExternalVariableMin)),
    # zzz: datasheet won't accept NA for DistributionTypeID
    DistributionTypeID = NA,
    DistributionFrequency = NA,
    DistributionMin = NA,
    DistributionMax = NA)) %>% 
  # Add LULC external variable
  bind_rows(tibble(
    Timestep = c(2016, 2020),
    ExternalVariableTypeID = "Historic LULC 5 Year Period",
    ExternalVariableValue = c(4, NA),
    DistributionTypeID = c(NA, "Uniform Integer"),
    DistributionFrequency = c(NA, "Iteration and Timestep"),
    DistributionMin = c(NA, 1),
    DistributionMax = c(NA, 4))) %>%
  mutate(DistributionTypeID = DistributionTypeID %>% as.character()) %>% 
  as.data.frame()


externalVariablesSubScenario <- scenario(ssimObject = myProject,
                                         scenario = "External Variables - Logging and LULC")

externalVariablesDatasheet <- datasheet(
  ssimObject = externalVariablesSubScenario,
  name = "corestime_ExternalVariableValue",
  optional = TRUE) %>%
  rbind(externalVariableValues)

saveDatasheet(ssimObject = externalVariablesSubScenario,
              data = externalVariablesDatasheet,
              name = "corestime_ExternalVariableValue")

# Memory management
rm(externalVariableValues, externalVariablesSubScenario, 
   externalVariablesDatasheet, loggingDistributionDatasheet)

#### Stocks and Flows ----
##### Flow Pathways ----
# Define flow pathway diagram
flowPathwayDiagramValues <- data.frame(
  StockTypeID = c("Aspen Cover (%)", "Diameter (cm)"),
  Location = c("A1", "B1"))

# Define flow pathway values 
flowPathwayGrowthRates <- data.frame(
  ToStockTypeID = c("Aspen Cover (%)", "Diameter (cm)"),
  StateAttributeTypeID = c("Aspen Cover Growth Rate", "Diameter Growth Rate"),
  FlowTypeID = c("Aspen Cover Growth", "Diameter Growth"),
  Multiplier = c(1,1))

flowPathwayDisturbances <- data.frame(
  FromStockTypeID = rep(c("Aspen Cover (%)", "Diameter (cm)"), each = 2),
  TransitionGroupID = rep(c("LULC Disturbances", "Replacement Disturbances"), times = 2),
  StateAttributeTypeID = c(NA, NA, NA, "Post Replacement Diameter (cm)") %>% as.factor(),
  FlowTypeID = c("LULC", "Replacement (Aspen Cover)", "LULC", "Replacement (Diameter)"),
  Multiplier = c(0,1,0,1),
  TargetType = c("From Stock", "Flow", "From Stock", "From Stock"))

# Create flow pathway sub scenario
flowPathwaysSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Flow Pathways")

# Populate datasheets
flowPathwayDiagramDatasheet <- datasheet(
  ssimObject = flowPathwaysSubScenario,
  name = "stsimsf_FlowPathwayDiagram",
  optional = TRUE) %>% 
  addRow(value = flowPathwayDiagramValues)

flowPathwaysGrowthRatesDatasheet <- datasheet(
  ssimObject = flowPathwaysSubScenario,
  name = "stsimsf_FlowPathway",
  optional = TRUE) %>% 
  addRow(value = flowPathwayGrowthRates) %>% 
  mutate(TransitionGroupID = NA) 

flowPathwaysPostFireDatasheet <- datasheet(
  ssimObject = flowPathwaysSubScenario,
  name = "stsimsf_FlowPathway",
  optional = TRUE) %>% 
  rbind(value = flowPathwayDisturbances)

# Save datasheets to library
saveDatasheet(ssimObject = flowPathwaysSubScenario,
              data = flowPathwayDiagramDatasheet,
              name = "stsimsf_FlowPathwayDiagram")

saveDatasheet(ssimObject = flowPathwaysSubScenario,
              data = flowPathwaysGrowthRatesDatasheet,
              name = "stsimsf_FlowPathway")

saveDatasheet(ssimObject = flowPathwaysSubScenario,
              data = flowPathwaysPostFireDatasheet,
              name = "stsimsf_FlowPathway",
              append = TRUE)

# Memory management
rm(flowPathwayDiagramValues, flowPathwayGrowthRates, flowPathwayDisturbances,
   flowPathwayDiagramDatasheet, flowPathwaysGrowthRatesDatasheet, 
   flowPathwaysPostFireDatasheet)

##### Initial Stocks ----
###### Spatial ----
# Create a list of the input tif files
initialStockValues <- data.frame(
  StockTypeID = c("Aspen Cover (%)", "Diameter (cm)"),
  RasterFileName = c(file.path(getwd(), spatialModelInputsDir, "initial-aspen-cover.tif"),
                     file.path(getwd(), spatialModelInputsDir, "initial-diameter.tif"))) 

# Create initial stocks sub scenario
initialStocksSubScenario <- scenario(
  ssimObject = myProject, 
  scenario = "Initial Stocks Spatial")

# Populate datasheet
initialStocksDatasheet <- datasheet(
  ssimObject = initialStocksSubScenario,
  name = "stsimsf_InitialStockSpatial") %>% 
  addRow(value = initialStockValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialStocksSubScenario, 
              data = initialStocksDatasheet,
              name = "stsimsf_InitialStockSpatial")

# Memory management
rm(initialStockValues, initialStocksSubScenario, initialStocksDatasheet)

###### Non-Spatial ----
initialStockValues <- data.frame(
  StockTypeID = c("Aspen Cover (%)", "Diameter (cm)"),
  StateAttributeTypeID = c("Non Spatial Initial Aspen Cover",
                           "Post Replacement Diameter (cm)")) 

# Create initial stocks sub scenario
initialStocksSubScenario <- scenario(
  ssimObject = myProject, 
  scenario = "Initial Stocks Non Spatial")

# Populate datasheet
initialStocksDatasheet <- datasheet(
  ssimObject = initialStocksSubScenario,
  name = "stsimsf_InitialStockNonSpatial") %>% 
  addRow(value = initialStockValues)

# Save datasheet to library
saveDatasheet(ssimObject = initialStocksSubScenario, 
              data = initialStocksDatasheet,
              name = "stsimsf_InitialStockNonSpatial")

# Memory management
rm(initialStockValues, initialStocksSubScenario, initialStocksDatasheet)

##### Output Options ----
# Define sf output options
sfOutputOptionValues <- data.frame(
  SummaryOutputST = "TRUE",
  SummaryOutputSTTimesteps = 1, 
  SummaryOutputFL = "TRUE",
  SummaryOutputFLTimesteps = 1,
  SpatialOutputST = "TRUE",
  SpatialOutputSTTimesteps = 1)

# Create sf output options sub scenario
sfOutputOptionsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "SF Output Options")

# Populate datasheet
sfOutputOptionsDatasheet <- datasheet(
  ssimObject = sfOutputOptionsSubScenario,
  name = "stsimsf_OutputOptions") %>% 
  addRow(value = sfOutputOptionValues)

# Save datasheet to library
saveDatasheet(ssimObject = sfOutputOptionsSubScenario, 
              data = sfOutputOptionsDatasheet,
              name = "stsimsf_OutputOptions")

# Memory management
rm(sfOutputOptionValues, sfOutputOptionsSubScenario, sfOutputOptionsDatasheet)

##### Stock Limits ----
# Define stock limits
stockLimitValues <- data.frame(
  StockTypeID = c("Aspen Cover (%)", "Diameter (cm)"),
  StockMinimum = c(0, 0), 
  StockMaximum = c(100, " "))

# Create stock limits sub scenario
stockLimitsSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Stock Limits")

# Populate datasheet
stockLimitsDatasheet <- datasheet(
  ssimObject = stockLimitsSubScenario,
  name = "stsimsf_StockLimit") %>% 
  addRow(value = stockLimitValues)

# Save datasheet to library
saveDatasheet(ssimObject = stockLimitsSubScenario, 
              data = stockLimitsDatasheet,
              name = "stsimsf_StockLimit")

# Memory management
rm(stockLimitValues, stockLimitsSubScenario, stockLimitsDatasheet)

##### Flow Multiplier ----
postFireAspenValues <- read_csv(file.path(tabularDataDir, "aspen-cover-post-fire.csv")) %>% 
  # Get values for bec == Interior Douglas Fir (IDF)
  # Assign rows to one subzone of IDF (dry cool)
  filter(bec == "Interior Douglas Fir") %>% 
  mutate(bec = "IDFdk") %>% 
  bind_rows(read_csv(file.path(tabularDataDir, "aspen-cover-post-fire.csv"))) %>% 
  filter(age <= 250) %>% 
  mutate(bec = case_when(bec == "IDFdk" ~ "IDFdk",
                         bec == "Interior Douglas Fir" ~ "IDFxm",
                         bec == "Sub-Boreal Pine - Spruce" ~ "SBPSmk",
                         bec == "Sub-Boreal Spruce" ~ "SBSdw"),
         species = str_c("Forest:", species),
         FlowGroupID = "Replacement (Aspen Cover) [Type]",
         AgeMin = age) %>% 
  rename(Value = relativeChange,
         AgeMax = age,
         StratumID = bec,
         StateClassID = species) %>% 
  mutate(AgeMax = na_if(AgeMax, 250)) %>% 
  filter(!(StratumID == "SBSdw" & StateClassID == "Forest:Pine" & AgeMax > 200)) %>% 
  mutate(AgeMax = case_when(StratumID == "SBSdw" &  StateClassID == "Forest:Pine" & AgeMax == 200 ~ NA,
                          StratumID != "SBSdw" |  StateClassID != "Forest:Pine" | AgeMax != 200 ~ AgeMax)) %>% 
  select(StratumID, StateClassID, FlowGroupID, AgeMin, AgeMax, Value)

# Create flow multipliers sub scenario
flowMultipliersSubScenario <- scenario(
  ssimObject = myProject,
  scenario = "Flow Multipliers")

# Populate datasheet
stockLimitsDatasheet <- datasheet(
  ssimObject = flowMultipliersSubScenario,
  name = "stsimsf_FlowMultiplier",
  optional = TRUE) %>% 
  addRow(value = postFireAspenValues)

# Save datasheet to library
saveDatasheet(ssimObject = flowMultipliersSubScenario, 
              data = stockLimitsDatasheet,
              name = "stsimsf_FlowMultiplier")

# Make Flow Pathways dependent on Flow Multipliers
dependency(flowPathwaysSubScenario, "Flow Multipliers")

# Memory management
rm(flowPathwaysSubScenario, postFireAspenValues, flowMultipliersSubScenario, 
   stockLimitsDatasheet)

## Full Scenarios ----
### Single Cell ----
#### No Disturbance ----
noDisturbanceScenario <- scenario(ssimObject = myProject,
                                  scenario = "Single Cell - No Disturbance")

# Merge dependencies for the baseline Scenario
mergeDependencies(noDisturbanceScenario) <- TRUE

# Add sub-scenarios as dependencies to the full scenario
dependency(noDisturbanceScenario, "Stock Limits")
dependency(noDisturbanceScenario, "Flow Pathways")
dependency(noDisturbanceScenario, "State Attribute Values Non-Spatial - Inital Aspen Cover")
dependency(noDisturbanceScenario, "State Attribute Values - Post Replacement Diameter")
dependency(noDisturbanceScenario, "State Attribute Values - Growth Rate")
dependency(noDisturbanceScenario, "Transition Pathways")
dependency(noDisturbanceScenario, "Run Control Non-Spatial, 250 yr, 40 it")
dependency(noDisturbanceScenario, "Initial Conditions Non-Spatial")
dependency(noDisturbanceScenario, "Initial Stocks Non Spatial")
dependency(noDisturbanceScenario, "Transition Multipliers Non-Spatial - No Disturbance")
dependency(noDisturbanceScenario, "Output Options Non-Spatial")

#### Fire ----
fireScenario <- scenario(ssimObject = myProject,
                         scenario = "Single Cell - Fire",
                         sourceScenario = "Single Cell - No Disturbance")

# Replace transition multiplier
dependency(fireScenario, "Transition Multipliers Non-Spatial - No Disturbance", 
           remove = TRUE, force = TRUE)
dependency(fireScenario, "Transition Multipliers Non-Spatial - Year 100 Fire")

### Landscape ----
#### Baseline Ownership with Disturbances ----
baselineScenario <- scenario(ssimObject = myProject,
                             scenario = "Baseline Ownership with Disturbances: 2016 to 2046, 1MC")

# Merge dependencies for the baseline Scenario
mergeDependencies(baselineScenario) <- TRUE

# Add sub-scenarios as dependencies to the full baseline scenario
# Note: sub-scenarios are added in reverse order so that they appear in order in the UI
dependency(baselineScenario, "Stock Limits")
dependency(baselineScenario, "SF Output Options")
dependency(baselineScenario, "Initial Stocks Spatial")
dependency(baselineScenario, "Flow Pathways")
dependency(baselineScenario, "State Attribute Values - Post Replacement Diameter")
dependency(baselineScenario, "State Attribute Values - Growth Rate")
dependency(baselineScenario, "Transition Adjacency - LULC")
dependency(baselineScenario, "Transition Size - Clearcut")
dependency(baselineScenario, "Transition Size - Fire")
dependency(baselineScenario, "Transition Multipliers - LULC")
dependency(baselineScenario, "Transition Multiplier - Historic Fire")
dependency(baselineScenario, "External Variables - Logging and LULC")
dependency(baselineScenario, "Distributions - LULC")
dependency(baselineScenario, "Distributions - Historic Logging")
dependency(baselineScenario, "Distributions - Historic Fire")
dependency(baselineScenario, "Output Options")
dependency(baselineScenario, "Transition Targets - LULC")
dependency(baselineScenario, "Transition Targets - Historic Logging")
dependency(baselineScenario, "Initial Conditions - TST Spatial")
dependency(baselineScenario, "Initial Conditions - Baseline Ownership")
dependency(baselineScenario, "Transition Pathways")
dependency(baselineScenario, "Run Control Spatial, 2016 to 2046, 1 Iteration")

#### Increased Aspen Protection with Disturbances ----
# Create a copy of the Baseline - No Fire scenario
aspenProtectionScenario <- scenario(ssimObject = myProject,
                                    scenario = "Aspen Protection with Disturbances: 2016 to 2046, 1MC",
                                    sourceScenario = "Baseline Ownership with Disturbances: 2016 to 2046, 1MC")

# Replace ownership raster
dependency(aspenProtectionScenario, "Initial Conditions - Baseline Ownership", remove = TRUE, force = TRUE)
dependency(aspenProtectionScenario, "Initial Conditions - Increased Aspen Protection")

#### Increased Protection (Military Training Land): 2016 to 2046, 1MC; Fire, Logging, LULC ----
# Create a copy of the Baseline - No Fire scenario
militaryLandProtectionScenario <- scenario(ssimObject = myProject,
                                           scenario = "Military Land Protection with Disturbances: 2016 to 2046, 1MC",
                                           sourceScenario = "Baseline Ownership with Disturbances: 2016 to 2046, 1MC")

# Remove Initial Conditions - Baseline Ownership datasheet
dependency(militaryLandProtectionScenario, "Initial Conditions - Baseline Ownership", remove = TRUE, force = TRUE)
# Add logging and LULC transition datasheets
dependency(militaryLandProtectionScenario, "Initial Conditions - Military Training Land Protection")


