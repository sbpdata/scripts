# This file takes in the international trade database 
# distributed by MITs observatory of economic complexity,
# filters it and returns a tidy version. This script
# uses the SITC 4-digit, second revision series. 
# the link to the download page is:
# https://oec.world/en/resources/data/
# this script does not use the time-dependet filters.
# also, note that or every year, the panel is balanced

### READ DATA ###
library(tidyverse)
library(here)
library(vroom)
library(WDI)

sitc_path <- here("../data/trade/sitc-rev2/year_origin_sitc_rev2.tsv")
output_path <- here("../data/sitc-rev2_tidy.csv")
sitc_raw <- vroom(sitc_path, delim = "\t")

sitc <- sitc_raw %>%
	mutate(
	       export_val = as.numeric(export_val),
	       export_rca = as.numeric(export_rca)
	       ) %>%
	select(
	       time = year,
	       region = origin,
	       unit = sitc4,
	       intensity = export_val,
	       rca = export_rca
	       )


### WITOUT TIME DEPENDENT FILTERS ###

# following filters are used:
# - countries must have a total export value > 1 bill in 2008
# - countries must have a population of at least 1.25 mio in 2008
# - countries must have data in 2008
# - countries must not be Tchad (TCD), Iraq (IRQ), Afghanistan (AFG)

# For other boundaries, change below:
ref_year <- 2008
ref_export <- 1000000000
ref_pop <- 1250000
ref_reliable <- c("afg", "tcd", "irq")

# DEFINE SETS 
# Get set of countries with exports > 1 bill in 2008
export_set <- sitc %>% 
	filter(time == ref_year) %>%
	group_by(region) %>%
	summarise(
		  total_export = sum(intensity)
		  ) %>%
	filter(total_export >= ref_export) %>%
	pull(region)

# Get set of countries with population > 1.25 mio in 2008
pop_raw <- WDI(country = "all", indicator = "SP.POP.TOTL", extra = TRUE) %>%
	as_tibble()

pop_data <- pop_raw %>% 
	mutate_if(is.factor, as.character) %>%
	mutate(
	       region = str_to_lower(iso3c)
	       ) %>%
	select(
	       time = year, 
	       region,
	       pop = SP.POP.TOTL
	       )

pop_set <- pop_data %>%
	filter(time == ref_year & pop >= ref_pop) %>%
	pull(region)


# Get set for countries with data in 2010
available_set <- sitc %>%
	filter(time == ref_year) %>%
	pull(region) %>%
	unique()

# Get set of reliable countries
reliable_set <- sitc %>%
	filter(!(region %in% ref_reliable)) %>%
	pull(region) %>%
	unique()
 
# APPLY SET
sitc_filtered <- sitc %>%
	filter(region %in% export_set) %>%
	filter(region %in% pop_set) %>% 
	filter(region %in% available_set) %>%
	filter(region %in% reliable_set) 

# There are only NA values in intensity and in RCA,
# which is a remnant from coercing them from chr to dlb
# (before they were NULL). I set these to 0.

sitc_filtered[is.na(sitc_filtered)] <- 0

# COMPLETE PANEL
# I now make sure that for each region present in a year,
# there is an observation for each product. Those not present
# are created as NA values. I set these to 0.

sitc_tidy <- sitc_filtered %>% 
	group_by(time) %>%  
	complete(region, unit)

sitc_tidy[is.na(sitc_tidy)] <- 0

### WRITE FILE ###
write_csv(sitc_tidy, output_path)

