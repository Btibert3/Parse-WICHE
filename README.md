# Forecast College Enrollment

As of late, there has been a surge in conversation around the topic of the `college-going population` here in the United States.   

One one hand, we have long talked about the "The Perfect Storm" of demographics.  For example, here is a simple [Google Search](http://goo.gl/T3OyCF).  On the other, the decline in college enrollment, has been connected to changes in the [labor market](http://fivethirtyeight.com/features/more-high-school-grads-decide-college-isnt-worth-it/). 

In the end, it might be nice to review what data exist and highlight how these flashy headlines could have been predictable well in advance of 2014.


## About this post

For this post, I will be using using the `R` language to download the data from [WICHE](http://www.wiche.edu/knocking-8th), an amazing resource for projections of High School graduates by state.  Using these data, we can do all sorts of fun analyses. 

In a future post, I will show you how to link WICHE to [IPEDS](http://nces.ed.gov/ipeds) data in order to forecast college participation rates by state.

While I will provide a few code snippets below, you should feel free to clone my [Github Repo](https://github.com/Btibert3/Parse-WICHE) which everything you need to replicate this post.  

Also included is a Tableau Workbook.  If you have Tableau Desktop, this super basic workbook highlights how you can leverage parameters to create your own forecasts.

Below is a screenshot of the workbook, which is a basic "Create-Your-Own College Enrollment Forecast" of sorts.

![Tableau-ss]("figs/tableau.png")



## Why this post

The changing demographics and volume of students that would be considering a college education should not be news to anyone in Enrollment Management.  I hope to highlight how with just a few lines of code, we can:

1.  Grab data that forecasts the volume of high school graduates    
2.  Use `R` to parse, clean, and reshape the data (originally stored in Excel)
3.  Save out the data and leverage Tableau to do some basic forecasting

For those of you that might be new to `R`, reading code can be extremely helpful when attempting to learn a new language.  When possible, I always try to comment the heck of out my code.  Hopefully these comments can help you in your journey.


## Get the data

With `R`, it's super simple to grab data from the web.  The command below will download the WICHE Excel Workbook.

	## download the dataset into your working directory
	## use mode option below so the file can open in R, error w/o it
	WICHE_DATA = "http://wiche.edu/info/knocking-8th/tables/allProjections.xlsx"
	download.file(url=WICHE_DATA, destfile="raw/wiche.xlsx", mode="wb")

It should be noted that the code above assumes that your current directory (where you are running the code) has a folder called `raw`.  To assure that this is the case, just do this:

	## ensure that we have a directory to store the raw data
	if (!file.exists("raw")) dir.create("raw")
	if (!file.exists("figs")) dir.create("figs")

Now we can use the `RODBC` package (on Windows) to connect to the workbook and query it as if the sheets were database tables.

	xl = odbcConnectExcel2007("raw/wiche.xlsx")

Because each state is a tab in the workbook, let's use `R` to define an object that holds the state abbreivations, which we will use while looping through the workbook.

	## how cool is it that R has the State names and Abbreviations preloaded?
	?state.name
	(states = state.name)
	length(states)
	states = c(states, "District of Columbia")

Finally, let's loop and build a dataset in the format we want:

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

## A quick plot

When playing around with data, it's usually a good practice to visualize what you have.  Below is a quick plot which represents both the actual and forecasted volume of high school graduates going until the 2027/28 Academic year.

![plot]("figs/Total-HS-Grads.jpg")


## Summary

I would encourage the reader to browse the code, and if possible, fire up the Tableau workbook.  As an Enrollment Scientist, `R` and `Tableau` are my two tools that I use on a daily basis.