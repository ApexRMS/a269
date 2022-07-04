## a269
## Shree Senthivasan, Sarah Chisholm 
## July 4, 2022
##
## Model % aspen cover and quadratic mean diameter as a function of age of 
## leading species using natural splines 

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(tidyverse)
library(sf)
library(splines)

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")

# Load data
# Group common species
vri <- st_read(dsn = spatialDataDir, layer = "vri-aspen-percent-cover") %>% 
  mutate(LEADING = case_when(LEADING == "Trembling Aspen" ~ "Trembling Aspen",
                             LEADING == "Lodgepole Pine (Interior)" ~ "Lodgepole Pine",
                             LEADING == "Douglas Fir Interior" ~ "Douglas Fir",
                             LEADING == "Spruce Hybrid" ~  "Spruce Hybrid",
                             LEADING == "Douglas Fir" ~ "Douglas Fir",
                             LEADING == "Lodgepole Pine" ~ "Lodgepole Pine",
                             LEADING == "Lodgepole Pine (Coast)" ~ "Lodgepole Pine",
                             LEADING == "Poplar" ~ "Poplar",
                             LEADING == "White Spruce" ~ "White Spruce",
                             LEADING == "Black Cottonwood" ~ "Black Cottonwood",
                             LEADING == "Paper Birch" ~ "Paper Birch",
                             LEADING == "Subalpine Fir" ~ "Subalpine Fir",
                             LEADING == "Yellow Pine" ~ "Yellow Pine",
                             LEADING == "Western Hemlock" ~ "Western Hemlock"))

# Testing: assessment of non-linearity ----
testVri <- vri %>% 
  as.data.frame %>% 
  as_tibble %>% 
  filter(BEC_ZONE_S == BEC_ZONE_S[1]) %>% 
  filter(LEADING == "Trembling Aspen") %>% 
  dplyr::select(aspen = AT_PCT, qmd = DIAM_12, age = PROJ_AGE_1) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(qmd))

# View data
testVri %>% 
  ggplot(aes(age, qmd)) + 
  geom_point()

# Test models - check linearity
modl <- lm(qmd ~ age, data = testVri)
plot(testVri$age, testVri$qmd)
lines(testVri$age, fitted(modl))

modp <- lm(qmd ~ poly(age, 4), data = testVri)
plot(testVri$age, testVri$qmd)
lines(testVri$age, fitted(modp))

modns <- lm(qmd ~ ns(age, df = 4), data = testVri)
plot(testVri$age, testVri$qmd)
lines(testVri$age, fitted(modns), col = "red")

# Stratify by BEC and leading species ----
listVri <- vri %>% 
  as.data.frame() %>% 
  dplyr::select(bec = BEC_ZONE_S, species = LEADING, aspen = AT_PCT, qmd = DIAM_12, age = PROJ_AGE_1) %>% 
  filter(!is.na(age)) %>% 
  arrange(age) %>% 
  filter(!is.na(qmd)) %>% # To do: handle NA qmd or re-filter for aspen
  group_by(bec, species) %>% 
  group_split 
  
# Fit splines ----
# Compare different spline fits
# modns
modns <- map(listVri,
    function(subset) lm(qmd ~ns(age, df = 3, Boundary.knots = c(0, 150)), data = subset)) 

# modns2
modns2 <- map(listVri,
             function(subset) lm(qmd ~ns(age, df = 3, Boundary.knots = c(0, 200)), data = subset)) 

# Predicted QMD as a function of age and BEC ----
#vriFitted <- map2_dfr(listVri, modns, ~.x %>% mutate(qmdFitted = fitted(.y)))
  vriFitted <- map2(listVri, modns, ~.x %>% mutate(qmdFitted = fitted(.y))) %>% 
  map2_dfr(modns2, ~.x %>% mutate(qmdFitted2 = fitted(.y)))

# Plot predicted QMD
vriFitted %>% 
  filter(!species %in% c("Black Cottonwood", "Paper Birch", "Poplar", "Subalpine Fir", "White Spruce")) %>% 
  ggplot(aes(age)) +
  geom_point(aes(y = qmd), size = 0.5, alpha = 0.1) +
  geom_line(aes(y = qmdFitted), size = 0.5, colour = "red") +
  #geom_line(aes(y = qmdFitted2), size = 0.5, colour = "dodgerblue") +
  facet_grid(species ~ bec) +
  ylim(c(0, 100))

# Get derivative of QMD with respect (wrt) to age as a function of age and BEC ----
agedf <- data.frame(age = seq(300))

vriDelta <- map2_dfr(modns, listVri, 
     function(model, dataSubset) {
       bec <- dataSubset$bec[1]
       species <- dataSubset$species[1]
       tibble(bec = bec,
              species = species,
              age = agedf$age,
              qmdPredicted = predict(model, agedf),
              qmdDelta = lead(qmdPredicted) - qmdPredicted)
     })

vriDelta %>% 
  filter(!species %in% c("Black Cottonwood", "Paper Birch", "Poplar", "Subalpine Fir", "White Spruce")) %>%
  ggplot(aes(age)) +
  #geom_point(aes(y = qmd), size = 0.5, alpha = 0.1, data = vriFitted) +
  geom_line(aes(y = qmdDelta), size = 0.5, colour = "red") +
  #geom_line(aes(y = qmdFitted), size = 0.5, colour = "dodgerblue", data = vriFitted) +
  facet_grid(species ~ bec) 
  #ylim(c(0, 100))
