#Cortisol - data cleaning/preprocessing for analysis - CC

# Setting up R ------------------

# Clear the workplace (remove all data objects and variables)
rm(list = ls())


#Load packages: 

library(lmerTest) #for Mixed Effect Models
library(MuMIn) #for Mixed Effect Models (R-squared)
library(tidyverse) #for tidying dataframes
library(dplyr) #for proportions tables
library(readxl) #for reading exel-files
library(ggplot2) #building plots
library(RColorBrewer) #colors for ggplot
library(wesanderson) #colors for ggplot
library(ggpubr) #for histogram
library(gg.gap) #for a break in the y-axis
library(forcats) #for rearanging in ggplot
library(gridGraphics) #for saving gghistogram
library(cowplot) #for adding several plots into one plot
library(plyr) #for descriptive data
library(plotly) #for interactive web graphics
library(xlsx) #to read, write and format excel-files
library(rstatix) #provides pipe-friendly R functions for easy statistical analyses
library(reshape2) #for transforming a dataset from long to wide
library(maditr) #for dcast function
library(writexl)# To write dataframe as excel file
library(car) # Levene's test with one independent variable
library(lawstat)
library(lme4)
library(multcomp)
library(tidyr) # to reshape dataframe
library(gridExtra)
library(Gmisc)
library(purrr)
#library(openxlsx) #this interferes with readxlsx

## Output and input folders --------------------

#Set output path and create folder if it doesn't exist
OutputPath = "F:/Amylase and Cortisol/Cortisol_data"
if (!dir.exists(file.path(OutputPath, "R_output"))) {
  dir.create(file.path(OutputPath, "R_output"))
}

#Set input folders and load data
CortisolDataPath = "F:/Amylase and Cortisol/Cortisol_data/Original data"
setwd(CortisolDataPath)
CortisolRawData_1 <- read.xlsx("Original_Saliva_Results_P060-P104.xlsx", sheetIndex = 1)
CortisolRawData_2 <- read.xlsx("Original_Saliva_Results_P105-P150.xlsx", sheetIndex = 1)
CortisolRawData_3 <- read.xlsx("Original_Saliva_Results_P151-P174.xlsx", sheetIndex = 1)

WakeUpData_HC <- read.csv("Wakeup_HC_DATA_2025-05-23_1318.csv", sep = ";")
WakeUpData_PPPD <- read.csv("WakeupPPPD_DATA_2025-05-23_1354.csv", sep = ";")

CRFDataPath = "E:/ConcettiC/PPPD_for_Caps/OriginalResults_04_CRF_all_Subjects/02_Analysed data/R_output"
setwd(CRFDataPath)
CRF <- read.xlsx("CRF_clean.xlsx", sheetIndex = 1)

## Clean and concatenate cortisol data -------------------

# Reassign some values of timepoint which are not read correctly
df_list <- list(CortisolRawData_1, CortisolRawData_2, CortisolRawData_3)

df_list <- lapply(df_list, function(df) {
  df %>%
    mutate(
      timepoint = as.character(timepoint),
      timepoint = case_when(
        timepoint == "0.583333333333333" ~ "14:00",
        timepoint == "0.625" ~ "15:00",
        timepoint == "0.666666666666667" ~ "16:00",
        timepoint == "0.708333333333333" ~ "17:00",
        TRUE ~ timepoint
      )
    )
})

# Then extract back to original variables
CortisolRawData_1 <- df_list[[1]]
CortisolRawData_2 <- df_list[[2]]
CortisolRawData_3 <- df_list[[3]]

#Rename cortisol data columns to make them consistent
CortisolRawData_1 <- rename(CortisolRawData_1, Cortisol = Cortisol.en.ng.ml )
CortisolRawData_3 <- rename(CortisolRawData_3, Cortisol = Cortisol.ng.ml )

#remove the first row of data2 as it is a header
CortisolRawData_2 <- CortisolRawData_2 %>% slice(-1)

#keep only columns ID, Date, timepoint, Cortisol
CortisolRawData_1 <- CortisolRawData_1 %>%
  dplyr::select(ID, Date, timepoint, Cortisol)
CortisolRawData_2 <- CortisolRawData_2 %>%
  dplyr::select(ID, Date, timepoint, Cortisol)
CortisolRawData_3 <- CortisolRawData_3 %>%
  dplyr::select(ID, Date, timepoint, Cortisol)

#remove suffix after ID of data 1
CortisolRawData_1$ID <- str_remove(CortisolRawData_1$ID, "_.*$") 

#remove last few rows which are just NAs
CortisolRawData_1 <- CortisolRawData_1 %>%
  filter(!is.na(ID))
CortisolRawData_2 <- CortisolRawData_2 %>%
  filter(!is.na(ID))
CortisolRawData_3 <- CortisolRawData_3 %>%
  filter(!is.na(ID))

#Cortisol is a character for data1 and 2, convert to numeric
CortisolRawData_1 <- CortisolRawData_1 %>%
  mutate(Cortisol = as.numeric(Cortisol))
CortisolRawData_2 <- CortisolRawData_2 %>%
  mutate(Cortisol = as.numeric(Cortisol))

#Concatenate cortisol data
CortisolRaw <- bind_rows(CortisolRawData_1, CortisolRawData_2, CortisolRawData_3)

#Change ID into p_code with just the number
CortisolRaw <- CortisolRaw %>%
  rename(p_code = ID) %>%
  mutate(p_code = as.numeric(gsub("P", "", p_code)))

#Reshape into wide format
CortisolRaw_wide <- CortisolRaw %>%
  pivot_wider(
    names_from = timepoint,      # Column that provides new column names
    values_from = Cortisol,      # Column that provides the values
    names_prefix = "cortisol_"   # Optional: prefix for new column names
  )

#Keep only age-gender-matched subjects (from CRF)
filtered_CortisolData <- CortisolRaw_wide %>%
  filter(p_code %in% CRF$p_code)

#Include record_id 
filtered_CortisolData <- inner_join(filtered_CortisolData, 
                                CRF %>% dplyr::select(p_code, record_id), 
                                by = "p_code")

#Save "clean" file
file_path <- file.path(OutputPath, "R_output", "Cortisol_Data_Clean.xlsx")
write.xlsx(filtered_CortisolData, file_path)

## Clean and concatenate wakeup data --------------------

#Add group column to wakeup data
WakeUpData_HC <- WakeUpData_HC %>%
  mutate(group = "HC")
WakeUpData_PPPD <- WakeUpData_PPPD %>%
  mutate(group = "PPPD")

#Check in the console if the column names are consistent for wakeup data
# print(colnames(WakeUpData_HC))
# print(colnames(WakeUpData_PPPD))
setdiff(colnames(WakeUpData_HC), colnames(WakeUpData_PPPD))

#Concatenate wakeup data
WakeUpData <- bind_rows(WakeUpData_HC, WakeUpData_PPPD)

#Remove date from wakeup time
WakeUpData$wakeuptime <- format(as.POSIXct(WakeUpData$wakeuptime, format = "%Y-%m-%d %H:%M"), "%H:%M")

#Keep only useful columns
WakeUpData <- WakeUpData %>%
  dplyr::select(-redcap_event_name, -saliva_location, -cortisol_complete)

# Replace NAs with 0
columns_to_change <- 4:12
WakeUpData[, columns_to_change][is.na(WakeUpData[, columns_to_change])] <- 0

# Keep only age-gender-matched subjects (the ones that appear in the CRF, because that it already clean and has the final sample)
# In other words, filter Wakeupdata to only include IDs that exist in CRF
filtered_WakeupData <- WakeUpData %>%
  filter(record_id %in% CRF$record_id)
#Include record_id 
filtered_WakeupData <- inner_join(filtered_WakeupData, 
                                    CRF %>% dplyr::select(p_code, record_id), 
                                    by = "record_id")
#I have to manually introduce a delay that was only present in the comments
filtered_WakeupData[8, 8] <- 60

#Save "clean" file
file_path <- file.path(OutputPath, "R_output", "Wakeup_Data_Clean.xlsx")
write.xlsx(filtered_WakeupData, file_path)


## Merge all data for analysis and further cleaning ----------------------

  #NOTE: Corticosteroid medication influences cortisol levels, but in my sample nobody took it
  #Hormonal contraception also influences cortisol levels
  #Also menopause influences cortisol levels
  #Also smoke influences cortisol levels
  #The effect of gender can be complex, needs to be used as a covariate
  #Menstrual cycle phase can also influence it
  #Also psychMed influences cortisol levels

#Merge with original CRF and save for correlations
AllDataMerged_bigCRF <- inner_join(CRF, filtered_CortisolData, by = "p_code")
AllDataMerged_bigCRF <- inner_join(AllDataMerged_bigCRF, filtered_WakeupData,by = "p_code")
file_path <- file.path(OutputPath, "R_output", "AllDataCortisolCRF_forCorr.xlsx")
write.xlsx(AllDataMerged_bigCRF, file_path)

#####
#Select only relevant columns of CRF, then merge and save this file that will be used for cortisol analysis
reduced_CRF <- CRF %>% 
  dplyr::select(p_code, record_id, gender, age, handedness, menopause, 
                crf_contraception, acutestress, group, psychMed, smoke, 
                menstrualcycle, Mood_score)
AllDataMerged <- inner_join(reduced_CRF, filtered_CortisolData, by = "p_code")
AllDataMerged <- inner_join(AllDataMerged, filtered_WakeupData, by = "p_code")

#Check that group and record id are the same
if (!identical(AllDataMerged$group.x, AllDataMerged$group.y)) {
  stop("group.x and group.y are not identical.")
}
if (!identical(AllDataMerged$record_id.x, AllDataMerged$record_id.y, AllDataMerged$record_id)) {
  stop("record_id.x and record_id.y are not identical.")
}

# 2) Keep one and rename it to group
AllDataMerged <-
  AllDataMerged |>
  dplyr::select(-group.y, -record_id.y, -record_id.x) |>
  dplyr::rename(group = group.x)


#Exclude datapoints with too much delay
# For delays up to delay_5 included, I exclude if delay was over 5 minutes
target_columns1 <- c("delay_1", "delay_2", "delay_3", "delay_4", "delay_5")
positions1 <- which(abs(AllDataMerged[target_columns1]) > 5, arr.ind = TRUE)# Find all positions where |value| > 5
# Convert to dataframe for readability
positions1_df <- data.frame(
  row = positions1[, "row"],
  DelayNames = colnames(AllDataMerged[target_columns1])[positions1[, "col"]],
  value = AllDataMerged[target_columns1][positions1]
)
print(positions1_df)

# For delays starting from delay_6 onwards, I exclude if delay was over 15 minutes
target_columns2 <- c("delay_6", "delay_7", "delay_8", "delay_9")
positions2 <- which(abs(AllDataMerged[target_columns2]) > 15, arr.ind = TRUE)# Find all positions where |value| > 15
# Convert to dataframe for readability
positions2_df <- data.frame(
  row = positions2[, "row"],
  DelayNames = colnames(AllDataMerged[target_columns2])[positions2[, "col"]],
  value = AllDataMerged[target_columns2][positions2]
)
print(positions2_df)

#Merge all found positions of data points to exclude
NApositions <- full_join(positions1_df, positions2_df)

#Now I have to find the corresponding cortisol value columns, and change them to NA (then remember to explicitly ignore NAs in statistical analyses)
CortisolDelayLookup <- data.frame(CortisolNames = c("cortisol_wake-up" , "cortisol_15'", 
                                                    "cortisol_30'", "cortisol_45'" , "cortisol_60'", 
                                                    "cortisol_14:00", "cortisol_15:00", "cortisol_16:00", 
                                                    "cortisol_17:00" ) , 
                                  DelayNames = c("delay_1", "delay_2", "delay_3",           
                                                 "delay_4", "delay_5", "delay_6", 
                                                 "delay_7", "delay_8", "delay_9") )

NApositions <- left_join(NApositions, CortisolDelayLookup, by = "DelayNames")

#Change them to NA
for (i in 1:nrow(NApositions)) {
  AllDataMerged[[NApositions$CortisolNames[i]]][NApositions$row[i]] <- NA
}

#Save merged "clean" file
file_path <- file.path(OutputPath, "R_output", "AllDataCortisolCRF_reduced.xlsx")
write.xlsx(AllDataMerged, file_path)

## Assessing covariates -------------------

# #Covariates: contraception, menopause, smoke , gender , menstrual cycle phase, psychMed 
# 
# ## Assess in they differ in the two groups - some of them are numerical, some are categorical
# 
# #Summarize numerical covariates using mean and SD
# summary_Covariates <-
#   AllDataMerged %>%
#   group_by(group) %>%
#   summarise(
#     across(
#       c(age, Mood_score),  
#       list(mean = ~mean(.x, na.rm = TRUE),
#            sd   = ~sd(.x,   na.rm = TRUE)),
#       .names = "{.col}_{.fn}"
#     )
#   )
# 
# #Summarize categorical covariates using percentages
# 
# #Function to run Fisher's test and store results in a table
# FisherTest_for_var <- function(data, group_var, cat_var) {
#   # build table
#   tab <- table(data[[group_var]], data[[cat_var]])
#   
#   # Fisher test
#   chi  <- fisher.test(tab)
#   pval <- chi$p.value
#   
#   # group-wise percentages per category
#   prop_tab <- prop.table(tab, margin = 1)  # proportions within each group
#   
#   # which group & category show the largest difference (as before)
#   diff_mat <- apply(prop_tab, 2, function(col) col - mean(col))
#   max_pos  <- which(abs(diff_mat) == max(abs(diff_mat)), arr.ind = TRUE)[1, ]
#   
#   higher_group  <- rownames(prop_tab)[max_pos[1]]
#   higher_level  <- colnames(prop_tab)[max_pos[2]]
#   
#   # turn proportions into a long data frame with percentages
#   perc_df <-
#     as.data.frame(prop_tab) |>
#     dplyr::rename(
#       group   = 1,
#       level   = 2,
#       prop    = Freq
#     ) |>
#     dplyr::mutate(perc = 100 * prop)
#   
#   # spread to one row per category, one column per group’s percentage
#   perc_wide <-
#     perc_df |>
#     dplyr::select(group, level, perc) |>
#     tidyr::pivot_wider(
#       names_from  = group,
#       values_from = perc,
#       names_prefix = "perc_"
#     )
#   
#   # summary row (p-value, higher group/level) + category percentages
#   tibble(
#     variable     = cat_var,
#     p_value      = pval,
#     higher_group = higher_group,
#     higher_level = higher_level
#   ) |>
#     dplyr::bind_cols(
#       list(
#         categories = list(perc_wide)
#       )
#     )
# }
# 
# #Define categorical covariates and create the table
# cat_vars <- c("gender", "menopause", "crf_contraception", "psychMed", "smoke", "menstrualcycle")  # categorical covariates
# 
# results_tbl <-
#   purrr::map_dfr(cat_vars, ~ FisherTest_for_var(AllDataMerged, group_var = "group", cat_var = .x))
# 
# ## Only psychMed is statistically different between the two groups, but this still 
# ## doesn't guarantee that the other covariates don't have any influence on the cortisol values
# ## Will have to try different covariate sets and see if they explain more or less of the variability


## Plotting: whole day cortisol timecourse ----------------------
 
#Reshape to long format for plotting
CortisolData_long <-
  AllDataMerged %>%
  dplyr::select(
    p_code, group,
    "cortisol_wake-up", "cortisol_15'", "cortisol_30'", "cortisol_45'",
    "cortisol_60'", "cortisol_14:00", "cortisol_15:00", "cortisol_16:00",
    "cortisol_17:00"
  ) %>%
  tidyr::pivot_longer(
    cols = dplyr::starts_with("cortisol"),
    names_to   = "timepoint",
    names_prefix = "cortisol_",
    values_to  = "Cortisol",
    values_drop_na = FALSE
  )

# plot whole day

plotday<-ggline(CortisolData_long, x = "timepoint", y = "Cortisol",linetype = "group", shape = 19, point.size = 3,
                add = c("jitter", "mean_se"), #add jitter if you want to see all the dots
                color = "group", palette = c("#96989c", "#ec9006"), size = 1)

plotday<-ggpar(plotday, font.legend = 10, font.tickslab = 10, font.subtitle = 10, font.x = 10, font.y = 10, 
               legend.title = 'Groups', subtitle = "") + theme(legend.position = c(0.9, 0.8),legend.background = element_rect(linetype = 1, size = 0.5, colour = 1))+
  labs(y = "Cortisol [ng/ml]")

#Alternative way to plot 

CortisolData_long$timepoint <- factor(
  CortisolData_long$timepoint,
  levels = c("wake-up", "15'", "30'", "45'", "60'", "14:00", "15:00", "16:00", "17:00")  
)

palette <- c(
  "HC" = "#96989c",   # grey
  "PPPD" = "#ec9006"  # orange
)
x_label_angle = 0

plotday <- ggplot(
  CortisolData_long,
  aes(x = timepoint,
      y = Cortisol,
      fill = group
      )
) +
  
  # individual data points
  geom_jitter(
    aes(fill = group),
    shape = 21,
    color = "black",
    stroke = 0.3,
    alpha = 0.5,
    size = 2.5,
    position = position_jitterdodge(
      jitter.width = 0.12,
      dodge.width = 0.4
    )
  )+
  
  # connecting lines between group means
  stat_summary(
    aes(group = group),
    fun = mean,
    geom = "line",
    linewidth = 0.8,
    alpha = 0.7,
    color = "black",
    position = position_dodge(width = 0.4)
  ) +
  
  
  # mean
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 16,
    size = 4,
    color = "black", 
    position = position_dodge(width = 0.4)
  ) +
  
  # SD
  stat_summary(
    fun.data = mean_sdl,
    fun.args = list(mult = 1),
    geom = "errorbar",
    width = 0.15,
    color = "black",
    linewidth = 0.8, 
    position = position_dodge(width = 0.4)
  ) +
  
  ########################################################
# AXES
########################################################

# coord_cartesian(
#   ylim = c(current_ymin, current_ymax)
# ) +
#   
#   scale_x_discrete(
#     expand = expansion(mult = c(
#       x_axis_spacing,
#       x_axis_spacing
#     ))
#   ) +
  
  ########################################################
# COLORS
########################################################

scale_fill_manual(values = palette) +
  
  ########################################################
# THEME
########################################################

theme_classic(base_size = 14) +
  
  theme(
    legend.position = "none",
    axis.text.x = element_text(
      face = "bold",
      angle = x_label_angle,
      hjust = 1,
      vjust = 1
    ),
    
    plot.title = element_text(
      face = "bold",
      size = 12,
      hjust = 0.5
    )
    
  ) +

   labs(
     title = "Cortisol",
     x = "",
     y = "Cortisol [ng/mL]"
   )

# Display the plot
print(plotday)

# Save the plot
ggsave(file.path(OutputPath, "R_output", "Cortisol_wholeDay_plot_jitter.png"), 
       plot = plotday, 
       width = 6, 
       height = 4, 
       dpi = 300)

ggsave(file.path(OutputPath, "R_output", "Cortisol_wholeDay_plot_jitter.svg"), 
       plot = plotday, 
       width = 6, 
       height = 4, 
       dpi = 300)

## Timecourse analysis: linear mixed model ----------------------

# Reshape to long format for modeling 
CortisolData_long_model <- AllDataMerged %>%
  dplyr::select(
    p_code, group, smoke,
    "cortisol_wake-up", "cortisol_15'", "cortisol_30'", "cortisol_45'",
    "cortisol_60'", "cortisol_14:00", "cortisol_15:00", "cortisol_16:00",
    "cortisol_17:00"
  ) %>%
  tidyr::pivot_longer(
    cols = dplyr::starts_with("cortisol"),
    names_to = "timepoint",
    names_prefix = "cortisol_",
    values_to = "Cortisol",
    values_drop_na = FALSE
  )

# Set factor levels (wake-up as reference) and factor types
CortisolData_long_model$timepoint <- factor(
  CortisolData_long_model$timepoint,
  levels = c("wake-up", "15'", "30'", "45'", "60'", "14:00", "15:00", "16:00", "17:00")
)
CortisolData_long_model$group  <- factor(CortisolData_long_model$group)
CortisolData_long_model$smoke  <- factor(CortisolData_long_model$smoke)
CortisolData_long_model$p_code <- factor(CortisolData_long_model$p_code)

# Fit mixed model: timepoint x group interaction, smoke as covariate, random intercept per subject
CortisolTimecourseModel <- lmer(
  Cortisol ~ timepoint * group + smoke + (1 | p_code),
  data = CortisolData_long_model,
  na.action = na.exclude
)

summary(CortisolTimecourseModel)
anova(CortisolTimecourseModel)          # Type III F-tests (via lmerTest) for timepoint, group, smoke, timepoint:group
r.squaredGLMM(CortisolTimecourseModel)  # marginal/conditional R² (via MuMIn)

# Optional: check model assumptions
plot(CortisolTimecourseModel)                          # residuals vs fitted
qqnorm(resid(CortisolTimecourseModel)); qqline(resid(CortisolTimecourseModel))


