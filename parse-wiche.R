###############################################################################
## Parse the WICHE Dataset and build Tableau Data Extract
## April 2019
## @brocktibert
## #emsci
## 
## Copyright (c) 2011, under the Simplified BSD License.  
## For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
## All rights reserved.
###############################################################################

## load the packages
library(tidyverse)
library(readxl)

## ensure that we have a directory to store the raw data
if (!file.exists("raw")) dir.create("raw")
if (!file.exists("figs")) dir.create("figs")

## download the dataset into your working directory
## use mode option below so the file can open in R, error w/o it
WICHE_DATA = "https://knocking.squarespace.com/s/All-Projections-Published-Table-Format-j2f9.xlsx"
download.file(url=WICHE_DATA, destfile="raw/wiche.xlsx", mode="wb")


## define the states
states = c(state.name, "District of Columbia")

## use a for loop -- not ideal but easy to read and debug
wiche = data.frame(stringsAsFactors=FALSE)

## the columns
CNAMES = c("grand_total", 
           "private_total",
           "public_total",
           "hispanic",
           "white",
           "black",
           "amerindian_alaskanative",
           "asian")

## the years and data values
data_years = 2000:2031
report_values = c(rep("actual", 11), rep("projected", 21))

for (state in states) {
 raw_w = read_excel("raw/wiche.xlsx", sheet=state, range="C7:J38", col_names = CNAMES)
 raw_w = transform(raw_w, 
                   year = data_years,
                   status = report_values,
                   state = state)
 raw_long = raw_w %>% gather("demo", "grads", -year, -status, -state)
 wiche = bind_rows(wiche, raw_long)
 cat("finished ", state, "\n")
}

## save the data
write_csv(wiche, "~/Downloads/wiche-hs-grads.csv", na="")


## lets look at the total over time
# grad_tot = ddply(wiche, .(year), summarise, 
#                  total = sum(total, na.rm=TRUE))
# g = ggplot(grad_tot, aes(x=year, y=total, group=1))
# g = g + geom_line(aes(colour=status)) + scale_colour_manual(values=c("#F8A31B", "#556670"))
# g = g + xlab("Academic Year") + ylab("# Grads")
# g = g + theme_bw() 
# g = g + theme(axis.text.x = element_text(angle = 90, hjust = 1),
#               panel.grid.major.x = element_blank(),
#               panel.border = element_blank())
# g + ggtitle("Wiche Actual/Projected High School Graduates")
# ggsave(file = "figs/Total-HS-Grads.jpg")
# 
# 
# ## save the data for tableau
# write.table(wiche, file="wiche-dataset.csv", sep=",", row.names=F)
