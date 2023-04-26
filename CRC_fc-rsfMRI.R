library(ggplot2)
library(effectsize)

# Load important packages for parallel processing
library(foreach)
library(doParallel)

# Specifications for parallel processing
n.cores <- parallel::detectCores() - 4

my.cluster <- parallel::makeCluster(n.cores, type = "FORK")
doParallel::registerDoParallel(cl = my.cluster)
foreach::getDoParRegistered()
foreach::getDoParWorkers()

# Set Directory with the ENIGMA_rs_halfpipe folder, the mats folder, and the covariates csv file

setwd("/media/janardhanan/DATADRIVE2/CRC_Folder")

# Specify covariates file

covs <- read.csv("Dummy_Covariates.csv")
# covs$Sex <- factor(covs$Sex, levels = c("Male", "Female"))  # If you want to change orders, for some reason

# Specify which atlas you want to use:
  # Can be  "schaefer2011Combined", or "brainnetomeCombined" or "power2011"

atlas <- "brainnetomeCombined"

# Read atlas labels file

atlas_labels <- read.table(paste0("ENIGMA_rs_halfpipe/tpl-MNI152NLin2009cAsym_atlas-", atlas, "_dseg.txt"))

# Renaming atlas labels

if(atlas == "schaefer2011Combined") {rem_label <- "Schaefer2018_17Networks_" }
if(atlas == "brainnetomeCombined") {rem_label <- "Brainnetome_" }
if(atlas == "power2011") {rem_label <- "Power2011_" }

atlas_labels$V2 <- gsub(rem_label, "", atlas_labels$V2)

# Give a subset of ROIs

roi.set <- c("A9/46d_L", "A9/46d_R", # DLPFC
             "A41/42_L", "A41/42_R", # TPJ
             "A39rv_L", "A39rv_R",   # IPL
             "A40rv_L", "A40rv_R",   # IPL
             "rHipp_L", "rHipp_R",   # Hippocampus
             "cHipp_L", "cHipp_R",   # Hippocampus
             "A32sg_L", "A32sg_R",   # ACC
             "dCa_L", "dCa_R"        # Caudate
             )

n.rois <- length(roi.set)

roi.mat <- matrix(nrow = length(roi.set),
                  ncol = length(roi.set))

rownames(roi.mat) <- roi.set
colnames(roi.mat) <- roi.set


# Make the long format of the connectivity matrix

conn.long <- data.frame(x.roi = rep(roi.set, each = n.rois),
                        y.roi = rep(roi.set, times = n.rois),
                        roi.roi = NA, d = NA, p = NA, index = NA,
                        x.roi.index = rep(1:n.rois, each = n.rois),
                        y.roi.index = rep(1:n.rois, times = n.rois))

conn.long$roi.roi <- paste0(conn.long$x.roi, ".", conn.long$y.roi)

# Make these indexes such that duplicates & diagonals are removed, so that computation time is halved
conn.long <- conn.long[conn.long$x.roi.index < conn.long$y.roi.index,]

conn.long$index <- 1:nrow(conn.long)

conn.long <- conn.long[,c("index", "x.roi", "y.roi", "roi.roi", "d", "p")]


# Specify which correction method
# Can be either of:  "corrMatrix" (ICA-AROMA) or "corrMatrix1" (aCompCor) or "corrMatrix2" (Both)

cor_method <- "corrMatrix"

# Get list of subjects, with the specified atlas and correction method

sub_list <- gsub(".*sub-(.+)_task.*", "\\1",  Sys.glob(paste0("CRC_mats/",
                                                              "sub-", "*",
                                                              "_task-rest",
                                                              "_feature-",cor_method,
                                                              "_atlas-", atlas,
                                                              "_desc-correlation_matrix.tsv")))


# Make blank templates for all your results of interest

conn.long.schiz <- conn.long
conn.long.dep <- conn.long


# Run a for loop for all ROIs

for(n in conn.long$index){
 
  i = conn.long[conn.long$index == n, "x.roi"]
  j = conn.long[conn.long$index == n, "y.roi"]

    con.ij <- data.frame(subid=NA, r=NA)
   
    for(k in sub_list){
      # Read subject k's connectivity matrix
      conmat <- read.table(paste0("CRC_mats/",
                             "sub-", k,
                             "_task-rest",
                             "_feature-",cor_method,
                             "_atlas-", atlas,
                             "_desc-correlation_matrix.tsv"))
     
      conmat[conmat == "NaN"] <- NA
     
      # Rename the rows and columns of the connectivity matrix
      rownames(conmat) <- atlas_labels$V2
      colnames(conmat) <- atlas_labels$V2
     
      # Extract the i ROI - j ROI connecitivty and bind it the con.ij object
      row.con.ij <- c(k, conmat[i,j])
     
      con.ij <- rbind(con.ij, row.con.ij)
      }
 
    # Remove a useless NA row
    con.ij <- con.ij[-1,]
   
    # Merging the connectivites with the covariates file
    covs2 <- merge(covs, con.ij, by = "subid")
   
    # Running the GLM
   
    mod <- lm(r ~ scale(Age) + Sex + Group, data= covs2)
    coef.table <- coefficients(summary(mod))
   
    effs <- effectsize::effectsize(mod)
   
    d.schiz <- effs[effs$Parameter == "GroupDepression", "Std_Coefficient"]
    d.dep <- effs[effs$Parameter == "GroupSchizophrenia", "Std_Coefficient"]
   
    p.schiz <-  coef.table["GroupDepression", "Pr(>|t|)"]
    p.dep <-  coef.table["GroupSchizophrenia", "Pr(>|t|)"]
   
    d.schiz.mat[i,j] <- d.schiz
    p.schiz.mat[i,j] <- p.schiz
   
    d.dep.mat[i,j] <- d.dep
    p.dep.mat[i,j] <- p.dep
  }
