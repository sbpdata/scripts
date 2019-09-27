# This file reads gdp / cap data from three sources (WDI, maddison, PWT),
# formats it and saves it. 

import pandas as pd

################
### WDI data ###
################

# WDI data is from: https://databank.worldbank.org/source/world-development-indicators#
# Measured in constant 2011 intl dollars (PPP)

# read data, skipping first 4 lines (download date and empty)
wdi = pd.read_csv('~/sorensfolder/sbpdata/data/gdp/wdi/wdi_gdp_cap_2011ppp.csv')

# remove spaces from column names
wdi.columns = wdi.columns.str.replace(' ', '')

# change names
wdi.rename(columns={'CountryName':'country',
                    'CountryCode':'code'},
           inplace=True)

# drop indicator cols
wdi = wdi.drop(columns=['SeriesName', 'SeriesCode'])

# melt to tidy
wdi_tidy = pd.melt(wdi,
                   id_vars=['country', 'code'],
                   var_name='year',
                   value_name='gdp_cap')

# remove code from year col, convert to int
wdi_tidy.loc[:, 'year'].replace(regex=True,
                         inplace=True,
                         to_replace='\[YR....\]',
                         value='')

# change to correct col types
wdi_tidy = wdi_tidy.astype({'year':int,
                            'gdp_cap':numeric})


# write the file
wdi_tidy.to_csv('../data/gdp/WDI_gdp_cap_ppp2011_tidy.csv')


# TODO NOT DONE, REDOWNLOAD DATA WITHOUT CODES; MISSING AS ' '


#####################
### Maddison data ###
#####################

# Maddison data is from: https://www.rug.nl/ggdc/historicaldevelopment/maddison/
