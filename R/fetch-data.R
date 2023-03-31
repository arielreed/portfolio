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
  
  # Confirm that station provided is a stream gage and collects flow, stage data
  query <- dataRetrieval::whatNWISdata(siteNumber = site_number)
  sufficient_data <- ifelse(
    any(query$site_tp_cd == "ST") &&
      any(query$parm_cd == "00065") &&
      any(query$parm_cd == "00060"),
    TRUE,
    FALSE
  )
  
  if (isFALSE(sufficient_data)) stop(paste0("Site ", site_number, " does not have sufficient data."))
  
  # Fetch instantaneous flow data
  site_data <- dataRetrieval::readNWISuv(
    siteNumbers = site_number,
    parameterCd = c("00060", "00065"),
    startDate = start_date,
    endDate = end_date
  )
  
  # Define metadata
  site_metadata <- attributes(site_data)$siteInfo
  
  # Define timezone
  timezone <- lutz::tz_lookup_coords(lat = site_metadata$dec_lat_va,
                                     lon = site_metadata$dec_lon_va) %>%
    suppressWarnings()
  
  # Format instantaneous data frame
  site_data <- site_data %>%
    dplyr::rename(flow_cfs = X_00060_00000,
                  gage_height_ft = X_00065_00000) %>%
    dplyr::mutate(datetime_local = lubridate::with_tz(time = dateTime,
                                                      tzone = timezone)) %>%
    dplyr::select(site_number = site_no, 
                  datetime_local, 
                  flow_cfs,
                  gage_height_ft) %>%
    tidyr::fill(flow_cfs, .direction = "down") %>%
    tidyr::fill(gage_height_ft, .direction = "down")
  
  return(list(data = site_data,
              metadata = site_metadata))
}

#' @title Fetch Weather Data From Open Meteo
#' @description Fetch precipitation data from Open Meteo
#' \link{https://open-meteo.com/en/docs/historical-weather-api#api_form}
#' @export
#' @param lat Latitude.
#' @param lon Longitude.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return A data frame containing a time series of precipitation data
#' in local date time and inches.
#'
fetch_weather_data <- function(lat,
                                     lon,
                                     start_date,
                                     end_date) {
  
  timezone <-
    lutz::tz_lookup_coords(lat = lat, lon = lon) %>% suppressWarnings()
  
  # GET request
  url <- paste0(
    "https://archive-api.open-meteo.com/v1/archive?latitude=",
    lat,
    "&longitude=",
    lon,
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
  weather_data <- weather_json %>%
    purrr::pluck("hourly") %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(datetime_local = as.POSIXct(time,
                                            format = "%Y-%m-%dT%H:%M",
                                            tz = timezone),
                  precipitation = precipitation * 0.0394,
                  temp_degF = 9 / 5 * temperature_2m + 32) %>%
    dplyr::select(datetime_local,
                  precipitation_in = precipitation,
                  temp_degF)
  
  return(weather_data)
}
