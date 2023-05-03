library(readxl)
library(dplyr)
library(stringr)

# Read any Wiser Detail-Work Up Export
wiser.dw <- read.csv("rawdata/report_2020-05-02_to_2023-05-02.csv")

wiser.dw$primary_diagnosis <- wiser.dw$primary_diagnosis %>% dplyr::recode(`0` = "HC",
                                                                         `1` = "Schizophrenia",
                                                                         `2` = "OCD",
                                                                         `3` = "MDD",
                                                                         `4` = "BPAD",
                                                                         `5` = "Dementia",
                                                                         `6` = "Addiction",
                                                                         `7` = "Panic Disorder")
# Do some column cleaning
names(wiser.dw) <- gsub(".*\\.as\\.\\.", "", names(wiser.dw))  
names(wiser.dw) <- gsub("\\.", "", names(wiser.dw))  
names(wiser.dw) <- gsub("__", "_", names(wiser.dw))  

# Read our curated CRC Demographix File
regs <- read_excel("metadata/CRC_Demog.xlsx")
regs <- regs[,c("CenterId", "id", "ProjectNumber","Name","Age","Gender")]
regs <- regs[str_detect(regs$ProjectNumber, "CR") & !is.na(regs$ProjectNumber),]

# Read Wiser Column Names File
wiser.names <- read.csv("metadata/Colnames2.csv")

wiser.names$Col.Name <- gsub(".*\\.as\\.\\.", "", wiser.names$Col.Name)  
wiser.names$Col.Name <- gsub("\\.", "", wiser.names$Col.Name)  
wiser.names$Col.Name <- gsub("__", "_", wiser.names$Col.Name)  

wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"] <- substr(wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"], 1,
                                                                         nchar(wiser.names$Col.Name[str_sub(wiser.names$Col.Name, -1) == "_"])-1)

crc.cols <- wiser.names[wiser.names$CRC_Relevant == "Yes" &
                          wiser.names$Scale != "Regis" &
                          wiser.names$Scale != "Demog", "Col.Name"]

timepts <- c("BSL", "FU1",  "FU2", "FU3", "FU4", "FU5", "FU6", "FU7", "FU8", "FU9", "FU10" )

crc.long <- data.frame()

for(i in timepts){
  # Make the time labels, and make column names to match with main wiser sheet
  time.label <- paste0("_", match(i, timepts), "DV")
  col.names <- c("ProjectNumber", paste0(crc.cols, time.label))
  
  # Get columns from main wiser sheet
  crc.i <- wiser.dw[wiser.dw$ProjectNumber %in% regs$ProjectNumber, col.names]
  
  crc.i <- data.frame(Assessment.Time = rep(i, times = nrow(crc.i)),
                      crc.i)
  
  # Remove time label from the column names
  names(crc.i) <- gsub(time.label, "", names(crc.i))  
  crc.long <- rbind(crc.long, crc.i)
  
  }


crc.long2 <- crc.long[rowSums(is.na(crc.long[,5:373])) < 365, ]

IDs <- c("Assessment.Time", "ProjectNumber", "assessment_date", "interviewer_name")

scales <- c("AHRS", "MADRS",
           "BPRS", "SANS", "SAPS", "HAMA", "HAMD", 
           "IDSSR", "BACS", "B4ECTReCoDe", "S_CGI")

list.scales <- list()


for(i in scales) {
  
  list.scales[[i]] <- crc.long2[, c(IDs, wiser.names[wiser.names$Scale == i, "Col.Name"])]
  
}
