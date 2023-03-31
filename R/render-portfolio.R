#' @title Render Portfolio
#' @description Render portfolio.
#' @export
#' @param  site_number Optional. A USGS stream gage number. Explore stream gages on NWIS
#' \link{https://maps.waterdata.usgs.gov/mapper/index.html}. If \code{NULL}, a random
#' eligible site is selected. Do not provide if state is specified.
#' @param state Optional. A two letter abbreviation for a US state, e.g. \code{"CO"}.
#' Only provide if \code{site_number} is not given.
#' @param start_date Optional. Provide as \code{"YYYY-mm_dd"}, otherwise 1 month
#' prior to today will be used.
#' @param end_date Optional. Provide as \code{"YYYY-mm-dd"}, otherwise today will be used.
#' @returns HTML report in the \code{/inst/outputs/} directory of this repository.
#' 
render_portfolio <- function(site_number = NULL,
                             state = NULL,
                             start_date = NULL,
                             end_date = NULL) {

  # If start and end dates are not provided, default to the past month of data
  if (is.null(start_date)) start_date <- Sys.Date() - 30
  if (is.null(end_date)) end_date <- Sys.Date()
  
  # Stop if site number and state are provided
  if (!is.null(state) && !is.null(site_number)) stop("Provide state OR site number, not both.")
  
  # If site number is not provided, get random eligible site
  if (is.null(site_number)) {
    state <- ifelse(is.null(state),
                    sample(state.abb, 1),
                    state)
    
    # Query sites with flow data
    flow_sites <-
      dataRetrieval::whatNWISsites(
        stateCd = state,
        parameterCd = "00060",
        startDt = start_date,
        endDt = end_date,
        hasDataTypeCd = "uv"
      ) 
    
    # Query sites with stage data
    stage_sites <-
      dataRetrieval::whatNWISsites(
        stateCd = state,
        parameterCd = "00065",
        startDt = start_date,
        endDt = end_date,
        hasDataTypeCd = "uv"
      ) 
    
    # Select random site
    site <- sample(intersect(flow_sites$site_no, stage_sites$site_no), 1)
  } else {
    site <- site_number
  }
  
  message(paste0("Rendering portfolio for stream gage ", site))
  
  # Render portfolio
  rmarkdown::render(
    input = here::here("inst", "rmd", "portfolio.Rmd"),
    output_dir = here::here("inst", "output"),
    output_file = paste0("portfolio-",
                         site,
                         ".html"),
    params = list(
      site_number = site,
      start_date = start_date,
      end_date = end_date
    ),
    envir = parent.frame()
  )
}
