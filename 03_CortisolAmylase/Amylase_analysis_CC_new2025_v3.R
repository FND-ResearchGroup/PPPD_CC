# Script for analysis of amylase data 

#load relevant libraries2
rm(list = ls())

# install.packages("lmtest") #need to run only once, not in all sessions
# install.packages("car")
# install.packages("emmeans")
# install.packages("effectsize")

library(lmtest)
library(car)
library(emmeans)
library(effectsize)
library(xlsx)

### 1. Define inputs and outputs of the script

#Set output folder
OutputPath = "F:/Amylase and Cortisol/Amylase_data/Processed results"
if (!dir.exists(file.path(OutputPath, "R_output"))) {
  dir.create(file.path(OutputPath, "R_output"))
}

#Set input folders, load input data 
#Load amylase file
AmylaseDataPath = "F:/Amylase and Cortisol/Amylase_data/Processed results"
setwd(AmylaseDataPath) #
AmylaseData <- read.xlsx("Amylase_AGmatched_2025.xlsx")
#Load CRF file
CRFDataPath = "E:/ConcettiC/PPPD_for_Caps/OriginalResults_04_CRF_all_Subjects/02_Analysed data/R_output"
setwd(CRFDataPath)
CRF <- read.xlsx("CRF_clean.xlsx")

names(AmylaseData)[names(AmylaseData) == "Amylase..U.ml."] <- "Amylase"

# Remove any columns where all values are NA
AmylaseData <- AmylaseData[, colSums(is.na(AmylaseData)) != nrow(AmylaseData)]

#Now reshape the amylase data
AmylaseData_wide <- reshape(data = AmylaseData,
                            idvar = c("p_code", "group"),
                            timevar = "timepoint",
                            direction = "wide",
                            v.names = "Amylase")

# Choose if consider both time points or if you want to take the average
cat("\n==========================================\n")
cat("ANALYSIS OPTION CHOICE\n")
cat("==========================================\n")
cat("Option 1: Keep time points separate (MR_pre and MR_post)\n")
cat("Option 2: Average the two time points for each subject\n")
cat("\n")

analysis_choice <- readline(prompt = "Enter your choice (1 or 2): ")

# Create a suffix for filenames based on choice
if(analysis_choice == "2") {
  analysis_suffix <- "_avg"
  cat("\nYou selected: Average of the two time points\n")
  
  # Calculate average for each subject
  AmylaseData_wide$Amylase_avg <- rowMeans(AmylaseData_wide[, c("Amylase.MR_pre", "Amylase.MR_post")], 
                                           na.rm = TRUE)
  
  # For the simple analysis (t-test), we'll use the average
  # For the covariate analysis, we need to reshape the averaged data
  Amylase_avg_long <- AmylaseData_wide[, c("p_code", "group", "Amylase_avg")]
  names(Amylase_avg_long)[names(Amylase_avg_long) == "Amylase_avg"] <- "Amylase"
  Amylase_avg_long$timepoint <- "average"  # Add a dummy timepoint
  
  # Create a version of Amylase_CRF_Data with averaged values
  # First, merge with CRF data
  Amylase_avg_long$p_code <- as.numeric(gsub("^P0?", "", Amylase_avg_long$p_code))
  Amylase_CRF_Data <- merge(Amylase_avg_long, CRF[, c("p_code", "age", "gender", "smoke")], by = "p_code")
  
  # For the simple analysis, we'll use the wide format with average
  AmylaseData_wide_for_ttest <- AmylaseData_wide
  AmylaseData_wide_for_ttest$AmylaseDelta <- 0  # Dummy value since no pre-post difference exists
  # Note: For averaged data, the t-test on pre-post difference doesn't make sense
  # We'll instead compare group means directly
  use_averaged_for_ttest <- TRUE
  
  #save avg data
  #write_xlsx (AmylaseData_wide_for_ttest, path = "F:/Amylase and Cortisol/Amylase_data/Processed results/AmylaseAvg.xlsx")
  write.xlsx (AmylaseData_wide_for_ttest, file = "F:/Amylase and Cortisol/Amylase_data/Processed results/AmylaseAvg.xlsx")
  
} else {
  analysis_suffix <- "_"
  cat("\nYou selected: Keep time points separate\n")
  
  # Keep original structure for covariate analysis
  Amylase_CRF_Data <- merge(AmylaseData, CRF[, c("p_code", "age", "gender", "smoke")], by = "p_code")
  
  # For simple analysis, keep original delta calculation
  AmylaseData_wide_for_ttest <- AmylaseData_wide
  AmylaseData_wide_for_ttest$AmylaseDelta <- AmylaseData_wide_for_ttest$`Amylase.MR_pre` - AmylaseData_wide_for_ttest$`Amylase.MR_post`
  use_averaged_for_ttest <- FALSE
}

cat("Analysis will proceed with option:", analysis_choice, "\n")
cat("Files will be saved with suffix:", analysis_suffix, "\n")
cat("==========================================\n\n")

### 2. Simple analysis: pre-post difference or group comparison
if(!use_averaged_for_ttest) {
  # Original analysis for separate time points
  # Check normality by group
  group1 <- "HC"
  group2 <- "PPPD"
  normality_group1 <- shapiro.test(AmylaseData_wide_for_ttest$AmylaseDelta[AmylaseData_wide_for_ttest$group == group1])
  normality_group2 <- shapiro.test(AmylaseData_wide_for_ttest$AmylaseDelta[AmylaseData_wide_for_ttest$group == group2])
  
  # Check homogeneity of variances
  var_test <- var.test(AmylaseDelta ~ group, data = AmylaseData_wide_for_ttest)
  
  # Run appropriate t-test
  if(normality_group1$p.value > 0.05 & normality_group2$p.value > 0.05) {
    # If normality assumption is met, use t-test
    if(var_test$p.value > 0.05) {
      test_result <- t.test(AmylaseDelta ~ group, data = AmylaseData_wide_for_ttest, var.equal = TRUE)
      test_used <- "Student's t-test"
    } else {
      test_result <- t.test(AmylaseDelta ~ group, data = AmylaseData_wide_for_ttest, var.equal = FALSE)
      test_used <- "Welch's t-test"
    }
  } else {
    # If normality assumption is violated, use non-parametric test
    test_result <- wilcox.test(AmylaseDelta ~ group, data = AmylaseData_wide_for_ttest)
    test_used <- "Wilcoxon rank-sum test"
  }
  
  # Print results
  cat("\n=== SIMPLE ANALYSIS: Pre-Post Difference ===\n")
  print(normality_group1)
  print(normality_group2)
  print(var_test)
  cat("\nTest used:", test_used, "\n\n")
  print(test_result)
  
  # Save simple analysis results
  sink(file.path(OutputPath, "R_output", paste0("simple_analysis", analysis_suffix, ".txt")))
  cat("SIMPLE ANALYSIS RESULTS\n")
  cat("Analysis type: Pre-post difference (post - pre)\n")
  cat("==========================================\n\n")
  print(normality_group1)
  print(normality_group2)
  print(var_test)
  cat("\nTest used:", test_used, "\n\n")
  print(test_result)
  sink()
  
} else {
  # Alternative analysis for averaged data - compare group means directly
  cat("\n=== SIMPLE ANALYSIS: Group Comparison (Averaged Data) ===\n")
  cat("Note: Since time points are averaged, comparing HC vs PPPD directly\n\n")
  
  # Check normality by group
  group1 <- "HC"
  group2 <- "PPPD"
  normality_group1 <- shapiro.test(Amylase_CRF_Data$Amylase[Amylase_CRF_Data$group == group1])
  normality_group2 <- shapiro.test(Amylase_CRF_Data$Amylase[Amylase_CRF_Data$group == group2])
  
  # Check homogeneity of variances
  var_test <- var.test(Amylase ~ group, data = Amylase_CRF_Data)
  
  # Run appropriate t-test
  if(normality_group1$p.value > 0.05 & normality_group2$p.value > 0.05) {
    # If normality assumption is met, use t-test
    if(var_test$p.value > 0.05) {
      test_result <- t.test(Amylase ~ group, data = Amylase_CRF_Data, var.equal = TRUE)
      test_used <- "Student's t-test"
    } else {
      test_result <- t.test(Amylase ~ group, data = Amylase_CRF_Data, var.equal = FALSE)
      test_used <- "Welch's t-test"
    }
  } else {
    # If normality assumption is violated, use non-parametric test
    test_result <- wilcox.test(Amylase ~ group, data = Amylase_CRF_Data)
    test_used <- "Wilcoxon rank-sum test"
  }
  
  # Print results
  print(normality_group1)
  print(normality_group2)
  print(var_test)
  cat("\nTest used:", test_used, "\n\n")
  print(test_result)
  
  # Save simple analysis results
  sink(file.path(OutputPath, "R_output", paste0("simple_analysis", analysis_suffix, ".txt")))
  cat("SIMPLE ANALYSIS RESULTS\n")
  cat("Analysis type: Group comparison on averaged data (HC vs PPPD)\n")
  cat("==========================================\n\n")
  print(normality_group1)
  print(normality_group2)
  print(var_test)
  cat("\nTest used:", test_used, "\n\n")
  print(test_result)
  sink()
}

### 3. Analysis with covariates: smoke can influence amylase
# Run linear models including covariates

if(!use_averaged_for_ttest) {
  # Original analysis with time points separate
  # Define covariate combinations
  covariate_sets <- list(
    c("age", "gender"),
    c("smoke"),
    c("age", "gender", "smoke")
  )
  
  # Run models for each covariate set
  models <- list()
  for (i in seq_along(covariate_sets)) {
    formula_text <- paste("Amylase ~ group * timepoint +", paste(covariate_sets[[i]], collapse = " + "))
    formula <- as.formula(formula_text)
    models[[i]] <- lm(formula, data = Amylase_CRF_Data)
    
    # Create output file for this model
    output_file <- file.path(OutputPath, "R_output", paste0("model_", i, analysis_suffix, ".txt"))
    sink(output_file)
    
    cat("MODEL", i, "RESULTS\n")
    cat("Covariates:", paste(covariate_sets[[i]], collapse = ", "), "\n")
    cat("Analysis: Time points separate\n\n")
    
    # Model summary 
    cat("=== MODEL SUMMARY ===\n")
    cat("Formula:", formula_text, "\n\n")
    print(summary(models[[i]]))
    cat("\n")
    
    # ANOVA table
    cat("=== ANOVA TABLE ===\n")
    print(Anova(models[[i]], type = 3))
    cat("\n")
    
    # Effect sizes (Partial Eta Squared)
    cat("=== EFFECT SIZES (Partial Eta Squared) ===\n")
    effects <- eta_squared(models[[i]], partial = TRUE)
    print(effects)
    cat("\n")
    
    # Post-hoc tests for group and timepoint
    cat("=== POST-HOC TESTS FOR GROUP ===\n")
    emm_group <- emmeans(models[[i]], specs = pairwise ~ group)
    print(emm_group$contrasts)
    cat("\n")
    
    cat("=== POST-HOC TESTS FOR TIMEPOINT ===\n")
    emm_time <- emmeans(models[[i]], specs = pairwise ~ timepoint)
    print(emm_time$contrasts)
    cat("\n")
    
    # Model diagnostics
    cat("=== MODEL DIAGNOSTICS ===\n")
    
    # Normality of residuals
    shapiro_test <- shapiro.test(residuals(models[[i]]))
    cat("Shapiro-Wilk normality test of residuals:\n")
    print(shapiro_test)
    cat("\n")
    
    # Heteroscedasticity
    bptest_result <- bptest(models[[i]])
    cat("Breusch-Pagan test for heteroscedasticity:\n")
    print(bptest_result)
    cat("\n")
    
    # Multicollinearity (VIF)
    if(length(covariate_sets[[i]]) > 1) {
      cat("Variance Inflation Factors (VIF):\n")
      vif_values <- vif(models[[i]])
      print(vif_values)
    }
    
    sink()
  }
  
} else {
  # Alternative analysis for averaged data (no timepoint factor)
  covariate_sets <- list(
    c("age", "gender"),
    c("smoke"),
    c("age", "gender", "smoke")
  )
  
  # Run models for each covariate set
  models <- list()
  for (i in seq_along(covariate_sets)) {
    formula_text <- paste("Amylase ~ group +", paste(covariate_sets[[i]], collapse = " + "))
    formula <- as.formula(formula_text)
    models[[i]] <- lm(formula, data = Amylase_CRF_Data)
    
    # Create output file for this model
    output_file <- file.path(OutputPath, "R_output", paste0("model_", i, analysis_suffix, ".txt"))
    sink(output_file)
    
    cat("MODEL", i, "RESULTS\n")
    cat("Covariates:", paste(covariate_sets[[i]], collapse = ", "), "\n")
    cat("Analysis: Time points averaged (no timepoint factor)\n\n")
    
    # Model summary 
    cat("=== MODEL SUMMARY ===\n")
    cat("Formula:", formula_text, "\n\n")
    print(summary(models[[i]]))
    cat("\n")
    
    # ANOVA table
    cat("=== ANOVA TABLE ===\n")
    print(Anova(models[[i]], type = 3))
    cat("\n")
    
    # Effect sizes (Partial Eta Squared)
    cat("=== EFFECT SIZES (Partial Eta Squared) ===\n")
    effects <- eta_squared(models[[i]], partial = TRUE)
    print(effects)
    cat("\n")
    
    # Post-hoc tests for group (no timepoint in averaged model)
    cat("=== POST-HOC TESTS FOR GROUP ===\n")
    emm_group <- emmeans(models[[i]], specs = pairwise ~ group)
    print(emm_group$contrasts)
    cat("\n")
    
    # Model diagnostics
    cat("=== MODEL DIAGNOSTICS ===\n")
    
    # Normality of residuals
    shapiro_test <- shapiro.test(residuals(models[[i]]))
    cat("Shapiro-Wilk normality test of residuals:\n")
    print(shapiro_test)
    cat("\n")
    
    # Heteroscedasticity
    bptest_result <- bptest(models[[i]])
    cat("Breusch-Pagan test for heteroscedasticity:\n")
    print(bptest_result)
    cat("\n")
    
    # Multicollinearity (VIF)
    if(length(covariate_sets[[i]]) > 1) {
      cat("Variance Inflation Factors (VIF):\n")
      vif_values <- vif(models[[i]])
      print(vif_values)
    }
    
    sink()
  }
}

cat("All model results and diagnostics have been saved to:", file.path(OutputPath, "R_output"), "\n")
cat("Files include suffix:", analysis_suffix, "\n")

### 4. Violin plot
library(ggplot2)

if(!use_averaged_for_ttest) {
  # Original violin plot with time points separate
  # Create new combined variable for fill aesthetic
  Amylase_CRF_Data$group_timepoint <- paste(Amylase_CRF_Data$group, Amylase_CRF_Data$timepoint, sep = "_")
  
  # Define the colors
  color_palette <- c(
    "HC_MR_pre" = "#D3D3D3",       # Light grey
    "HC_MR_post" = "#96989c",      # Dark grey
    "PPPD_MR_pre" = "#FFD580",     # Light orange
    "PPPD_MR_post" = "#ec9006"     # Dark orange
  )
  
  # Create the plot
  violin_plot <- ggplot(Amylase_CRF_Data, aes(x = group, y = Amylase, fill = group_timepoint)) +
    geom_violin(alpha = 0.7, trim = FALSE, position = position_dodge(0.8, reverse = TRUE)) +
    geom_boxplot(width = 0.2, alpha = 0.8, position = position_dodge(0.8, reverse = TRUE), outlier.shape = NA) +
    geom_point(position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.8, reverse = TRUE), 
               shape = 1, alpha = 0.5, size = 2.5) +
    labs(title = "Amylase Levels by Group and Timepoint",
         x = "Group",
         y = "Amylase (U/ml)",
         fill = "Group & Timepoint") +
    theme_minimal() +
    scale_fill_manual(values = color_palette,
                      labels = c("HC (MR_pre)", "HC (MR_post)", "PPPD (MR_pre)", "PPPD (MR_post)"))
  
} else {
  # Modified violin plot for averaged data
  violin_plot <- ggplot(Amylase_CRF_Data, aes(x = group, y = Amylase, fill = group)) +
    #geom_violin(alpha = 0.7, width = 0.3, trim = FALSE,position = position_dodge(0.8, reverse = TRUE)) +
    #geom_boxplot(width = 0.1, alpha = 0.8, outlier.shape = NA) +
    #geom_point(position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.8, reverse = TRUE), shape = 1, alpha = 0.5, size = 2.5) +
    
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
    
    labs(title = "Amylase Levels by Group (Averaged across time points)",
         x = "Group",
         y = "Amylase (U/ml)",
         fill = "Group") +
    #theme_minimal() +
    
    theme_classic(base_size = 14) +
    
    theme(
      legend.position = "none",
      axis.text.x = element_text(
        face = "bold",
        #angle = x_label_angle,
        hjust = 1,
        vjust = 1
      ),
      
      plot.title = element_text(
        face = "bold",
        size = 12,
        hjust = 0.5
      )
      
    )+
    
    scale_fill_manual(values = c("HC" = "#96989c", "PPPD" = "#ec9006"))
}

# Display the plot
print(violin_plot)

# Save the plot with suffix
if (analysis_choice == "1"){
  PlotWidth <- 3
} else { 
  PlotWidth <- 2
} 

# original_wd <- getwd() # Save current working directory
# setwd(file.path(OutputPath, "R_output")) # Change to the R_output directory

ggsave(paste0("amylase_violin_plot_v3", analysis_suffix, ".png"),
       plot = violin_plot,
       width = PlotWidth,
       height = 4,
       dpi = 300)  

ggsave(file.path(OutputPath, "R_output", paste0("amylase_violin_plot_v3", analysis_suffix, ".svg")),
       plot = violin_plot,
       width = PlotWidth,
       height = 4,
       dpi = 300,
       device = "svg")

#Note 17.04.2026. Had issues saving in the intended folder, so I exported plots manually into desktop, then moved them to the right folder.


# # Create PNG file
# png_file <- file.path(OutputPath, "R_output", paste0("amylase_violin_plot", analysis_suffix, ".png"))
# png(filename = png_file, width = PlotWidth, height = 4, units = "in", res = 300, type = "cairo")
# print(violin_plot)
# dev.off()
# 
# # Create SVG file
# svg_file <- file.path(OutputPath, "R_output", paste0("amylase_violin_plot", analysis_suffix, ".svg"))
# svg(filename = svg_file, width = PlotWidth, height = 4)
# print(violin_plot)
# dev.off()

cat("\n==========================================\n")
cat("Analysis complete!\n")
cat("All output files have been saved with suffix:", analysis_suffix, "\n")
cat("==========================================\n")


