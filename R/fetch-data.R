#' @title Fetch Flow Data from USGS Stream Gage
#' @description Fetch flow data from USGS stream gage
#' @export
#' @param site_number USGS stream gage site number.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return A list of data frames. \code{site_data} is the time series flow data
#' in local date time and cubic feet per second. \code{site_metadata} is the metadata
#' associated with the requested gage station.
#'
fetch_gage_data <- function(site_number,
                            start_date,
                            end_date) {
  # Initiate data frames for appending
  site_data <- c()
  site_metadata <- c()
  for (i in site_number) {
    # Confirm that station provided is a stream gage and collects flow, stage data
  query <- dataRetrieval::whatNWISdata(siteNumber = i)
  sufficient_data <- ifelse(
    any(query$site_tp_cd == "ST") &&
      any(query$parm_cd == "00065") &&
      any(query$parm_cd == "00060"),
    TRUE,
    FALSE
  )
  
  if (isFALSE(sufficient_data)) stop(paste0("Site ", i, " does not have sufficient data."))
  
  # Fetch instantaneous flow data
  site_data_i <- dataRetrieval::readNWISuv(
    siteNumbers = i,
    parameterCd = c("00060", "00065"),
    startDate = start_date,
    endDate = end_date
  )
  
  # Define metadata
  site_metadata_i <- attributes(site_data_i)$siteInfo %>%
    dplyr::rename(site_number = site_no)
  
  # Define timezone
  timezone_i <- lutz::tz_lookup_coords(
    lat = site_metadata_i$dec_lat_va,
    lon = site_metadata_i$dec_lon_va) %>%
    suppressWarnings()
  
  # Format instantaneous data frame
  site_data_i <- site_data_i %>%
    dplyr::rename(flow_cfs = X_00060_00000,
                  gage_height_ft = X_00065_00000) %>%
    dplyr::mutate(datetime_local = lubridate::with_tz(time = dateTime,
                                                      tzone = timezone_i)) %>%
    dplyr::select(site_number = site_no, 
                  datetime_local, 
                  flow_cfs,
                  gage_height_ft) %>%
    tidyr::fill(flow_cfs, .direction = "down") %>%
    tidyr::fill(gage_height_ft, .direction = "down")
  
  # Append all results into single data frame
  site_data <- rbind(site_data_i, site_data)
  site_metadata <- rbind(site_metadata_i, site_metadata)
  }
  
  return(list(data = site_data,
              metadata = site_metadata))
}

#' @title Fetch Weather Data From Open Meteo
#' @description Fetch precipitation data from Open Meteo
#' \link{https://open-meteo.com/en/docs/historical-weather-api#api_form}
#' @export
#' @param site_metadata A data frame containing the columns \code{site_number,
#' lat, lon} where \code{site_number} corresponds to the USGS site number,
#' \code{lat} to the latitudinal coordinate of the given site and \code{lon} 
#' to the longitudinal coordinate of the given site.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return A data frame containing a time series of precipitation data
#' in local date time and inches.
#'
fetch_weather_data <- function(site_metadata,
                               start_date,
                               end_date) {
  # Initiate data frames for appending
  weather_data <- c()
  for (i in 1:nrow(site_metadata)) {
    timezone <- lutz::tz_lookup_coords(lat = site_metadata$dec_lat_va[i],
                                       lon = site_metadata$dec_lon_va[i]) %>%
      suppressWarnings()
    
    # GET request
    url <- paste0(
      "https://archive-api.open-meteo.com/v1/archive?latitude=",
      site_metadata$dec_lat_va[i],
      "&longitude=",
      site_metadata$dec_lon_va[i],
      "&start_date=",
      start_date,
      "&end_date=",
      end_date,
      "&timezone=",
      timezone,
      "&hourly=precipitation&hourly=temperature_2m&format=json"
    )
    
    # Fetch json
    weather_json <- jsonlite::fromJSON(url)
    
    # Convert json to data frame
    # Extract time series data and convert to local timezone
    # Convert mm to inches and C to F
    weather_data_i <- weather_json %>%
      purrr::pluck("hourly") %>%
      dplyr::bind_rows() %>%
      dplyr::mutate(
        site_number = site_metadata$site_number[i],
        datetime_local = as.POSIXct(time,
                                    format = "%Y-%m-%dT%H:%M",
                                    tz = timezone),
        precipitation = precipitation * 0.0394,
        temp_degF = 9 / 5 * temperature_2m + 32
      ) %>%
      dplyr::select(site_number,
                    datetime_local,
                    precipitation_in = precipitation,
                    temp_degF)
    weather_data <- rbind(weather_data_i, weather_data)
  }
  
  return(weather_data)
}
