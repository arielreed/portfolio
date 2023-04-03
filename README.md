# :chart_with_upwards_trend: Portfolio
A flashy display of my data science prowess
## System Requirements
   - [R 4.2.2](https://cran.r-project.org/bin/windows/base/old/)
   - [Rtools 4.2](https://cran.r-project.org/bin/windows/Rtools/)
   - [RStudio](https://posit.co/download/rstudio-desktop/)
   
## R Environment
1. Clone this repository `https://github.com/arielreed/portfolio.git`
2. Open the R Studio project `portfolio.RProj`
3. First time users need to acivate the project by running `renv::activate()`
4. Run `renv::restore()` to download all dependencies
5. Load the portfolio package by running `devtools::load_all()`

## Generate My Portfolio

1. Run `render_portfolio()`.
2. The output is rendered in `/inst/output/`.

**Choose your own adventure when rendering my portfolio:**
  | Parameter | Description |
|---|---|
| `site_number` | &#8226; A USGS stream gage number.<br>&#8226; Explore stream gages on the [National Water Information System](https://maps.waterdata.usgs.gov/mapper/index.html) web interface.<br>&#8226; A random, eligible site is selected when not specified by user. |
| `state` | &#8226; A two letter abbreviation for a US state, e.g. `"CO"`<br>&#8226; Provide when you want a random stream gage selected within the given state. |
| `start_date` | &#8226; First day of data to be displayed in portfolio.<br>&#8226; Provide as `"YYYY-mm_dd"`, otherwise 1 month prior to today will be used. |
| `end_date` | &#8226; Last day of data to be displayed in portfolio.<br>&#8226; Provide as `"YYYY-mm_dd"`, otherwise today will be used. |

#### Examples:
```r
# Renders a portfolio using a random stream gage anywhere in the USA and displays the past 1 month of data.
render_portfolio()

# Renders a portfolio using a random USGS stream gage located in Colorado, USA and displays the past 1 month of data.
render_portfolio(state = "CO")

# Renders a portfolio for stream gage 04213000 and displays all data from 2022.
render_portfolio(site_number = "04213000", start_date = "2022-01-01", end_date = "2022-12-31")
```

#### The Final Product:
![image](https://user-images.githubusercontent.com/52611343/229561793-9f24d49b-8e0b-4b59-9438-3a2036a4139f.png)

