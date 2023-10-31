## a296
## Sarah Chisholm (ApexRMS)
## November 2022
##
## Historic logging analysis
##
## This code:                                                                                                               
## 1. Imports Primary Stratum, Secondary Stratum, and CUTBLOCKS data                                       
## 2. Imports study region clipping mask                                                                 
## 3. Computes area clearcut per year, per Primary Stratum, and per Secondary Stratum                                       
## 4. Determines the clearcut size class distribution                                                                       

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(tidyverse)
library(terra)
library(sf)

# Define directories
tabularDataDir <- file.path("Data", "Tabular")
spatialDataDir <- file.path("Data", "Spatial")
tabularModelInputsDir <- file.path("Model-Inputs", "Tabular")
spatialModelInputsDir <- file.path("Model-Inputs", "Spatial")
plotsDir <- "Plots"

# Load spatial data
# VRI shapefile (used to define the study area and get the primary stratum)
vri <- vect(x = spatialDataDir, layer = "vri-aspen-percent-cover")

# Secondary stratum (Baseline Ownership)
secondaryStratum <- rast(file.path(spatialModelInputsDir, "ownership-baseline.tif"))

# Cutblocks shapefile
# To be used with terra functions
cutblocks <- vect(x = file.path(spatialDataDir, "Consolidated_Cutblocks", "Consolidated_Cutblocks", "Consolidated_Cut_Block.gdb"),
                  layer = "consolidated-cutblocks-vri-extent")

# To be used with sf functions
cutBlocksSf <- st_read(dsn = file.path(spatialDataDir, "Consolidated_Cutblocks", "Consolidated_Cutblocks", "Consolidated_Cut_Block.gdb"),
                       layer = "consolidated-cutblocks-vri-extent")

## Define the study area and strata ----
# Study Area
vri$Boundary <- 1
studyArea <- aggregate(vri, by = "Boundary")

# Primary stratum (BEC variant)
primaryStratum <- aggregate(vri, by = "BEC_VAR_")

# Secondary stratum
secondaryStratum <- as.polygons(secondaryStratum)
secondaryStratum$ownershipType <- secondaryStratum$OBJECTID

## Historic logging analysis ----
# 1. Union strata and cutblocks
# zzz: export and check that this is correct
primaryStratumUnionCutblocks <- terra::intersect(cutblocks, primaryStratum)
stratumUnionCutblocks <- terra::intersect(primaryStratumUnionCutblocks, secondaryStratum)

# 2. Calculate area harvested per stratum per year
## Calculate area of each polygon
stratumUnionCutblocks$areaHa <- expanse(stratumUnionCutblocks, unit = "ha")

rawData <- as.data.frame(stratumUnionCutblocks) %>% 
  select(BEC_ZONE_C, BEC_SUB, ownershipType, Harvest_Ye, areaHa) %>% 
  mutate(PrimaryStratum = str_c(BEC_ZONE_C, BEC_SUB)) %>% 
  rename(SecondaryStratum = ownershipType, 
         Year = Harvest_Ye) %>% 
  select(PrimaryStratum, SecondaryStratum, Year, areaHa)

# Create template stratum | year dataframe
# Get all unique combinations of primary and secondary stratum
strata <- rawData %>% 
  select(PrimaryStratum, SecondaryStratum) %>% 
  distinct() %>% 
  bind_rows(data.frame(PrimaryStratum = "BGxw",
                       SecondaryStratum = 3))

# Get continuous sequence of harvest years
years <- min(rawData$Year):max(rawData$Year)

# Create template dataframe
template <- data.frame(PrimaryStratum = rep(strata$PrimaryStratum, times=length(years)),
                       SecondaryStratum = rep(strata$SecondaryStratum, times=length(years)),
                       Year = rep(years, each=nrow(strata)))

# Compute area cut
areaCut <- rawData %>%
  group_by(PrimaryStratum, SecondaryStratum, Year) %>% 
  summarise(areaCutHa = sum(areaHa)) %>% 
  ungroup()

# Populate the template dataframe
areaCut <- areaCut %>% 
  left_join(template, .) %>% 
  mutate(areaCutHa = replace_na(areaCutHa, 0),
         SecondaryStratum = case_when(SecondaryStratum == 1 ~ "Protected",
                                      SecondaryStratum == 2 ~ "Private",
                                      SecondaryStratum == 3 ~ "Public")) %>% 
  filter(Year >= 1995) %>% 
  rename(StratumID = PrimaryStratum,
         SecondaryStratumID = SecondaryStratum,
         Value = areaCutHa) %>%
  mutate(DistributionTypeID = "Historic Logging",
         ExternalVariableTypeID = "Historic Logging Years",
         ExternalVariableMin = Year,
         ExternalVariableMax = Year, 
         Value = case_when(SecondaryStratumID == "Protected" ~ 0,
                           SecondaryStratumID == "Private" ~ Value,
                           SecondaryStratumID == "Public" ~ Value)) %>% 
  select(StratumID, SecondaryStratumID, DistributionTypeID, 
         ExternalVariableTypeID, ExternalVariableMin, ExternalVariableMax, Value)

# Save to disk
write_csv(areaCut, file.path(tabularModelInputsDir, "Distributions - Historic Logging.csv"))

## Clearcut count by clearcut size class ----

# Remove clearcuts that are older than year 1995

# Multipart to single part features
# Remove cut polygons with Harvest Year < 1995
splitCutBlocks <- st_cast(cutBlocksSf, "POLYGON") %>% 
  filter(Harvest_Ye >= 1995) %>% select(Harvest_Ye) %>% pull(Harvest_Ye)
  vect()

# Compute area
splitCutBlocks$areaHa <- expanse(splitCutBlocks, unit = "ha")

# Get cut sizes
# Less than or equal to 50 ha
lessThan50Ha <- splitCutBlocks %>% 
  as.data.frame() %>% 
  select(areaHa) %>% 
  filter(areaHa <= 50) %>% 
  arrange(areaHa)

# Define size classes
interval <- 10 # Set interval size
mins <- seq(from=floor(min(lessThan50Ha)), by=interval, length.out=ceiling(max(lessThan50Ha)/interval))
maxs <- mins+interval

# Compute cut count by cut size class
cutsLessThan50Ha <- data.frame(SizeClassMinHa = mins,
                               SizeClassMaxHa = maxs)
cutsLessThan50Ha$ClearcutCount <- sapply(1:nrow(cutsLessThan50Ha),
                                          function(x) length(lessThan50Ha[which((lessThan50Ha$areaHa >= cutsLessThan50Ha$SizeClassMinHa[x]) & (lessThan50Ha$areaHa < cutsLessThan50Ha$SizeClassMaxHa[x])),]))

# Greater than 50 ha
greaterThan50Ha <- splitCutBlocks %>% 
  as.data.frame() %>% 
  select(areaHa) %>% 
  filter(areaHa > 50) %>% 
  arrange(areaHa)

# Define size classes
interval <- 50 # Set interval size
mins <- seq(from=floor(min(greaterThan50Ha)), by=interval, length.out=floor(max(greaterThan50Ha)/interval))
maxs <- mins+interval

# Compute cut count by cut size class
cutsGreaterThan50Ha <- data.frame(SizeClassMinHa = mins,
                                 SizeClassMaxHa = maxs)
cutsGreaterThan50Ha$ClearcutCount <- sapply(1:nrow(cutsGreaterThan50Ha),
                                           function(x) length(greaterThan50Ha[which((greaterThan50Ha$areaHa >= cutsGreaterThan50Ha$SizeClassMinHa[x]) & (greaterThan50Ha$areaHa < cutsGreaterThan50Ha$SizeClassMaxHa[x])),]))

# Combine size class data frames
cutCountSizeClass <- cutsLessThan50Ha %>% 
  bind_rows(cutsGreaterThan50Ha) %>% 
  mutate(TransitionGroupID = "Disturbance: Clearcut [Type]",
         MaximumArea = SizeClassMaxHa,
         RelativeAmount = ClearcutCount) %>% 
  select(TransitionGroupID, MaximumArea, RelativeAmount)

# Export
write_csv(cutSizesDf, file.path(tabularModelInputsDir, "cut-sizes.csv"))
write_csv(cutCountSizeClass, file.path(tabularModelInputsDir, "Transition Size Distribution - Historic Logging.csv"))

## Plots ----
### Area cut per year ----
areaCut <- read_csv(file.path(tabularModelInputsDir, "Distribution - Historic Logging.csv"))

areaCutPlot <- areaCut %>% 
  filter(Year >= 1950) %>% 
  ggplot(aes(Year, areaCutHa)) +
  geom_line() + 
  facet_grid(SecondaryStratum ~ PrimaryStratum) + 
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  scale_y_continuous(breaks = seq(0, 4000, by = 1000)) +
  ylab("Area Cut (Ha)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 

ggsave(filename = file.path(plotsDir, "annual-area-cut.png"),
       plot = areaCutPlot,
       width = 12,
       height = 6,
       dpi = 300)
   