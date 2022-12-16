## a269
## Shree Senthivasan, Sarah Chisholm 
## July 4, 2022
##
## Model % aspen cover and quadratic mean diameter as a function of age and 
## leading species using natural splines 

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(tidyverse)
library(sf)
library(splines)
library(broom)

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")
plotDir <- file.path("Plots")

# Load data
# Group common species, remove Bunch Grass BEC zone (insufficient data)
vri <- st_read(dsn = spatialDataDir, layer = "vri-aspen-percent-cover") %>% 
  filter(BEC_ZONE_C != "BG") %>% 
  mutate(LEADING = case_when(LEADING == "Trembling Aspen" ~ "Aspen",
                             LEADING == "Lodgepole Pine (Interior)" ~ "Pine",
                             LEADING == "Douglas Fir Interior" ~ "Fir",
                             LEADING == "Spruce Hybrid" ~  "Spruce",
                             LEADING == "Douglas Fir" ~ "Fir",
                             LEADING == "Lodgepole Pine" ~ "Pine",
                             LEADING == "Lodgepole Pine (Coast)" ~ "Pine",
                             LEADING == "Poplar" ~ "Aspen",
                             LEADING == "White Spruce" ~ "Spruce",
                             LEADING == "Black Cottonwood" ~ "Aspen",
                             LEADING == "Paper Birch" ~ "Aspen",
                             LEADING == "Subalpine Fir" ~ "Fir",
                             LEADING == "Yellow Pine" ~ "Pine",
                             LEADING == "Western Hemlock" ~ "Fir")) %>% 
  mutate(BEC_ZONE_C = case_when(BEC_ZONE_C == "SBPS" ~ "Sub-Boreal Pine - Spruce",
                                BEC_ZONE_C == "SBS" ~ "Sub-Boreal Spruce", 
                                BEC_ZONE_C == "IDF" ~ "Interior Douglas Fir"))

## Assessment of non-linearity ----
# Consider removing testing section
## QMD
qmdTest <- vri %>% 
  as.data.frame %>% 
  as_tibble %>% 
  filter(BEC_ZONE_C == BEC_ZONE_C[1]) %>% 
  filter(LEADING == "Trembling Aspen") %>% 
  dplyr::select(qmd = DIAM_12, age = PROJ_AGE_1) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(qmd))

# View data
qmdTest %>% 
  ggplot(aes(age, qmd)) + 
  geom_point()

# Test models - check linearity
modl <- lm(qmd ~ age, data = qmdTest)
plot(qmdTest$age, qmdTest$qmd)
lines(qmdTest$age, fitted(modl))

modp <- lm(qmd ~ poly(age, 4), data = qmdTest)
plot(qmdTest$age, qmdTest$qmd)
lines(qmdTest$age, fitted(modp))

modns <- lm(qmd ~ ns(age, df = 4), data = qmdTest)
plot(qmdTest$age, qmdTest$qmd)
lines(qmdTest$age, fitted(modns), col = "red")

# Memory management
rm(qmdTest, modl, modp, modns)

## Aspen cover
aspenTest <- vri %>% 
  as.data.frame %>% 
  as_tibble %>% 
  filter(BEC_ZONE_C == BEC_ZONE_C[1]) %>% 
  filter(LEADING == "Trembling Aspen") %>% 
  dplyr::select(aspen = AT_PCT, age = PROJ_AGE_1) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(aspen))

# View data
aspenTest %>% 
  ggplot(aes(age, aspen)) + 
  geom_point()

# Test models - check linearity
modl <- lm(aspen ~ age, data = aspenTest)
plot(aspenTest$age, aspenTest$aspen)
lines(aspenTest$age, fitted(modl))

modp <- lm(aspen ~ poly(age, 4), data = aspenTest)
plot(aspenTest$age, aspenTest$aspen)
lines(aspenTest$age, fitted(modp))

modns <- lm(aspen ~ ns(age, df = 4), data = aspenTest)
plot(aspenTest$age, aspenTest$aspen)
lines(aspenTest$age, fitted(modns), col = "red")

# Memory management
rm(aspenTest, modl, modp, modns)

## Stratify by BEC and leading species ----
# QMD
qmdVriList <- vri %>% 
  as.data.frame() %>% 
  dplyr::select(bec = BEC_ZONE_C, species = LEADING, age = PROJ_AGE_1, qmd = DIAM_12) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(qmd)) %>% 
  group_by(bec, species) %>% 
  group_split 

# Aspen cover
aspenVriList <- vri %>% 
  as.data.frame() %>% 
  dplyr::select(bec = BEC_ZONE_C, species = LEADING, age = PROJ_AGE_1, aspen = AT_PCT) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(aspen)) %>% 
  group_by(bec, species) %>% 
  group_split
  
## Fit splines ----
# QMD
# Compare different spline fits

# modns
qmdModns <- map(qmdVriList,
    function(subset) lm(qmd ~ns(age, df = 3, Boundary.knots = c(0, 150)), data = subset)) 

# modns2
qmdModns2 <- map(qmdVriList,
             function(subset) lm(qmd ~ns(age, df = 2, Boundary.knots = c(0, 150)), data = subset)) 

# Predicted QMD as a function of age and BEC
qmdFit <- map2(qmdVriList, qmdModns, ~.x %>% mutate(qmdFitted = fitted(.y))) %>% 
  map2_dfr(qmdModns2, ~.x %>% mutate(qmdFitted2 = fitted(.y)))

# Plot predicted QMD
qmdSplinePlot <- qmdFit %>% 
  filter(qmd <= 125) %>% 
  ggplot(aes(age)) +
  geom_point(aes(y = qmd), size = 0.5, alpha = 0.1) +
  geom_line(aes(y = qmdFitted), size = 0.5, colour = "red") +         # 3 df
  geom_line(aes(y = qmdFitted2), size = 0.5, colour = "dodgerblue") + # 2 df
  facet_grid(species ~ bec, scales = "free_y") +
  theme_bw()

# Save plot to disk
ggsave(
  filename = file.path(plotDir, "qmd-splines-update.png"),
  plot = qmdSplinePlot,
  device = "png", 
  width = 7,
  height = 8,
  dpi = 300)

# Memory management
rm(qmdFit, qmdSplinePlot)

# Aspen
# Compare different spline fits

# modns
aspenModns <- map(aspenVriList,
             function(subset) lm(aspen ~ns(age, df = 3, Boundary.knots = c(0, 125)), data = subset))

# modns2
aspenModns2 <- map(aspenVriList,
              function(subset) lm(aspen ~ns(age, df = 2, Boundary.knots = c(0, 125)), data = subset)) 

# Predicted aspen cover as a function of age and BEC
aspenFit <- map2(aspenVriList, aspenModns, ~.x %>% mutate(aspenFitted = fitted(.y))) %>% 
  map2_dfr(aspenModns2, ~.x %>% mutate(aspenFitted2 = fitted(.y)))

# Plot predicted aspen cover
aspenSplinePlot <- aspenFit %>% 
  ggplot(aes(age)) +
  geom_point(aes(y = aspen), size = 0.5, alpha = 0.1) +
  geom_line(aes(y = aspenFitted), size = 0.5, colour = "red") +  # df = 3
  geom_line(aes(y = aspenFitted2), size = 0.5, colour = "dodgerblue") + # df = 2
  facet_grid(species ~ bec, scales = "free_y") +
  theme_bw()

# Save plot to disk
ggsave(
  filename = file.path(plotDir, "aspen-splines-update.png"),
  plot = aspenSplinePlot,
  device = "png", 
  width = 7,
  height = 8,
  dpi = 300)

# Memory management
rm(aspenFit, aspenSplinePlot)

## Get derivative of QMD with respect to (wrt) age as a function of species and BEC ----
# Create data frame of all possible ages
ageDf <- data.frame(age = seq(300))

# QMD - 2 df
deltaQmd <- map2_dfr(qmdModns2, qmdVriList, 
     function(model, dataSubset) {
       bec <- dataSubset$bec[1]
       species <- dataSubset$species[1]
       tibble(bec = bec,
              species = species,
              age = ageDf$age,
              qmdPredicted = predict(model, ageDf),
              qmdDelta = lead(qmdPredicted) - qmdPredicted)
     })

# Aspen - 2 df
deltaAspen <- map2_dfr(aspenModns2, aspenVriList, 
     function(model, dataSubset) {
       bec <- dataSubset$bec[1]
       species <- dataSubset$species[1]
       tibble(bec = bec,
              species = species,
              age = ageDf$age,
              aspenPredicted = predict(model, ageDf),
              aspenDelta = lead(aspenPredicted) - aspenPredicted)
     })

# Summarize tabular data
derivatives <- tibble(
  bec = deltaAspen$bec,
  species = deltaAspen$species,
  age = deltaAspen$age,
  deltaAspen = deltaAspen$aspenDelta,
  deltaQmd = deltaQmd$qmdDelta
) %>% 
  drop_na()

# Save tabular data to disk
write_csv(derivatives, file.path(tabularDataDir, "state-attribute-values.csv"))

# Plot derivatives
# QMD
qmdDerivativesPlot <- derivatives %>% 
  ggplot(aes(age)) +
  geom_line(aes(y = deltaQmd), size = 0.5, colour = "red") +
  facet_grid(species ~ bec, scales = "free_y") +
  theme_bw()

# Save plot to disk
ggsave(
  filename = file.path(plotDir, "qmd-derivatives-2df-update.png"),
  plot = qmdDerivativesPlot,
  device = "png", 
  width = 13,
  height = 10,
  dpi = 300)

# Aspen cover
aspenDerivativesPlot <- derivatives %>% 
  ggplot(aes(age)) +
  geom_line(aes(y = deltaAspen), size = 0.5, colour = "red") +
  facet_grid(species ~ bec, scales = "free_y") +
  theme_bw()

# Save plot to disk
ggsave(
  filename = file.path(plotDir, "aspen-derivatives-2df-update.png"),
  plot = aspenDerivativesPlot,
  device = "png", 
  width = 13,
  height = 10,
  dpi = 300)

## Post fire stocks ----

# QMD intercepts
qmdPostFire <- 
  map2_dfr(qmdVriList, qmdModns2, 
           function(data, model) {
             output <- tibble(
               bec = data$bec[1],
               species = data$species[1],
               intercept = coef(model)[[1]])})

write_csv(qmdPostFire, file.path(tabularDataDir, "diameter-post-fire.csv"))
                                  
# Aspen Cover intercept
# aspenInterceptTable <- 
#   map2_dfr(aspenVriList, aspenModns2, 
#            function(data, model) {
#              output <- tibble(
#                bec = data$bec[1],
#                species = data$species[1],
#                intercept = coef(model)[[1]])})
# 
# write_csv(aspenInterceptTable, file.path(tabularDataDir, "aspen-cover-intercepts.csv"))

# Aspen Cover relative change
# Get the relative amount of change for a given age compared to the intercept
# Used to reset stocks after a fire - age-dependent
aspenPostFire <- 
  map2_dfr(aspenModns2, aspenVriList, 
           function(model, dataSubset) {
             bec <- dataSubset$bec[1]
             species <- dataSubset$species[1]
             tibble(bec = bec,
                    species = species,
                    age = ageDf$age,
                    aspenPredicted = predict(model, ageDf),
                    intercept = coef(model)[[1]],
                    # If there is a fire, for a given year, what is the change in aspen cover compared to the intercept
                    relativeChange = intercept - aspenPredicted)})

write_csv(aspenPostFire, file.path(tabularDataDir, "aspen-cover-post-fire.csv"))
