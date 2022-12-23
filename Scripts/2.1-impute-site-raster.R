## a296
## Sarah Chisholm (ApexRMS)
## December 21 2022
##
## Generate imputed site raster

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
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")
modelInputsDir <- file.path("Model-Inputs", "Spatial")
intermediatesDir <- "Intermediates"

# Parameters
# Create GRASS mapset?
doGRASSSetup <- FALSE

# Target crs
targetCrs <- "epsg: 3005"

# Target extent
targetExtent <- c(1229152, 1309432, 760673, 819713)

# Target resolution
targetResolution <- 90

# Load spaital data
# VRI shapefile (appended with aspen cover)
samplePlots <- st_read(dsn = spatialDataDir, 
                       layer = "eccc-sample-plot-data-append-vri")

# Primary stratum raster
primaryStratum <- rast(file.path(modelInputsDir, "primary-stratum.tif"))

# State class raster
stateClass <- rast(file.path(modelInputsDir, "state-class.tif"))

## Template raster ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

## Prep and rasterize shapefile ----
# Get a vector of unique Sites
uniqueSites <- samplePlots %>% # zzz: confirm that these are the correct Site IDs
  select(Site_x) %>%
  pull(Site_x) %>% 
  unique

# Create a vector of integers of length(uniqueSites)
siteIDs <- seq(1, length(uniqueSites))

# Assign an integer to each unique site
siteRasterValues <- tibble(
  Site = uniqueSites,
  Value = siteIDs) %>% 
  write_csv(file.path(tabularDataDir, "imputed-site-raster-crosswalk.csv"))

# Join unique raster IDs to samplePlots shapefile and rasterize
# zzz: this results in a raster that omits 4 site IDs (14, 35, 39, 43)
#       Revisit this issue when generating the finalized site map
site <- samplePlots %>% 
  left_join(siteRasterValues, by = c("Site_x" = "Site")) %>% 
  rasterize(y = templateRaster,
            field = "Value",
            filename = file.path(intermediatesDir, "site.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

## Prep combined initial conditions rasters ----
# Create raster of unique BEC variant and state class combinations
stratum <- ((primaryStratum * 100) + stateClass) %>% 
  writeRaster(filename = file.path(intermediatesDir, "bec-variant-state-class.tif"),
              datatype = "INT2S",
              NAflag = -9999L,
              overwrite = TRUE)

## Set up GRASS Mapset ----
# Initiate GRASS in 'siteImputation' mapset
if(doGRASSSetup) {
  # Manually set up empty GRASS database
  initGRASS(gisBase=gisBase, gisDbase=gisDbase, location = "a269", mapset='PERMANENT', override=TRUE)
  execGRASS("g.proj", georef = file.path(intermediatesDir, "site.tif"), flags="c")
  
  # Initialize new mapset inheriting projection info
  execGRASS("g.mapset", mapset = "siteImputation", flags="c")
  
  # Import data
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "site.tif"), output = "site", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(intermediatesDir, "bec-variant-state-class.tif"), output = "strata", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(modelInputsDir, "state-class.tif"), output = "state-class", flags = c("overwrite", "o"))
  execGRASS('r.in.gdal', input = file.path(modelInputsDir, "primary-stratum.tif"), output = "primary-stratum", flags = c("overwrite", "o"))
} else {
  initGRASS(gisBase=gisBase, gisDbase=gisDbase, location = "a269", mapset='siteImputation', override=TRUE)
}

# Set the geographic region
execGRASS('g.region', n='819713', e='1309432', w='1229152', s='760673', res = '90') 

## Impute Site ID ----
### By BEC and State Class ----
# For each unique combination of BEC variant and state class, assign NA cells in 
# the site raster with the nearest site value. 
uniqueStrataCombos <- freq(stratum) %>% 
  select(value)

for(i in uniqueStrataCombos$value) {
  
  outputFilename <- str_c("imputed-site-", i)
  
  # 1) Apply strata raster as a mask to the mapset
  execGRASS('r.mask', raster = 'strata', maskcats = i %>% as.character)
  
  # 2) Perform the nearest neighbour imputation
  execGRASS('r.grow.distance', input = 'site', value = outputFilename, flags = 'overwrite')
  
  # 3) If values in the output are != 0, save the imputed raster to disk, else
  #    perform the masking and imputation again, stratified by the state class
  
  # Get unique values in the imputed raster
  reportFilename = file.path(intermediatesDir, str_c("report-", i, ".csv"))
  execGRASS('r.report', map = outputFilename, output = reportFilename, flags = c('h', 'i', 'overwrite'))
  
  report <- read_csv(reportFilename)
  
  # Write out imputed raster if minimum value != 0
  if((!report[4, , drop = TRUE] %>% str_detect("0"))) {
    execGRASS('r.out.gdal', input = outputFilename, output = file.path(intermediatesDir, str_c(outputFilename, "-checked.tif")), format = 'GTiff', type = "Int16", nodata = -9999, flags = c('f', 'overwrite'))
  } 
  
  # Remove active mask before processing next stratum ID
  execGRASS('r.mask', flags = 'r')
}

# Check if imputation was successful for each stratum
 reportSummaries <- map_dfr(uniqueStrataCombos$value, 
~{
  reportFilename = file.path(intermediatesDir, str_c("report-", .x, ".csv"))
  report <- read_csv(reportFilename)
  
  output <- tibble(
    StratumId = .x %>% as.character,
    SuccessfulImputation = !report[4, , drop = TRUE] %>% str_detect("0"))
})

# Identify successfully imputed rasters
successfulImputations <- reportSummaries %>% 
   filter(SuccessfulImputation == "TRUE") %>% 
   pull(StratumId)

# Create an empty raster with the correct dimensions
imputedSite <- setValues(templateRaster, NA)

# Load successfully imputed rasters by strata and merge into one
for(i in successfulImputations) {
  
  rasterFilename <- str_c("imputed-site-", i, ".tif")
  imputedRaster <- rast(file.path(intermediatesDir, rasterFilename))
  
  imputedSite <- merge(imputedSite, imputedRaster)
}

### By State Class ----
# Identify state classes for unsuccessfully imputed rasters
stateClassesToImpute <- reportSummaries %>% 
  filter(SuccessfulImputation == "FALSE") %>% 
  select(StratumId) %>% 
  mutate(StateClass = StratumId %>% str_sub(2,3)) %>% 
  pull(StateClass) %>% 
  unique

# Repeat exercise for stratum values that did not contain any site IDs
for(i in stateClassesToImpute) {
  
  outputFilename <- str_c("imputed-site-", i)
  
  # 1) Apply stateClass raster as a mask to the mapset
  execGRASS('r.mask', raster = 'state-class', maskcats = i)
  
  # 2) Perform the nearest neighbour imputation
  execGRASS('r.grow.distance', input = 'site', value = outputFilename, flags = 'overwrite')
  
  # 3) If values in the output are != 0, save the imputed raster to disk, else
  #    perform the masking and imputation again, stratified by the state class
  
  # Get unique values in the imputed raster
  reportFilename = file.path(intermediatesDir, str_c("report-", i, ".csv"))
  execGRASS('r.report', map = outputFilename, output = reportFilename, flags = c('h', 'i', 'overwrite'))
  
  report <- read_csv(reportFilename)
  
  # Write out imputed raster if minimum value != 0
  if((!report[4, , drop = TRUE] %>% str_detect("0"))) {
    execGRASS('r.out.gdal', input = outputFilename, output = file.path(intermediatesDir, str_c(outputFilename, ".tif")), format = 'GTiff', type = "Int16", nodata = -9999, flags = c('f', 'overwrite'))
  } 
  
  # Remove active mask before processing next stratum ID
  execGRASS('r.mask', flags = 'r')
}
  
# Load successfully imputed rasters by state class, mask by imputedSite, and merge
for(i in stateClassesToImpute[stateClassesToImpute != 90]) {
  
  rasterFilename <- str_c("imputed-site-", i, ".tif")
  imputedRaster <- rast(file.path(intermediatesDir, rasterFilename)) %>% 
    mask(mask = imputedSite,
         inverse = TRUE)
  
  imputedSite <- merge(imputedSite, imputedRaster)
}

### By BEC ----
# Find BEC variants that overlap with state class value 90
otherAll <- stateClass
otherAll[otherAll != 90] <- NA

becVariantsToImpute <- primaryStratum %>% 
  mask(mask = otherAll) %>% 
  freq() %>% 
  pull(value)

# Repeat exercise for state class values that did not contain any site IDs (90)
for(i in becVariantsToImpute) {
  
  outputFilename <- str_c("imputed-site-", i)
  
  # 1) Apply stateClass raster as a mask to the mapset
  execGRASS('r.mask', raster = 'primary-stratum', maskcats = i %>% as.character)
  
  # 2) Perform the nearest neighbour imputation
  execGRASS('r.grow.distance', input = 'site', value = outputFilename, flags = 'overwrite')
  
  # 3) If values in the output are != 0, save the imputed raster to disk, else
  #    perform the masking and imputation again, stratified by the state class
  
  # Get unique values in the imputed raster
  reportFilename = file.path(intermediatesDir, str_c("report-", i, ".csv"))
  execGRASS('r.report', map = outputFilename, output = reportFilename, flags = c('h', 'i', 'overwrite'))
  
  report <- read_csv(reportFilename)
  
  # Write out imputed raster if minimum value != 0
  if((!report[4, , drop = TRUE] %>% str_detect("0"))) {
    execGRASS('r.out.gdal', input = outputFilename, output = file.path(intermediatesDir, str_c(outputFilename, ".tif")), format = 'GTiff', type = "Int16", nodata = -9999, flags = c('f', 'overwrite'))
  } 
  
  # Remove active mask before processing next stratum ID
  execGRASS('r.mask', flags = 'r')
}

# Load successfully imputed rasters by bec variant, mask by imputedSite, and merge
for(i in becVariantsToImpute[becVariantsToImpute != 1]) {
  
  rasterFilename <- str_c("imputed-site-", i, ".tif")
  imputedRaster <- rast(file.path(intermediatesDir, rasterFilename)) %>% 
    mask(mask = imputedSite,
         inverse = TRUE)
  
  imputedSite <- merge(imputedSite, imputedRaster)
}

# Save the imputed site map to disk
writeRaster(imputedSite,
            file.path(intermediatesDir, "partially-imputed-site.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

### Fill gaps ----
# Perform a final nearest neighbour imputation for the stratum ID 190, which
# contains no sites in both the state class and BEC variant.
outputFilename <- file.path(modelInputsDir, "site.tif")

execGRASS('r.in.gdal', input = file.path(intermediatesDir, "partially-imputed-site.tif"), output = "partially-imputed-site", flags = c("overwrite", "o"))
execGRASS('r.mask', raster = 'primary-stratum')
execGRASS('r.grow.distance', input = 'partially-imputed-site', value = "site-final", flags = 'overwrite')
execGRASS('r.out.gdal', input = "site-final", output = outputFilename, format = 'GTiff', type = "Int16", nodata = -9999, flags = c('f', 'overwrite'))
execGRASS('r.mask', flags = 'r')
