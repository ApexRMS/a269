# NestWeb Habitat Model

This repo contains scripts that prepare spatial and tabular inputs, run habitat models on stsimsf stock projections, and forecasts total amount of available habitat for select woodpecker species in BC, Canada.

Scripts in this repo perform the following tasks:

1-data-preprocessing.R: Calculates % aspen cover for each polygon in the VRI dataset and samples VRI data from sample plot coordinates.

2.0-generate-spatial-model-inputs.R: Generates spatial input data for the stsimsf model, including the primary and secondary strata, state class, time since cut, age, and initial stock rasters.

2.1-impute-site-raster.R: Performs nearest neighbour imputation on sample plot IDs to create a contiguous site raster.

3-historic-fire-analysis.R: Computes the annual probability of historic fires, the normalized fire distribution, and the fire size class distribution.  

4-historic-logging-analysis.R: Computes the annual probability of clearcutting and the clearcut size class distribution. 

5-lulc-change-analysis.R: Computes the annual rate of conversion to developed or agricultural land.

6-model-variables.R: Models % aspen cover and quadratic mean diameter as a function of stand age using natural cubic splines.

7-build-library.R: Creates an stsimsf SyncroSim library, loads Project and Scenario-scope datasheets, and builds management scenarios.

8-post-processing.R: Runs habitat model on stsimsf stock outputs to generate predicted habitat (draft transformer script).
