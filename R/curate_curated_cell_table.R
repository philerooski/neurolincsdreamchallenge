library(synapser)
library(tidyverse)

fetch_syn_table <- function(syn_id, cols = "*") {
  if (is.vector(cols)) {
    cols <- paste(cols, collapse = ",")
  }
  table <- synapser::synTableQuery(paste("select", cols, "from", syn_id))
  table_df <- table$asDataFrame()
  return(as_tibble(table_df))
}

get_corrected_indices <- function() {
  corrected_abc <- fetch_syn_table("syn17087846")
  corrected_lincs <- fetch_syn_table("syn17096732")
  corrected_sod <- fetch_syn_table("syn17933845")
  corrected_indices <- bind_rows(corrected_abc, corrected_lincs, corrected_sod)
  return(corrected_indices)
}

main <- function() {
  synLogin()
  curated_cell_data <- fetch_syn_table(
    "syn11378063", c("Experiment", "ObjectTrackID",
                     "Well", "TimePoint", "Live_Cells", "Lost_Tracking")) %>% 
    select(-ROW_ID, -ROW_VERSION)
  censored_wells <- fetch_syn_table("syn11709601") %>%
    select(-ROW_ID, -ROW_VERSION)
  curated_cell_data <- anti_join(curated_cell_data, censored_wells)
  corrected_indices <- get_corrected_indices()
}