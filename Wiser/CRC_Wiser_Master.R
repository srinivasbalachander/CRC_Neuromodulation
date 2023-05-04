library(readxl)
library(dplyr)
library(stringr)

# Read any Wiser Detail-Work Up Export
wiser.dw <- read.csv("rawdata/DW_2020-01-01_to_2023-05-04.csv")
wiser.fu <- read.csv("rawdata/FU_2020-01-01_to_2023-05-04.csv")

# Remove bad entries in Wiser

wiser.dw <- wiser.dw[!(is.na(wiser.dw$Center.Id)),]
wiser.fu <- wiser.fu[!(is.na(wiser.fu$Center.Id)),]


wiser.dw$primary_diagnosis <- wiser.dw$primary_diagnosis %>% dplyr::recode(`0` = "HC",
                                                                           `1` = "Schizophrenia",
                                                                           `2` = "OCD",
                                                                           `3` = "MDD",
                                                                           `4` = "BPAD",
                                                                           `5` = "Dementia",
                                                                           `6` = "Addiction",
                                                                           `7` = "Panic Disorder")

wiser.fu$primary_diagnosis <- wiser.fu$primary_diagnosis %>% dplyr::recode(`0` = "HC",
                                                                           `1` = "Schizophrenia",
                                                                           `2` = "OCD",
                                                                           `3` = "MDD",
                                                                           `4` = "BPAD",
                                                                           `5` = "Dementia",
                                                                           `6` = "Addiction",
                                                                           `7` = "Panic Disorder")



# Read our curated CRC Demographix File
regs <- read_excel("metadata/CRC_Demog.xlsx")
regs <- regs[,c("Center.Id", "id", "Project.Number","Name","Age","Gender")]

# regs <- regs[str_detect(regs$ProjectNumber, "CR") & !is.na(regs$ProjectNumber),]


# Merge just the required rows in wiser make crc.wiser

crc.wiser.dw <- merge(regs, select(wiser.dw, -Project.Number, -Name, -Age, -Gender), by=c("Center.Id", "id"))
crc.wiser.fu <- merge(regs, select(wiser.fu, -Project.Number, -Name, -Age, -Gender), by=c("Center.Id", "id"))

# Do some column cleaning
names(crc.wiser.dw) <- gsub(".*.as\\.\\.", "", names(crc.wiser.dw))  
names(crc.wiser.dw) <- gsub("\\.", "", names(crc.wiser.dw))  
names(crc.wiser.dw) <- gsub("__", "_", names(crc.wiser.dw))

names(crc.wiser.fu) <- gsub(".*.as\\.\\.", "", names(crc.wiser.fu))  
names(crc.wiser.fu) <- gsub("\\.", "", names(crc.wiser.fu))  
names(crc.wiser.fu) <- gsub("__", "_", names(crc.wiser.fu)) 

# Read Wiser Column Names File
wiser.names <- read.csv("metadata/Colnames2.csv")

wiser.names$Col.Name <- gsub(".*\\.as\\.\\.", "", wiser.names$Col.Name)  
wiser.names$Col.Name <- gsub("\\.", "", wiser.names$Col.Name)  
wiser.names$Col.Name <- gsub("__", "_", wiser.names$Col.Name)  

wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"] <- substr(wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"], 1,
                                                                         nchar(wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"])-1)

# Make a demographic sheet
demog.cols <- wiser.names[wiser.names$Scale == "Regis" |
                            wiser.names$Scale == "Demog", "Col.Name"]

demog.cols[!(demog.cols %in% names(crc.wiser.dw))] <- paste0(demog.cols[!(demog.cols %in% names(crc.wiser.dw))], "_1DW")

crc.demogs <- crc.wiser.dw[,demog.cols]

crc.demogs$CenterId <- crc.demogs$CenterId %>% recode(`1` = "NIMHANS",
                                                      `2` = "KMC",
                                                      `3` = "CIP")

crc.demogs$Study <- substr(crc.demogs$ProjectNumber, 7,7)

crc.demogs$Study <- crc.demogs$Study %>% recode(`1` = "Study 1",
                                                `2` = "Study 2",
                                                `3` = "Study 3",
                                                `0` = "HC" )

crc.demogs <- crc.demogs %>% select(id, CenterId, Study, ProjectNumber, Name, Age, Gender, everything())
crc.demogs <- crc.demogs %>% select(-DateofBirth, -AadharNumber)

# Make the whole Wiser into long format

crc.cols <- wiser.names[wiser.names$CRC_Relevant == "Yes" &
                          wiser.names$Scale != "Regis" &
                          wiser.names$Scale != "Demog", "Col.Name"]


crc.cols <- crc.cols[-2]  # Remove the interviewer name from this, because the follow-up export does not have it!

timepts.dw <- c("DW1", "DW2", "DW3")
timepts.fu <- c("FU1", "FU2", "FU3", "FU4", "FU5", "FU6", "FU7", "FU8", "FU9", "FU10")

crc.long.dw <- data.frame()
crc.long.fu <- data.frame()

for(i in timepts.dw){
  # Make the time labels, and make column names to match with main wiser sheet
  time.label <- paste0("_", match(i, timepts.dw), "DW")
  col.names <- c("ProjectNumber", paste0(crc.cols, time.label))
  
  # Get columns from main wiser sheet
  crc.i <- crc.wiser.dw[,col.names]
  crc.i <- data.frame(Assessment.Time = rep(i, times = nrow(crc.i)), crc.i)
  
  # Remove time label from the column names
  names(crc.i) <- gsub(time.label, "", names(crc.i))  
  crc.long.dw <- rbind(crc.long.dw, crc.i)}


for(i in timepts.fu){
  # Make the time labels, and make column names to match with main wiser sheet
  time.label <- paste0("_", match(i, timepts.fu), "FU")
  col.names <- c("ProjectNumber", paste0(crc.cols, time.label))
  
  # Get columns from main wiser sheet
  crc.i <- crc.wiser.fu[,col.names]
  crc.i <- data.frame(Assessment.Time = rep(i, times = nrow(crc.i)), crc.i)
  
  # Remove time label from the column names
  names(crc.i) <- gsub(time.label, "", names(crc.i))  
  crc.long.fu <- rbind(crc.long.fu, crc.i)}


# Remove rows with too many missing data (almost all missing)
crc.long.dw <- crc.long.dw[rowSums(is.na(crc.long.dw[,4:382])) < 374, ]
crc.long.fu <- crc.long.fu[rowSums(is.na(crc.long.fu[,4:382])) < 374, ]

# Make individual data frames for each time point

IDs <- c("Assessment.Time", "ProjectNumber", "assessment_date")

list.scales <- c("CGI", "AHRS", "BPRS", "SANS", "SAPS",
                 "MADRS", "HAMA", "HAMD","IDSSR",
                 "BACS", "B4ECTReCoDe", "S_CGI")

all.scales <- list()


for(j in list.scales) {
  
  subset.dw <- crc.long.dw[, c(IDs, wiser.names[wiser.names$Scale == j, "Col.Name"])]
  subset.fu <- crc.long.fu[, c(IDs, wiser.names[wiser.names$Scale == j, "Col.Name"])]
  
  names(subset.dw)[4] <- "administered"
  names(subset.fu)[4] <- "administered"
  
  subset.dw <- subset.dw[subset.dw$administered == 1 & !is.na(subset.dw$administered), ]
  subset.fu <- subset.fu[subset.fu$administered == 1 & !is.na(subset.fu$administered), ]
  
  subset <- rbind(subset.dw, subset.fu)
  
  all.scales[[j]] <- subset
  
}


# Write all files to a CSV

write.csv(crc.demogs, "Demogs.csv")

sapply(names(all.scales), 
       function (x) write.table(all.scales[[x]], sep = ",", row.names = FALSE, 
                                file=paste(x, "csv", sep=".")))


