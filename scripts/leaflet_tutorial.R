library(tidyverse) # for general data munging
library(leaflet) # the main mapping library
library(htmltools) # use html to format popups
library(htmlwidgets) # same the map as an html page
library(geojsonio) # deal with geojson files
library(stringi) # deal with accents indifferent languages

# Import the data with the numbers you want to visualize
brazil <- read_csv("data/acled_brazil_22.csv")

# Import a geojson file with the outlines of each states in Brazil
brazil_geo <- geojson_read("data/brazil_estados.geojson",
                           what = "sp") 

# Create a column with state names but no accents for merging the datasets  
brazil_geo@data$shapeNameSimple <- stri_trans_general(
  str = brazil_geo@data$shapeName, id = "Latin-ASCII")

# One dataset has "Federal District," the other "Distrito Federal." This
# makes everything consistent.
brazil_geo@data$shapeNameSimple <- ifelse(
  brazil_geo@data$shapeNameSimple == "Federal District", "Distrito Federal",
  brazil_geo@data$shapeNameSimple)

# It can be tricky merging with shapefiles. `match` with the state names in 
# each dataset lets us get the fatalities variable where we need it in the
# spatial dataframe
brazil_geo$fatalities <- brazil$FATALITIES[match(brazil_geo$shapeNameSimple,
                                                 brazil$ADMIN1)]

# this defines your popup with some HTML for styling. In bold, we'll have the
# `stateName`, then a new line (<br/>), then `fatalities` followed by 
# " fatalities in 2023"
labels <- sprintf(
  "<strong>%s</strong><br/>%g fatalities in 2023",
  brazil_geo$shapeName, brazil_geo$fatalities
) %>% lapply(htmltools::HTML)

# Here we create a custom color palate. The miminum value is #FAFAFA, the max
# is #B31536. The rage goes from 0, to the max in our dataset for `fatalities`
pal <- colorNumeric(c("#FAFAFA", "#B31536"),
                    domain = c(0, max(brazil_geo$fatalities)))

# leaflet builds the underlying map and adds our dataset to it
leaflet(brazil_geo, options = leafletOptions(zoomControl = FALSE)) %>%
  # this allows you the change the background with a bunch of default themes
  addProviderTiles(providers$CartoDB.Positron, 
                   options = providerTileOptions(minZoom = 0)) %>%
  # and this adds the colored state outlines on top of the map 
   addPolygons(
    fillColor = ~pal(fatalities),
    weight = 1,
    opacity = 1,
    color = "#3B3B3B",
    fillOpacity = .8,
    highlightOptions = highlightOptions(
      weight = 2,
      bringToFront = TRUE),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto")) 
