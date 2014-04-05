###############################################################################
## Parse the WICHE Dataset and build Tableau Data Extract
## March 2014
## @brocktibert
## #emsci
## 
## Copyright (c) 2011, under the Simplified BSD License.  
## For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
## All rights reserved.
###############################################################################

## load the packages
library(RODBC) #works on windows
library(reshape2)
library(stringr)
library(plyr)
library(ggplot2)

## ensure that we have a directory to store the raw data
if (!file.exists("raw")) dir.create("raw")
if (!file.exists("figs")) dir.create("figs")

## download the dataset into your working directory
## use mode option below so the file can open in R, error w/o it
WICHE_DATA = "http://wiche.edu/info/knocking-8th/tables/allProjections.xlsx"
download.file(url=WICHE_DATA, destfile="raw/wiche.xlsx", mode="wb")


## use the RODBC library (Windows) to query and get the data
xl = odbcConnectExcel2007("raw/wiche.xlsx")


## now we can think of our XL workbook as a database. Tabs = Database Tables
sqlTables(xl)


## store the metadata as a dataframe
meta = as.data.frame(sqlTables(xl))


## how cool is it that R has the State names and Abbreviations preloaded?
?state.name
(states = state.name)
length(states)
states = c(states, "District of Columbia")



## use a for loop -- not ideal but easy to read and debug
wiche = data.frame(stringsAsFactors=FALSE)
for (state in states) {
 raw = sqlFetch(xl, state, stringsAsFactors=FALSE)
 ## bc there is a structure to each sheet, we can reference each column by index
 ## no way is this ideal, but quick when data doesnt change
 ROWS = 9:40
 COLS = c(1, 3:10)
 ## create a flag for actual/projected -- hard coded from looking at Excel file
 status = c(rep("actual", 13), rep("projected", 19))
 ## keep the data
 df = raw[ROWS, COLS]
 colnames(df) = c('year',
                  'pub_amind',
                  'pub_asian',
                  'pub_black',
                  'pub_hisp',
                  'pub_white',
                  'pub_total',
                  'np_total',
                  'total')
 ## remove the commas -- using a for loop not ideal, but intuitive
 for (i in 2:ncol(df)) {
  df[,i] = as.numeric(gsub(",","", df[,i]))
 }
 df$state = state
 df$status = status
 ## bind onto the master data frame
 wiche = rbind.fill(wiche, df)
 ## status
 cat("finished ", state, "\n")
}


## lets look at the total over time
grad_tot = ddply(wiche, .(year), summarise, 
                 total = sum(total, na.rm=TRUE))
g = ggplot(grad_tot, aes(x=year, y=total, group=1))
g = g + geom_line(aes(colour=status)) + scale_colour_manual(values=c("#F8A31B", "#556670"))
g = g + xlab("Academic Year") + ylab("# Grads")
g = g + theme_bw() 
g = g + theme(axis.text.x = element_text(angle = 90, hjust = 1),
              panel.grid.major.x = element_blank(),
              panel.border = element_blank())
g + ggtitle("Wiche Actual/Projected High School Graduates")
ggsave(file = "figs/Total-HS-Grads.jpg")


## save the data for tableau
write.table(wiche, file="wiche-dataset.csv", sep=",", row.names=F)
