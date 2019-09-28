# This file reads gdp / cap data from three sources (WDI, maddison, PWT), formats and saves it.
library(tidyverse)
library(haven)

# pwt9 contains the penn world tables v9
library(pwt9)
# wdi contains api for wdi
library(WDI)
# maddison conatains the maddison database, updated 2018
# install_github("expersso/maddison")
library(maddison)

## OUTPUT PATH
output_dir <- "../data/joined_gdp_cap.csv"

################
### WDI data ###
################
# WDI data is from: https://databank.worldbank.org/source/world-development-indicators#
# Measured in constant 2011 intl dollars (PPP)

wdi <- as_tibble(WDI(country = "all", 
		      indicator = "NY.GDP.PCAP.PP.CD",
		      extra = TRUE,
		      start = NULL))

wdi_tidy <- wdi %>%
	select(country = iso3c, year, wdi_gdp_cap = NY.GDP.PCAP.PP.CD) %>%
	mutate_if(is.factor, as.character)

#####################
### Maddison data ###
#####################

# Maddison data is from: https://www.rug.nl/ggdc/historicaldevelopment/maddison/
mad <- as_tibble(maddison)

# for computing relative growth rates, authors recommend the RGDPNApc
mad_tidy <- mad %>%
	select(country = iso3c, year, mad_gdp_cap = rgdpnapc)

################
### PWT data ###
################

# pwt data is from https://www.rug.nl/ggdc/productivity/pwt
pwt_tidy <- as_tibble(pwt9.1) %>%
	select(country = isocode, year, rgdpe, pop) %>% 
	mutate(pwt_gdp_cap = rgdpe / pop) %>% 
	mutate_if(is.factor, as.character) %>%
	select(country, year, pwt_gdp_cap)

#######################
### join the frames ###
#######################
joined <- wdi_tidy %>%
	left_join(mad_tidy) %>%
	left_join(pwt_tidy) 

write_csv(joined, output_dir)
