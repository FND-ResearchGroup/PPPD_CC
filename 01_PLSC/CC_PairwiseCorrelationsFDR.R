# =========================================================
# Pairwise correlations between variables in two XLSX files
# with FDR correction and correlation matrix plot
# =========================================================
#clear R
rm(list = ls())
# -----------------------------
# Install packages if needed
# -----------------------------
packages <- c("readxl", "Hmisc", "corrplot", "reshape2")

installed <- packages %in% rownames(installed.packages())

if(any(!installed)){
  install.packages(packages[!installed])
}

library(readxl)
library(Hmisc)
library(corrplot)
library(reshape2)

# -----------------------------
# USER INPUT
# -----------------------------

# Replace with your actual file paths
file_X <- "F:/CC_PLSC_Analysis_onlyPPPD/X0_wide_output_onlyPPPD_selectedCAPs_onlyVars.xlsx"
file_Y <- "F:/CC_PLSC_Analysis_onlyPPPD/Y0_matrix_reduced_onlyPPPD_withClinicalVars_selectedVars_onlyVars.xlsx"

# Sheet names (optional)
sheet_X <- 1
sheet_Y <- 1

# -----------------------------
# IMPORT DATA
# -----------------------------

X <- read_excel(file_X, sheet = sheet_X)
Y <- read_excel(file_Y, sheet = sheet_Y)

# Convert to data frames
X <- as.data.frame(X)
Y <- as.data.frame(Y)

# -----------------------------
# KEEP ONLY NUMERIC VARIABLES
# -----------------------------

X_num <- X[, sapply(X, is.numeric)]
Y_num <- Y[, sapply(Y, is.numeric)]

# -----------------------------
# CHECK NUMBER OF SUBJECTS
# -----------------------------

if(nrow(X_num) != nrow(Y_num)){
  stop("X and Y must have the same number of rows (subjects).")
}

# -----------------------------
# INITIALIZE MATRICES
# -----------------------------

cor_matrix <- matrix(
  NA,
  nrow = ncol(X_num),
  ncol = ncol(Y_num)
)

p_matrix <- matrix(
  NA,
  nrow = ncol(X_num),
  ncol = ncol(Y_num)
)

rownames(cor_matrix) <- colnames(X_num)
colnames(cor_matrix) <- colnames(Y_num)

rownames(p_matrix) <- colnames(X_num)
colnames(p_matrix) <- colnames(Y_num)

method_matrix <- matrix(
  NA,
  nrow = ncol(X_num),
  ncol = ncol(Y_num)
)

rownames(method_matrix) <- colnames(X_num)
colnames(method_matrix) <- colnames(Y_num)

# -----------------------------
# COMPUTE PAIRWISE CORRELATIONS
# -----------------------------

for(i in 1:ncol(X_num)){
  
  for(j in 1:ncol(Y_num)){
    
    x_var <- X_num[, i]
    y_var <- Y_num[, j]
    
    # Keep complete cases
    complete_idx <- complete.cases(x_var, y_var)
    x_complete <- x_var[complete_idx]
    y_complete <- y_var[complete_idx]
    
    # CHECK PEARSON ASSUMPTIONS
    # Shapiro-Wilk normality tests
    # (only valid for n <= 5000)
    
    if(length(x_complete) <= 5000){
      p_norm_x <- shapiro.test(x_complete)$p.value
    } else {
      p_norm_x <- 1
    }
    
    if(length(y_complete) <= 5000){
      p_norm_y <- shapiro.test(y_complete)$p.value
    } else {
      p_norm_y <- 1
    }
    
    # Decide method automatically
    if(p_norm_x > 0.05 & p_norm_y > 0.05){
      selected_method <- "pearson"
    } else {
      selected_method <- "spearman"
    }
    
    # Run correlation
    test <- cor.test(
      x_complete,
      y_complete,
      method = selected_method
    )
    
    # Store outputs
    cor_matrix[i, j] <- test$estimate
    p_matrix[i, j] <- test$p.value
    method_matrix[i, j] <- selected_method
  }
}

# -----------------------------
# FDR CORRECTION
# -----------------------------

p_vector <- as.vector(p_matrix)

p_fdr <- p.adjust(p_vector, method = "fdr")

p_fdr_matrix <- matrix(
  p_fdr,
  nrow = nrow(p_matrix),
  ncol = ncol(p_matrix)
)

rownames(p_fdr_matrix) <- rownames(p_matrix)
colnames(p_fdr_matrix) <- colnames(p_matrix)

# -----------------------------
# CREATE SIGNIFICANCE LABELS
# -----------------------------

sig_labels <- matrix(
  "",
  nrow = nrow(p_fdr_matrix),
  ncol = ncol(p_fdr_matrix)
)

sig_labels[p_fdr_matrix < 0.05] <- "*"
sig_labels[p_fdr_matrix < 0.01] <- "**"
sig_labels[p_fdr_matrix < 0.001] <- "***"

# -----------------------------
# SAVE RESULTS TABLES
# -----------------------------

write.csv(cor_matrix, "F:/CC_PLSC_Analysis_onlyPPPD/SimpleCorrelations/correlation_coefficients.csv")
write.csv(p_matrix, "F:/CC_PLSC_Analysis_onlyPPPD/SimpleCorrelations/raw_pvalues.csv")
write.csv(p_fdr_matrix, "F:/CC_PLSC_Analysis_onlyPPPD/SimpleCorrelations/fdr_corrected_pvalues.csv")
write.csv(method_matrix, "F:/CC_PLSC_Analysis_onlyPPPD/SimpleCorrelations/correlation_methods.csv")

# -----------------------------
# PLOT CORRELATION MATRIX
# -----------------------------

# Open graphics device (optional)
png(
  filename = "F:/CC_PLSC_Analysis_onlyPPPD/SimpleCorrelations/correlation_matrix.png",
  width = 4000,
  height = 3500,
  res = 300
)

corrplot(
  cor_matrix,
  method = "color",
  col = colorRampPalette(c("blue", "white", "red"))(200),
  tl.col = "black",
  tl.srt = 45,
  tl.cex = 1,
  is.corr = FALSE,
  # cl.lim = c(-1, 1),
  addCoef.col = "black",
  number.cex = 1
)

# Add significance stars
for(i in 1:nrow(cor_matrix)){
  for(j in 1:ncol(cor_matrix)){
    
    text(
      x = j,
      y = nrow(cor_matrix) - i + 1,
      labels = sig_labels[i, j],
      col = "white",
      cex = 1.5
    )
  }
}

dev.off()

# -----------------------------
# OPTIONAL: PRINT SUMMARY
# -----------------------------

cat("\nAnalysis completed.\n")
cat("Correlation matrix saved as: correlation_coefficients.csv\n")
cat("Raw p-values saved as: raw_pvalues.csv\n")
cat("FDR-corrected p-values saved as: fdr_corrected_pvalues.csv\n")
cat("Correlation plot saved as: correlation_matrix.png\n")