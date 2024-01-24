
# baja-ranching

<!-- badges: start -->

<!-- badges: end -->

This repository contains the data and code for our paper:

> Kenneth B. Vernon
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0003-0098-5092),
> Simon Brewer
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-6810-1911),
> Brian F. Codding
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-7977-8568)
> and Shane Macfarlan
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-6332-9829)
> (2023). Market integration mediates human-environment interactions among traditional ranchers in Baja, Mexico.
> *Nature Sustainability*.

**Preprint**: [manuscript.pdf](/manuscript/manuscript.pdf)  
**Supplement**: [models.html](https://kbvernon.github.io/baja-ranching/R/models.html), [least-cost-paths.html](https://kbvernon.github.io/baja-ranching/R/least-cost-paths.html)  

## Contents  

📂 [_extensions](/_extensions) has Quarto extension for compiling manuscript  
📂 [data](/data) required for reproducing analysis and figures  
&emsp;&emsp;&RightTee; 🌎 choyero.gpkg is a GeoPackage database with all necessary data  
&emsp;&emsp;&RightTee; 📈 model-statistics.rdata has various evaluation tables for the models  
&emsp;&emsp;&RightTee; 💾 [ranches.csv](data/ranches.csv)  
&emsp;&emsp;&RightTee; 🌎 [roads.geojson](data/roads.geojson)  
&emsp;&emsp;&RightTee; 💾 [springs.csv](data/springs.csv)  
&emsp;&emsp;&RightTee; 🌎 [watersheds.geojson](data/watersheds.geojson)  
📂 [figures](/figures) contains all figures included in the paper  
📂 [manuscript](/manuscript) contains the pre-print  
&emsp;&emsp;&RightTee; 📄 [manuscript.qmd](/manuscript/manuscript.qmd)  
&emsp;&emsp;&RightTee; 📄 [manuscript.pdf](/manuscript/manuscript.pdf)  
📂 [R](/R) code for preparing data and conducting analysis, including  
&emsp;&emsp;&RightTee; 📄 [models.qmd](/R/models.qmd) is the primary analysis,  
&emsp;&emsp;&RightTee; 📄 [least-cost-paths.qmd](/R/least-cost-paths.qmd),  
&emsp;&emsp;&RightTee; 📄 [data-wrangling.R](/R/data-wrangling.R), and  
&emsp;&emsp;&RightTee; 📄 [overview-map.R](/R/overview-map.R)  

## 🌎 How to Rebuild GeoPackage Database  

All scripts for conducting analysis and generating figures assume that
the data can be found in a GeoPackage database called
`data/western-fremont.gpkg`. Unfortunately, a GeoPackage is not amenable
to git integration, so we note two ways to reconstruct it here. First, by running the necessary scripts. Assuming you're in the `baja-ranching` project folder, the following
is sufficient to build a local copy of the database:  

```
source("./R/data_wrangling.R")
quarto::quarto_render("./R/least-cost-paths.qmd")
```

Alternatively, if you are less interested in trying to replicate the steps required to generate the final data set used to train the models, you can simply download the database from Zenodo by running this: 

```
download.file(
  url = "https://zenodo.org/record/<record-id-here>/choyero.gpkg?download=1", 
  destfile = "./data/choyero.gpkg", 
  mode = "wb"
)
```

## 📈 Replicate analysis

To replicate the analysis, it's sufficient to compile the Quarto document `models.qmd`. 

```
quarto::quarto_render("./R/models.qmd")
```

## License  

**Text and figures:** [CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

**Code:** [MIT](LICENSE.md)

**Data:** [CC-0](http://creativecommons.org/publicdomain/zero/1.0/)
attribution requested in reuse.
