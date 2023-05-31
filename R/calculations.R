#' @title Calculate Linear Rating Curve
#' @description Calculate linear rating curve for USGS stream gage site between
#' a given start and end date
#' @export
#' @param site_number USGS stream gage site number.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return Data frame with slope and intercept for each site number provided.
#' Values are in imperial units.
#'
calculate_linear_rating_curve <- function(site_number,
                                          start_date,
                                          end_date) {
  linear_model <- c()
  # Get field measurements from NWIS
  for (i in site_number) {
    fieldMeas <-
      dataRetrieval::readNWISmeas(
        siteNumbers = i,
        startDate = as.Date(start_date) - lubridate::years(5),
        endDate = as.Date(start_date),
        tz = "UTC",
        expand = TRUE
      ) %>%
      # Select columns for rating curve calculation
      # Remove poor readings and negative values
      dplyr::select(
        site_no,
        measured_rating_diff,
        chan_discharge,
        chan_width,
        chan_velocity,
        gage_height_va
      ) %>%
      dplyr::filter(measured_rating_diff != "Poor",
                    dplyr::if_all(dplyr::where(is.numeric), ~ .x > 0)) %>%
      
      # Calculate channel depth from field measurements
      dplyr::mutate(chan_depth_ft = chan_discharge / (chan_width * chan_velocity))
    
    # Linear interpolation (y ~ x ::: depth ~ stage)
    depthRating <- as.data.frame(fieldMeas) %>%
      dplyr::group_by(site_no) %>%
      dplyr::do(depthRating = broom::tidy(lm(chan_depth_ft ~ gage_height_va, data = .))) %>%
      tidyr::unnest(depthRating) %>%
      dplyr::ungroup()
    
    slope <- depthRating %>%
      dplyr::filter(term == "gage_height_va") %>%
      dplyr::select(site_no, estimate) %>%
      dplyr::rename(slope = estimate) %>%
      dplyr::ungroup()
    
    intercept <- depthRating %>%
      dplyr::filter(term == "(Intercept)") %>%
      dplyr::select(site_no, estimate) %>%
      dplyr::rename(int = estimate)
    
    linear_model_i <- dplyr::full_join(slope,
                                       intercept,
                                       by = "site_no") %>%
      dplyr::rename(site_number = site_no)
    # Append all results into single data frame
    linear_model <- rbind(linear_model_i, linear_model)
  }
  
  return(linear_model)
} 
