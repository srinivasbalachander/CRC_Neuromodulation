library(dplyr)

wiser.dw <- read.csv("rawdata/report_2020-01-01_to_2023-03-30.csv")
wiser.names <- read.csv("colnames/Colnames_BSL.csv")

bsl.vars <- wiser.names[wiser.names$CRC_Relevant == "Yes", "Col.Name"]
wiser.dw <- wiser.dw[, bsl.vars]

crc.bsl <- wiser.dw %>% filter(project_id_1DV %in% c("Clinical Research centre for neuromodulation",
                                                     "CRP-Pilot studies of CRC",
                                                     "Pilot studies of CRC") |
                               interviewer_name_1DV %in% c("Sreepriya", "Sachin1", "Rujuta", 
                                                           "RajKumar", "Nathiya", "makarand", 
                                                           "Kiran", "Ketaki", "Chithra"))


crc.bsl$primary_diagnosis <- crc.bsl$primary_diagnosis %>% dplyr::recode(`0` = "HC",
                                                                          `1` = "Schizophrenia",
                                                                          `2` = "OCD",
                                                                          `3` = "MDD",
                                                                          `4` = "BPAD",
                                                                          `5` = "Dementia",
                                                                          `6` = "Addiction",
                                                                          `7` = "Panic Disorder")

IDs <-  c("Center.Id", "id", "Project.Number", "Name")

vars.demog <- c("Center.Id", "id", "Project.Number", "Name", "Patient.Number", "UHID", 
                "Gender", "Date.of.Birth", "Age", "primary_diagnosis", "ses_1DV", 
                "years_of_education_1DV",   "occupation_1DV", "marital_status_1DV",  
                "languages_spoken_1DV","assessment_date_1DV")

demogr <- crc.bsl[, vars.demog]

ahrs <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "AHRS", "Col.Name"])] 

sans <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "SANS", "Col.Name"])] 

saps <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "SAPS", "Col.Name"])]

cdrs <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "CDRS", "Col.Name"])]

hama <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "HAMA", "Col.Name"])]

hamd <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "HAMD", "Col.Name"])]

idssr <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "IDS_SR", "Col.Name"])]

bacs <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "BACS", "Col.Name"])]

sCGI <- crc.bsl[, c(IDs, wiser.names[wiser.names$Scale == "sCGI", "Col.Name"])]
