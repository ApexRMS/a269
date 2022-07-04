## a296
## Sarah Chisholm (ApexRMS)
## June 30 2022
##
## Build cavity nests st-sim library

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(rsyncrosim)
library(tidyverse)
library(terra)
library(sf)

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")
modelInputsDir <- "Model-Inputs"

# Parameters
# Target crs
targetCrs <- "epsg: 3005"

# Target extent
targetExtent <- c(1229152, 1309432, 760673, 819713)

# of columns: 892
# # of rows: 656

# Target resolution
targetResolution <- 90

# Load spaital data
# VRI shapefile (appended with aspen cover)
vriShapefile <- vect(x = file.path(".", "vri-aspen-percent-cover.shp"))

# st_read(dsn = spatialDataDir,
#                       layer = "vri-aspen-percent-cover")

# AAFC Land Cover raster

## Generate Strata ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

# Primary Stratum ----
becVariantRaster <- rasterize(x = vriShapefile,
                              y = templateRaster, 
                              field = "BEC_VAR_")

# State Class ----

# Age Raster ----
ageRaster <- rasterize(x = vriShapefile,
                       y = templateRaster,
                       field = "PROJ_AGE_1")

# Write rasters to disk
# Primary stratum
writeRaster(x = becVariantRaster,
            filename = file.path(modelInputsDir, "primary-stratum.tiff"),
            overwrite = TRUE)

# State Class

# Age Raster
writeRaster(x = ageRaster,
            filename = file.path(modelInputsDir, "age.tiff"),
            overwrite = TRUE)

