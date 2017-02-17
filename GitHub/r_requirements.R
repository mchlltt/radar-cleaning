# A list of all the packages used in RADAR cleaning scripts.

# NOTES:
# 1. This does not include the 'radar' package, because that is a custom library that must be built separately.
# Running `install.packages('radar')` will install the wrong package.
# 2. If you are unable to install rJava, you may need to involve FSMIT or else use 32-bit R/RStudio.
# You cannot use the xlsx package without a functional installation of rJava.

package.list = c(
    'rJava',
    'xlsx',
    'rjson',
    'stringr',
    'jsonlite',
    'plyr',
    'RNeo4j',
    'RecordLinkage',
    'ggplot2',
    'data.table',
    'grid',
    'igraph',
    'devtools',
    'roxygen2'
)

# For each of these packages, try loading the package. If there's an error, install it.
for (i in 1:length(package.list)) {
    tryCatch(
      library(package.list[i], character.only = TRUE),
      error = function(e) {return(install.packages(package.list[i]))}
   )
}