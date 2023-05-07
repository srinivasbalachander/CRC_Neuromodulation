library(readxl)


df <- read_excel("MoCA.xlsx", sheet = 2) 


df <-  df[, c("Project.Number", 
              "Total_baseline_phase 1" ,
              "Total_postintervention_phase 1",
              "Total__prephase2",
              "Total_postintervention_phase2")]

df <- data.frame(df)

df.long <- reshape(data = df, 
                    varying = c("Total_baseline_phase.1" ,
                                  "Total_postintervention_phase.1",
                                  "Total__prephase2",
                                  "Total_postintervention_phase2"),
                    v.names = "MoCA_Total",
                    timevar = "Time",
                    idvar = "Project.Number",
                    times = c("baseline_phase.1",
                              "postintervention_phase.1",
                              "prephase2",
                              "postintervention_phase2"),
                    direction = "long")

rownames(df.long) <- NULL

 
df.long <- df.long[!(is.na(df.long$MoCA_Total)),]


df.long$Time <- factor(df.long$Time, levels = c("baseline_phase.1",
                                                   "postintervention_phase.1",
                                                   "prephase2",
                                                   "postintervention_phase2"),
                                    labels = c("BSL", 
                                               "Post1", 
                                               "Pre2", 
                                               "Post2"))

library(ggplot2)

ggplot(data = df.long, mapping = aes(x=Time, y = MoCA_Total)) +
  geom_point() + geom_line(aes(group = Project.Number, color = Project.Number))
  



