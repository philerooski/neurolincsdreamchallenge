# Fill in missing Timepoint values in syn11378063 and correct Lost_Tracking column.
#
# To use: Rscript fix_lost_tracking.R --outputPath corrected_lost_tracking.csv --outputSynapse syn7837269
# Omit either flag to omit its respective action.
# See Rscript fix_lost_tracking.R --help

library(tidyverse)
library(synapser)
library(optparse)


read_args <- function() {
  parser <- OptionParser()
  parser <- add_option(parser, "--outputPath",
                       type = "character",
                       help = "Where to write output to. By default,
                               no data will be written")
  parser <- add_option(parser, "--outputSynapse",
                       type = "character",
                       help = "Parent Synapse ID to output to. By default,
                               no output will be stored to Synapse.")
  parse_args(parser)
}

fetch_syn_table <- function(syn_id, cols = "*") {
  if (is.vector(cols)) {
    cols <- paste(cols, collapse = ",")
  }
  table <- synapser::synTableQuery(paste("select", cols, "from", syn_id))
  table_df <- table$asDataFrame()
  return(as_tibble(table_df))
}

fill_out_missing_timepoints <- function(curated_cell_data, timepoint_reference) {
  tidy_timepoint_reference <- timepoint_reference %>% 
    purrr::pmap_dfr(function(Experiment, TimePointBegin, TimePointEnd) {
      tibble(
        Experiment = Experiment,
        TimePoint = TimePointBegin:TimePointEnd
      )
    })
  object_well_reference <- curated_cell_data %>%
    distinct(Experiment, Well, ObjectTrackID)
  complete_reference <- tidy_timepoint_reference %>% 
    left_join(object_well_reference, by = "Experiment")
  curated_cell_data_full <- complete_reference %>% 
    left_join(curated_cell_data) %>% 
    filter(!is.na(ObjectTrackID)) %>% 
    arrange(Experiment, Well, ObjectTrackID, TimePoint) %>% 
    mutate(Live_Cells = as.logical(Live_Cells),
           Lost_Tracking = as.logical(Lost_Tracking)) %>% 
    group_by(Experiment, Well, ObjectTrackID)
  last_seen_alive <- curated_cell_data_full %>% 
    summarise(last_seen_alive = max(which(Live_Cells)) - 1)
  curated_cell_data_full <- curated_cell_data_full %>% 
    left_join(last_seen_alive) %>% 
    mutate(previous_live_cells = lag(Live_Cells),
           previous_lost_tracking = lag(Lost_Tracking),
           Correct_Lost_Tracking = ifelse(Lost_Tracking, F, Lost_Tracking),
           Correct_Lost_Tracking = ifelse(is.na(previous_lost_tracking), Correct_Lost_Tracking,
                                  ifelse(previous_lost_tracking, T, Correct_Lost_Tracking)),
           Correct_Lost_Tracking = ifelse(is.na(Lost_Tracking),
                                          ifelse(TimePoint < last_seen_alive, T, Correct_Lost_Tracking),
                                          Correct_Lost_Tracking),
           Correct_Live_Cells = ifelse(is.na(Live_Cells),
                                       ifelse(is.na(Lost_Tracking),
                                              ifelse(!previous_lost_tracking, 
                                                     ifelse(TimePoint > last_seen_alive, F, Live_Cells),
                                                     Live_Cells),
                                              Live_Cells),
                                       Live_Cells),
           Correct_Live_Cells = ifelse(TimePoint < last_seen_alive, T, Correct_Live_Cells))
  # after fill, if Lost_Tracking is T, Live_Cells is NA (Unless seen alive later)
  return(curated_cell_data_full)
}

main <- function() {
  args <- read_args()
  if(all(is.null(args$outputPath), is.null(args$outputSynapse))) {
    print("No --outputPath or --outputSynapse specified. Doing nothing.")
    return()
  }
  synLogin()
  curated_cell_data <- fetch_syn_table(
    "syn11378063", c("Experiment", "ObjectTrackID",
                     "Well", "TimePoint", "Live_Cells", "Lost_Tracking")) %>% 
    select(-ROW_ID, -ROW_VERSION)
  timepoint_reference <- fetch_syn_table(
    "syn11817859", c("Experiment", "TimePointBegin", "TimePointEnd")) %>% 
    select(-ROW_ID, -ROW_VERSION)
  curated_cell_data_full <- fill_out_missing_timepoints(
    curated_cell_data, timepoint_reference)
}

#main()