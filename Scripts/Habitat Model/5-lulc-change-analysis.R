## a296
## Sarah Chisholm (ApexRMS)
## November 2022
##
## LULC change rates
##
## This script characterizes land cover change at an interval of 5 years from 
## 2000 to 2020, stratified by ownership type.

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(rgrass7)
library(tidyverse)
library(terra)
library(sf)

# Define directories
gisBase <- "C:/Program Files/GRASS GIS 7.8"
gisDbase <- "F:/gitproject/a269/grass7"
tabularDataDir <- file.path("Data", "Tabular")
spatialDataDir <- file.path("Data", "Spatial")
intermediatesDir <- "Intermediates"
tabularModelInputsDir <- file.path("Model-Inputs", "Tabular")
spatialModelInputsDir <- file.path("Model-Inputs", "Spatial")
plotDir <- "Plots"

# Parameters
# Create GRASS mapset?
doGRASSSetup <- FALSE

# List land cover raster files
landCoverFilnames <- list.files(path = file.path(spatialDataDir, "AAFC"),
                                pattern = ".tif$",
                                full.names = TRUE,
                                recursive = TRUE)

# Target crs
targetCrs <- "epsg: 3005"

# Target extent
targetExtent <- c(1229152, 1309432, 760673, 819713)

# Target resolution
targetResolution <- 90

# Convert cell counts to hectares (for cells with 90x90m resolution)
scaleFactor <- 0.81

# Temporal resolution of LULC data (years)
temporalResolution <- 5

# Load spatial data
# VRI data
vriShapefile <- vect(x = file.path(spatialDataDir, "vri-aspen-percent-cover.shp"))

# Secondary stratum (Baseline Ownership)
secondaryStratum <- rast(file.path(spatialModelInputsDir, "ownership-baseline.tif"))

# Load tabular data 
# Secondary stratum IDs
ownershipdIds <- read_csv(file.path(tabularModelInputsDir, "Secondary Stratum.csv")) %>% 
  select(ID, Name)

# State class IDs
stateClassIds <- read_csv(file.path(tabularModelInputsDir, "State Class.csv")) %>% 
  select(ID, Name)

## Create template raster ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

## Create a leading species raster for Forest classes ----
# Rasterize VRI leading species data and reclassify
speciesReclassMatrix <- matrix(data = c(0,1,2,3,4,0,41,42,43,44),
                               nrow = 5, 
                               ncol = 2)

speciesRaster <- rasterize(x = vriShapefile,
                           y = templateRaster,
                           field = "ledngID") %>% 
  classify(rcl = speciesReclassMatrix)

speciesRaster[is.na(speciesRaster)] <- 0
speciesRaster <- speciesRaster %>% 
  mask(mask = secondaryStratum)

## Create state class rasters ----
# Define land cover reclassification matrix
landcoverReclassMatrix <- matrix(data = c(21,22,24,25,28,29,31,41,42,43,44,47,48,
                                          49,51,52,55,56,61,62,71,81,82,84,85,88,
                                          89,91,
                                          20,20,20,20,20,20,30,40,40,40,40,40,40,
                                          40,50,50,50,50,60,60,70,20,20,20,20,20,
                                          20,90),
                                 nrow = 28,
                                 ncol = 2)

# Process raw land cover data
for(i in landCoverFilnames) {
  
  landcoverRaster <- rast(i) %>% 
    # Project, resample and mask raw AAFC land cover data
    project(y = crs(secondaryStratum), method = "near") %>% 
    resample(y = templateRaster) %>% 
    mask(mask = secondaryStratum) %>% 
    # Reclassify into broader land cover classes
    classify(rcl = landcoverReclassMatrix)
  
  # Combine landcover and species raster to make state class raster
  # If land cover = forest (4), add species code
  stateClassRaster <- ifel(speciesRaster == 0, speciesRaster + landcoverRaster, speciesRaster)
  
  # Create rasters that track both ownership and land cover
  ownershipLULC <- stateClassRaster + (secondaryStratum * 100)
  
  year <- names(landcoverRaster) %>% 
    str_remove("LU")
  
  outputFilename <- "lulc-ownership-" %>% str_c(year, ".tif")
  
  # Write to disk
  writeRaster(ownershipLULC,
              file.path(intermediatesDir, outputFilename),
              datatype = "INT2S",
              NAflag = -9999L,
              overwrite = TRUE)
}

## Set up GRASS Mapset ----
# Initiate GRASS in 'PrepareStateClass' mapset
if(doGRASSSetup) {
  # Manually set up empty GRASS database
  initGRASS(gisBase=gisBase, gisDbase=gisDbase, location = "a269", mapset='PERMANENT', override=TRUE)
  execGRASS("g.proj", georef = file.path(spatialModelInputsDir, "ownership-baseline.tif"), flags="c")
  
  # Initialize new mapset inheriting projection info
  execGRASS("g.mapset", mapset = "lulcChange", flags="c")
  
  # Import data
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "lulc-ownership-2000.tif"), output = "lulcOwnership2000", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "lulc-ownership-2005.tif"), output = "lulcOwnership2005", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "lulc-ownership-2010.tif"), output = "lulcOwnership2010", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "lulc-ownership-2015.tif"), output = "lulcOwnership2015", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "lulc-ownership-2020.tif"), output = "lulcOwnership2020", flags = c("overwrite", "o"))
} else {
  initGRASS(gisBase=gisBase, gisDbase=gisDbase, location = "a269", mapset='lulcChange', override=TRUE)
}

# Set the geographic region
execGRASS('g.region', n='819713', e='1309432', w='1229152', s='760673', res = '90') 

## Land cover change rates ----
# List ownership-landcover rasters
lulcOwnershipPairs <- tibble(reference = c("lulcOwnership2000", "lulcOwnership2005", "lulcOwnership2010", "lulcOwnership2015"),
                             classification = c("lulcOwnership2005", "lulcOwnership2010", "lulcOwnership2015", "lulcOwnership2020"))

# Compute transition matrices
for(i in seq_along(lulcOwnershipPairs$reference)) {
  
  # Reference raster
  reference <- lulcOwnershipPairs$reference[i]
  
  # Classification raster
  classification <- lulcOwnershipPairs$classification[i]
  
  # Reference year
  referenceYear <- str_remove(reference, "lulcOwnership")
  
  # Classification year
  classificationYear <- str_remove(classification, "lulcOwnership")
  
  
  outputMatrix <- "transition-matrix-" %>% 
    str_c(referenceYear,
          "-",
          classificationYear,
          ".csv")
  
  # Compute error matrices  
  execGRASS('r.kappa',
            reference = reference,
            classification = classification,
            output = file.path(tabularDataDir, outputMatrix),
            flags = c('overwrite', "h", 'w'))

  # Format transition matrices
  # Load as data frames
  tm <- read.csv(file.path(tabularDataDir, outputMatrix),
                          sep = "\t",
                          header = FALSE)

  # Format to dataframe with col1 = time 1 and colnames = time 2
  # Get each panel
  tmp1 <- tm[4:37, 1:10]
  tmp2 <- tm[41:74, 1:10]
  tmp3 <- tm[78:111, 1:10]
  tmp4 <- tm[115:148, 1:7]
  
  # Head column name
  colName <- referenceYear %>% 
    str_c(" (C) to ", 
          classificationYear,
          " (R)")

  # Bind panels
  tm <- bind_cols(tmp1, tmp2[, 2:10], tmp3[, 2:10], tmp4[, 2:7])
  colnames(tm) <- c(colName, tm[1, 2:ncol(tm)])
  tm <- tm[2:nrow(tm),]
  tm[,1] <- colnames(tm)[2:ncol(tm)]
  rm(tmp1, tmp2, tmp3, tmp4)

  # Format final dataframe
  # Wide to long format
  lulcChange <- tm %>%
    gather(key = 'Source', value = 'CellCount', -colName) %>%
    rename(Destination = colName) %>%
    mutate_all(as.integer) %>%
    mutate(SourceOwnership = floor(Source/100),
           DestinationOwnership = floor(Destination/100)) %>%
    filter(SourceOwnership == DestinationOwnership) %>%
    mutate(Ownership = SourceOwnership,
           TimePeriod = referenceYear %>% 
             str_c(" - ", classificationYear),
           Source = Source %% 100,
           Destination = Destination %% 100) %>%
    select(TimePeriod, Ownership, Source, Destination, CellCount) %>%
    arrange(TimePeriod, Ownership, Source, Destination) %>%
    left_join(stateClassIds, by = c("Source" = "ID")) %>%
    rename(SourceStateClass = Name) %>%
    left_join(stateClassIds, by = c("Destination" = "ID")) %>%
    rename(DestStateClass = Name) %>%
    left_join(ownershipdIds, by = c("Ownership" = "ID")) %>%
    rename(OwnershipType = Name) %>%
    mutate(AreaHa = CellCount * scaleFactor,
           AnnualChangeRateHa = AreaHa/temporalResolution) %>%
    select(TimePeriod, OwnershipType, SourceStateClass, DestStateClass, AreaHa, AnnualChangeRateHa)
  
  outputFilename <- 'lulc-annual-rates-of-change-' %>% 
    str_c(referenceYear, "-", classificationYear, ".csv")
  
  # Export
  write_csv(lulcChange, file.path(tabularDataDir, outputFilename))
}

# Combine all dataframes
lulc2000_2005 <- read_csv(file.path(tabularDataDir, 'lulc-annual-rates-of-change-2000-2005.csv'))
lulc2005_2010 <- read_csv(file.path(tabularDataDir, 'lulc-annual-rates-of-change-2005-2010.csv'))
lulc2010_2015 <- read_csv(file.path(tabularDataDir, 'lulc-annual-rates-of-change-2010-2015.csv'))
lulc2015_2020 <- read_csv(file.path(tabularDataDir, 'lulc-annual-rates-of-change-2015-2020.csv'))

lulcChange <- lulc2000_2005 %>% 
  bind_rows(lulc2005_2010, lulc2010_2015, lulc2015_2020)

# Write to disk
write_csv(lulcChange, file.path(tabularModelInputsDir, "lulc-rates-of-change.csv"))

# Land cover change proportions ----
# Get area of each state class for each 5 year interval
lulcChange <- read_csv(file.path(tabularModelInputsDir, "lulc-rates-of-change.csv")) %>% 
  mutate(TimePeriod = TimePeriod %>% str_replace("-", "to"),
         Transition = SourceStateClass %>% str_c(" to ", DestStateClass))

totalAreaSourceStateClass <- lulcChange %>% 
  group_by(TimePeriod, OwnershipType, SourceStateClass) %>% 
  summarize(TotalAreaSourceStateClass = sum(AreaHa)) %>% 
  ungroup()

lulcChangeProportion <- lulcChange %>% 
  left_join(totalAreaSourceStateClass, by = c("TimePeriod", "OwnershipType", "SourceStateClass")) %>% 
  filter(DestStateClass == "Urban:All" | DestStateClass == "Cropland:All") %>%
  filter(SourceStateClass != "Urban:All" & SourceStateClass != "Cropland:All" & SourceStateClass != "Other:All") %>% 
  filter(AnnualChangeRateHa != 0) %>% 
  mutate(ProportionOfChange = AreaHa/TotalAreaSourceStateClass) %>% 
  select(-AnnualChangeRateHa, -TotalAreaSourceStateClass) 

### Create LULC transition multipliers ----
transitionMultipliers <- lulcChangeProportion %>% 
  group_by(OwnershipType, SourceStateClass, DestStateClass) %>% 
  summarise(Amount = mean(ProportionOfChange)) %>% 
  ungroup() %>% 
  rename(SecondaryStratumID = OwnershipType,
         StateClassID = SourceStateClass,
         TransitionGroupID = DestStateClass) %>% 
  mutate(TransitionGroupID = case_when(TransitionGroupID == "Cropland:All" ~ "LULC: -> Cropland [Type]",
                                       TransitionGroupID == "Urban:All" ~ "LULC: -> Urban [Type]"))

# Add rows for all other Forest state classes
forestMultipliers <- expand.grid(SecondaryStratumID = c("Private", "Protected", "Public"),
                                 StateClassID = c("Forest:Aspen", "Forest:Pine", "Forest:Spruce", "Forest:Fir"),
                                 TransitionGroupID = c("LULC: -> Cropland [Type]", "LULC: -> Urban [Type]")) %>% 
  left_join(transitionMultipliers %>% filter(StateClassID == "Forest:Unknown"), 
            by = c("SecondaryStratumID", "TransitionGroupID")) %>% 
  rename(StateClassID = StateClassID.x) %>% 
  select(-StateClassID.y)

# Combine multipliers
transitionMultipliers <- transitionMultipliers %>% bind_rows(forestMultipliers)

# Save to disk
write_csv(transitionMultipliers, 
          file.path(tabularModelInputsDir, "Transition Multipliers - LULC Proportions.csv"))

### Create LULC Distribution ----
lulcDistribution <- lulcChange %>% 
  filter(DestStateClass == "Urban:All" | DestStateClass == "Cropland:All") %>% 
  filter(SourceStateClass != "Urban:All" & SourceStateClass != "Cropland:All" & SourceStateClass != "Other:All") %>% 
  mutate(AnnualChangeRateHa = case_when(OwnershipType == "Protected" ~ 0,
                                        OwnershipType == "Public" ~ AnnualChangeRateHa,
                                        OwnershipType == "Private" ~ AnnualChangeRateHa)) %>% 
  group_by(TimePeriod, OwnershipType, DestStateClass) %>% 
  summarise(Value = sum(AnnualChangeRateHa)) %>% 
  ungroup() %>% 
  rename(ExternalVariableMin = TimePeriod,
         SecondaryStratumID = OwnershipType, 
         DistributionTypeID = DestStateClass) %>% 
  mutate(ExternalVariableMin = case_when(ExternalVariableMin == "2000 to 2005" ~ 1,
                                         ExternalVariableMin == "2005 to 2010" ~ 2,
                                         ExternalVariableMin == "2010 to 2015" ~ 3, 
                                         ExternalVariableMin == "2015 to 2020" ~ 4),
         ExternalVariableMax = ExternalVariableMin, 
         DistributionTypeID = case_when(DistributionTypeID == "Cropland:All" ~ "Historic LULC -> Cropland",
                                        DistributionTypeID == "Urban:All" ~ "Historic LULC -> Urban"),
         ExternalVariableTypeID = "Historic LULC 5 Year Period") %>% 
  select(SecondaryStratumID, DistributionTypeID, ExternalVariableTypeID, ExternalVariableMin, ExternalVariableMax, Value)

# Save to disk
write_csv(lulcDistribution, 
          file.path(tabularModelInputsDir, "Distributions - LULC.csv"))

## Plots ----
### Annual rates of change ----
lulcChange <- read_csv(file.path(tabularModelInputsDir, "lulc-rates-of-change.csv")) %>% 
  filter(DestStateClass == "Urban:All" | DestStateClass == "Cropland:All") %>% 
  filter(SourceStateClass != "Urban:All" & SourceStateClass != "Cropland:All") %>% 
  filter(AnnualChangeRateHa != 0) %>% 
  mutate(TimePeriod = TimePeriod %>% str_replace("-", "to"),
         Transition = SourceStateClass %>% str_c(" to ", DestStateClass))

lulcChangePlot <- lulcChange %>% 
  ggplot(aes(x = Transition, y = AnnualChangeRateHa)) +
  geom_bar(stat = "identity") +
  facet_grid(OwnershipType ~ TimePeriod) +
  ylab("Annual rate of change (ha/yr)") + 
  xlab("State Class Transition") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggsave(filename = file.path(plotDir, "lulc-annual-rate-of-change.png"), 
       plot = lulcChangePlot, 
       width = 10, 
       height = 8, 
       dpi = 300)

### Proportion of area transitioned ----
# Get area of each state class for each 5 year interval
lulcChange <- read_csv(file.path(tabularModelInputsDir, "lulc-rates-of-change.csv")) %>% 
  mutate(TimePeriod = TimePeriod %>% str_replace("-", "to"),
         Transition = SourceStateClass %>% str_c(" to ", DestStateClass))

totalAreaSourceStateClass <- lulcChange %>% 
  group_by(TimePeriod, OwnershipType, SourceStateClass) %>% 
  summarize(TotalAreaSourceStateClass = sum(AreaHa)) %>% 
  ungroup()

lulcChangeProportion <- lulcChange %>% 
  left_join(totalAreaSourceStateClass, by = c("TimePeriod", "OwnershipType", "SourceStateClass")) %>% 
  filter(DestStateClass == "Urban:All" | DestStateClass == "Cropland:All") %>%
  filter(SourceStateClass != "Urban:All" & SourceStateClass != "Cropland:All" ) %>% 
  filter(AnnualChangeRateHa != 0) %>% 
  mutate(ProportionOfChange = AreaHa/TotalAreaSourceStateClass) %>% 
  select(-AnnualChangeRateHa)

lulcChangeProportionPlot <- lulcChangeProportion %>% 
  ggplot(aes(x = Transition, y = ProportionOfChange)) +
  geom_bar(stat = "identity") +
  facet_grid(OwnershipType ~ TimePeriod) +
  ylab("Proportion of Source State Class Transitioned") + 
  xlab("State Class Transition") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggsave(filename = file.path(plotDir, "proportion-source-state-class-transitioned-2.png"), 
       plot = lulcChangeProportionPlot, 
       width = 10, 
       height = 8, 
       dpi = 300)
