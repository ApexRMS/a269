## a296
## Sarah Chisholm (ApexRMS)
## October 6, 2022
##
## Habitat Suitability Analysis

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Settings
options(stringsAsFactors=FALSE, SHAPE_RESTORE_SHX=T, useFancyQuotes = F, digits=10)

# Load libraries
library(rsyncrosim)
library(tidyverse)
library(terra)
library(MuMIn)
library(VGAM)
library(unmarked)

# Define directories
tabularDataDir <- file.path("Data", "Tabular")
libraryDir <- "Libraries"
modelInputsDir <- file.path("Model-Inputs", "Spatial")
modelOutputsDir <- "Model-Outputs"

# Input Parameters
# List result scenario IDs
scenarioIds <- c(19, 18)

# ST-Sim library path
libraryPath <- file.path(libraryDir, "ECCC cavity nests model.ssim")

# PIWO statistical model path
modelPath <- file.path(tabularDataDir,"piwo_mods.Rds")

# Load model
m <- load(modelPath)
m <- piwo_mods

# Cell size (90m x 90m) to Ha conversion
scaleFactor = 0.81

# Total area (Ha) of analysis area
totalArea <- 336475.6200

# # Get averaged coefficients - zzz: are these necessary??
# m_Perc_At_mean <- piwo_mods$coefficients[1, 2]
# # SC: not sure where to find SE; for now, use averaged SE from coefArray 
# m_Perc_At_se <- sum(piwo_mods$coefArray[1, 2, 2], 
#                     piwo_mods$coefArray[2, 2, 2],   
#                     piwo_mods$coefArray[3, 2, 2]) / 3
#   
# m_Median_DBH_mean <- piwo_mods$coefficients[1, 3]
# # SC: not sure where to find SE; for now, use averaged SE from coefArray 
# m_Median_DBH_se <- sum(piwo_mods$coefArray[1, 2, 3],   
#                        piwo_mods$coefArray[2, 2, 3],   
#                        piwo_mods$coefArray[3, 2, 3]) / 3   
  
## Connect to library ----
  
# SQLite connection
# SC: not sure if I need this
# db <- dbConnect(SQLite(), dbname=libraryPath)
  
# Load library
myLibrary <- ssimLibrary(libraryPath)

# Load project
myProject <- rsyncrosim::project(myLibrary, project = 1) 

# Get "OSFL Habitat" key
# SC: don't think I need this
# stsim_StateAttributeType <- datasheet(project, "stsim_StateAttributeType", includeKey = T)
# key <- stsim_StateAttributeType$StateAttributeTypeID[which(stsim_StateAttributeType$Name == 'OSFL Habitat')]

## Habitat Suitability Analysis ----
# Generate a PIWO habitat suitability map for each full scenario
for(scenarioId in scenarioIds){
  
  # SC: Test on scenario 14 (No Fire)
  #scenarioId <- scenarioIds[1]
  
  # Scenario
  scenario <- scenario(myLibrary, scenario = scenarioId)
  
  # Run Control Information
  #nIterations <- datasheet(scenario, "stsim_RunControl") %>% .$MaximumIteration
  minTime <- datasheet(scenario, "stsim_RunControl") %>% .$MinimumTimestep  
  maxTime <- datasheet(scenario, "stsim_RunControl") %>% .$MaximumTimestep
  timeSteps <- seq(from=minTime, to=maxTime, by=10)
  
  # Inputs - Get paths
  # primaryStratum_name <- datasheet(scenario, "stsim_InitialConditionsSpatial") %>% .$StratumFileName
 
  # Inputs - Import
  # primaryStratum <- rast(primaryStratum_name)
  
  # Inputs - Get keys
  # SC: What is a key?
  #keys_primaryStratum <- datasheet(scenario, name = "stsim_Stratum", includeKey = T)
  
  # Create empty raster of study area
  maskRaster <- datasheetRaster(scenario, "stsim_OutputSpatialState", iteration = 1, timestep = timeSteps[1])
  maskRaster[] <- as.numeric(maskRaster[])
  maskRaster[!is.na(maskRaster)] <- 0
  
  # Define statistical models to be used for each iteration
  
  # zzz: I don't think this chunk is necessary??
  # SC: there is currently a single iteration
  #for(it in 1:nIterations){
    
    #m <- piwo_mods
 
    #zzz: stuck here - look further down the script to see where it is used
    #m@beta[2] <- rnorm(1, mean = m_Perc_At_mean, sd = m_Perc_At_se)
    #m@beta[3] <- rnorm(1, mean = m_Median_DBH_mean, sd = m_Median_DBH_se)
    #m_list <- c(m_list, m)
    
    # # m1
    # m1_it <- m1
    # m1_it@beta[2] <- rnorm(1, mean = m1_Cut_size_sc_mean, sd = m1_Cut_size_sc_se)
    # m1_it@beta[4] <- rnorm(1, mean = m1_T_cut_sc_sq_mean, sd = m1_T_cut_sc_sq_se)
    # m1_list <- c(m1_list, m1_it)
  #}
  #rm(it, m_it)
  
  # SC: Get input stock rasters for 2046
  # Percent aspen cover 
  aspenCover <- datasheetRaster(
    ssimObject = scenario, 
    datasheet = "stsimsf_OutputSpatialStockGroup", 
    iteration = 1, 
    timestep = maxTime)$stkg_54.it1.ts2046
  
  # Diameter
  quadraticMeanDiameter <- datasheetRaster(
    ssimObject = scenario, 
    datasheet = "stsimsf_OutputSpatialStockGroup", 
    iteration = 1, 
    timestep = maxTime)$stkg_55.it1.ts2046
  
  # Convert aspen raster to proportion (rather than percentage)
  aspenCover[] <- aspenCover[]/100
  
  # Create dataframe of habitat suitability model inputs
  habitatSuitabilityDf <- data.frame(Perc_At = aspenCover[], 
                                     Median_DBH = quadraticMeanDiameter[],
                                     edge_near = 0,
                                     Num_2BI = 0,
                                     Mean_decay = 0,
                                     dist_to_cut = 0,
                                     # zzz: how to handle categorical variables??
                                     cut_harvest0 = "N",
                                     Site = rep(x = "YY", times = 585152))
  
  # Predict PIWO presence using piwo_mod
  habitatSuitabilityDf$pred <- predict(m, newdata = habitatSuitabilityDf, type = "response", allow.new.levels = TRUE)
  
  # Create habitat suitability raster
  habitatSuitabilityRaster <- maskRaster
  habitatSuitabilityRaster[] <- NA
  habitatSuitabilityRaster[] <- habitatSuitabilityDf$pred
  names(habitatSuitabilityRaster) <- str_c("piwo-suitability-scenario", scenarioId, "-ts", maxTime) 
    
  # Save to model outputs
  # zzz: Save back to library?
  writeRaster(x = habitatSuitabilityRaster, 
              filename = file.path(modelOutputsDir, str_c(names(habitatSuitabilityRaster), ".tif")))
  
}

## Calculate and plot avg habitat suitability ----
# Load primary stratum raster (BEC subzones)
primaryStratumRaster <- rast(file.path(modelInputsDir, "primary-stratum.tif"))
names(primaryStratumRaster) <- "BecSubzone"

# Get total area (Ha) per BEC subzone
becAreaDf <- freq(primaryStratumRaster) %>% 
  as.data.frame() %>% 
  select(-layer) %>% 
  mutate(Area = count * scaleFactor)

# Load habitat suitability maps
habitatSuitabilityNoFire <- rast(file.path(modelOutputsDir, "piwo.suitability.scenario19.ts2046.tif"))
names(habitatSuitabilityNoFire) <- "NoFire"

habitatSuitabilityFire <- rast(file.path(modelOutputsDir, "piwo.suitability.scenario18.ts2046.tif"))
names(habitatSuitabilityFire) <- "Fire"

# Plot mean suitability per Bec subzone
suitabilityPerBecDf <- c(primaryStratumRaster, habitatSuitabilityNoFire, habitatSuitabilityFire) %>% 
  as.data.frame() %>% 
  group_by(BecSubzone) %>% 
  summarise(TotalHabitatSuitabilityNoFire = sum(NoFire),
            TotalHabitatSuitabilityFire = sum(Fire)) %>%
  ungroup() %>% 
  left_join(becAreaDf, by = c("BecSubzone" = "value")) %>% 
  mutate(NoFire = TotalHabitatSuitabilityNoFire/Area,
         Fire = TotalHabitatSuitabilityFire/Area) %>% 
  pivot_longer(cols = NoFire:Fire,
               names_to = "Scenario",
               values_to = "MeanSuitability") %>% 
  mutate(BecSubzone = case_when(BecSubzone == 1 ~ "BGxw",
                                BecSubzone == 2 ~ "IDFdk",
                                BecSubzone == 3 ~ "IDFxm",
                                BecSubzone == 4 ~ "SBPSmk",
                                BecSubzone == 5 ~ "SBSdw")) %>% 
  rename("BEC Subzone" = BecSubzone)


becSuitabilityPlot <- suitabilityPerBecDf %>% 
  ggplot(mapping = aes(x = `BEC Subzone`, y = MeanSuitability, fill = Scenario)) +
  geom_col(position = position_dodge(), colour = "black") +
  scale_fill_manual(values = c("white", "black")) +
  ylab("Mean Suitability Per Ha") +
  theme_bw()

ggsave(
  file.path(modelOutputsDir, "suitability-per-bec.png"),
  becSuitabilityPlot,
  width = 6,
  height = 5,
  dpi = 300
)

# Plot mean suitability for whole analysis area
suitabilityTotalDf = c(habitatSuitabilityNoFire, habitatSuitabilityFire) %>% 
  as.data.frame() %>% 
  summarise(MeanNoFire = sum(NoFire)/totalArea,
            MeanFire = sum(Fire)/totalArea) %>% 
  pivot_longer(cols = MeanNoFire:MeanFire,
               names_to = "Scenario",
               values_to = "MeanSuitability") 

totalSuitabilityPlot <- suitabilityTotalDf %>% 
  mutate(Scenario = case_when(Scenario == "MeanNoFire" ~ "No Fire",
                              Scenario == "MeanFire" ~ "Fire")) %>% 
  ggplot(aes(x = Scenario, y = MeanSuitability, fill = Scenario)) + 
  geom_bar(position = "dodge", stat = "identity", colour = "black") +
  scale_fill_manual(values = c("white", "black")) +
  ylab("Mean Suitability Per Ha") +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())
  
ggsave(
  file.path(modelOutputsDir, "suitability-total.png"),
  totalSuitabilityPlot,
  width = 5,
  height = 5,
  dpi = 300
)

