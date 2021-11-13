library(data.table)
library(ggplot2)
library(extrafont)
library(ggpubr)
loadfonts(device = "win")

options(stringsAsFactors = FALSE)
setwd("C:/Users/aashisjoshi/surfdrive/Sustainability paper/Sustainability paper/final")
filename='experiment-results-main.csv'
alldata = read.table(filename, skip=6, head=TRUE,  sep=',', comment.char = "")

names(alldata)[names(alldata) == 'X.run.number.'] <- 'run'
names(alldata)[names(alldata) == 'X.step.'] <- 'duration'
names(alldata)[names(alldata) == 'global.mean.capability.attainment'] <- 'avg.cap.attainment'
names(alldata)[names(alldata) == 'avg.built.sys.state'] <- 'avg.sys.state'
names(alldata)[names(alldata) == 'capability.acceptable.level..'] <- 'cap.acceptable.pc'
names(alldata)[names(alldata) == 'capability.good.level..'] <- 'cap.good.pc'
names(alldata)[names(alldata) == 'capability.unacceptable.level..'] <- 'cap.unacceptable.pc'
names(alldata)[names(alldata) == 'avg.built.sys.links.per.person'] <- 'avg.sys.links.per.person'
names(alldata)[names(alldata) == 'stdev.global.capability.attainment'] <- 'stdev.cap.attainment'
names(alldata)[names(alldata) == 'capability.call.help'] <- 'cap.help.on'

##################################################
##################################################
newdata <- alldata[order(alldata$duration),]

newdata$collapsed.or.not <- newdata$duration
newdata$collapsed.or.not[newdata$duration==3000] <- 0
newdata$collapsed.or.not[newdata$duration!=3000] <- 1
newdata$collapsed.total <- cumsum(newdata$collapsed.or.not)

###################################################
######        x = random.damage.limit        ######
###################################################

plot1data <- newdata
plot2data <- subset(newdata, seek.capability.when == "avg-capability-attainment < capability-high"
                    & share.access.potential == "no" & cap.help.on == "false")
plot2data$collapsed.no.sharing <- cumsum(plot2data$collapsed.or.not)
plot3data <- subset(newdata, seek.capability.when == "avg-capability-attainment < capability-high"
                    & share.access.potential == "yes, through a community fund" & cap.help.on == "false")
plot3data$collapsed.comm.fund <- cumsum(plot3data$collapsed.or.not)
plot4data <- subset(newdata, seek.capability.when == "avg-capability-attainment < capability-high"
                    & share.access.potential == "yes, through personal transfers" & cap.help.on == "false")
plot4data$collapsed.pers.trans <- cumsum(plot4data$collapsed.or.not)
plot5data <- subset(newdata, seek.capability.when == "avg-capability-attainment < capability-high"
                    & cap.help.on == "true")
plot5data$collapsed.cap.help <- cumsum(plot5data$collapsed.or.not)

#########################################################################
#########################################################################


gg1 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=cap.good.pc+cap.acceptable.pc, colour="No redistribution"), span=0.1 ) +
  geom_smooth(data=plot3data, aes(y=cap.good.pc+cap.acceptable.pc, colour="Egalitarian"), span=0.1 ) +
  geom_smooth(data=plot4data, aes(y=cap.good.pc+cap.acceptable.pc, colour="Difference-proportionate"), span=0.1 ) +
  geom_smooth(data=plot5data, aes(y=cap.good.pc+cap.acceptable.pc, colour="Sufficientarian"), span=0.1 ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="% of people with desirable or acceptable capability attainment", 
       y="% of people", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg2 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=cap.good.pc, colour="No redistribution"), span=0.1  ) +
  geom_smooth(data=plot3data, aes(y=cap.good.pc, colour="Egalitarian"), span=0.1  ) +
  geom_smooth(data=plot4data, aes(y=cap.good.pc, colour="Difference-proportionate"), span=0.1  ) +
  geom_smooth(data=plot5data, aes(y=cap.good.pc, colour="Sufficientarian"), span=0.1  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="% of people with desirable capability attainment", 
       y="% of people", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg3 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=cap.unacceptable.pc, colour="No redistribution"), span=0.1  ) +
  geom_smooth(data=plot3data, aes(y=cap.unacceptable.pc, colour="Egalitarian"), span=0.1  ) +
  geom_smooth(data=plot4data, aes(y=cap.unacceptable.pc, colour="Difference-proportionate"), span=0.1  ) +
  geom_smooth(data=plot5data, aes(y=cap.unacceptable.pc, colour="Sufficientarian"), span=0.1  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="% of people with unacceptable capability attainment", 
       y="% of people", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg4 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=cap.acceptable.pc, colour="No redistribution"), span=0.1  ) +
  geom_smooth(data=plot3data, aes(y=cap.acceptable.pc, colour="Egalitarian"), span=0.1  ) +
  geom_smooth(data=plot4data, aes(y=cap.acceptable.pc, colour="Difference-proportionate"), span=0.1  ) +
  geom_smooth(data=plot5data, aes(y=cap.acceptable.pc, colour="Sufficientarian"), span=0.1  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="% of people with acceptable capability attainment", 
       y="% of people", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)),
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg5 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=avg.sys.state, colour="No redistribution"), span=0.1  ) +
  geom_smooth(data=plot3data, aes(y=avg.sys.state, colour="Egalitarian"), span=0.1  ) +
  geom_smooth(data=plot4data, aes(y=avg.sys.state, colour="Difference-proportionate"), span=0.1  ) +
  geom_smooth(data=plot5data, aes(y=avg.sys.state, colour="Sufficientarian"), span=0.1  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Mean system-state of resource systems", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg6 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=max.global.mean.capability.attainment, colour="No redistribution"), span=0.1, linetype="dashed") +
  geom_smooth(data=plot3data, aes(y=max.global.mean.capability.attainment, colour="Egalitarian"), span=0.1, linetype="dashed") +
  geom_smooth(data=plot4data, aes(y=max.global.mean.capability.attainment, colour="Difference-proportionate"), span=0.1, linetype="dashed") +
  geom_smooth(data=plot5data, aes(y=max.global.mean.capability.attainment, colour="Sufficientarian"), span=0.1, linetype="dashed") +
  geom_smooth(data=plot2data, aes(y=min.global.mean.capability.attainment, colour="No redistribution"), span=0.1) +
  geom_smooth(data=plot3data, aes(y=min.global.mean.capability.attainment, colour="Egalitarian"), span=0.1) +
  geom_smooth(data=plot4data, aes(y=min.global.mean.capability.attainment, colour="Difference-proportionate"), span=0.1) +
  geom_smooth(data=plot5data, aes(y=min.global.mean.capability.attainment, colour="Sufficientarian"), span=0.1) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Max. and min. global mean capability attainment of people", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg7 <- ggplot(NULL, aes(x=duration, size=random.damage.limit)) + 
  geom_smooth(data=plot2data, aes(y=100*collapsed.no.sharing/nrow(plot2data), colour="No redistribution") ) +
  geom_smooth(data=plot3data, aes(y=100*collapsed.comm.fund/nrow(plot3data), colour="Egalitarian") ) +
  geom_smooth(data=plot4data, aes(y=100*collapsed.pers.trans/nrow(plot4data), colour="Difference-proportionate") ) +
  geom_smooth(data=plot5data, aes(y=100*collapsed.cap.help/nrow(plot5data), colour="Sufficientarian") ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="% of runs that collapsed under different distributive principles", 
       y="% of runs collapsed", x="duration (ticks)") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg8 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_smooth(data=plot2data, aes(y=aggr.system.recoveries, colour="No redistribution"), span=0.1) +
  geom_smooth(data=plot3data, aes(y=aggr.system.recoveries, colour="Egalitarian"), span=0.1) +
  geom_smooth(data=plot4data, aes(y=aggr.system.recoveries, colour="Difference-proportionate"), span=0.1) +
  geom_smooth(data=plot5data, aes(y=aggr.system.recoveries, colour="Sufficientarian"), span=0.1) +
  # geom_smooth(data=plot2data, aes(y=aggr.system.damages, colour="No redistribution"), span=0.1, linetype="dashed") +
  # geom_smooth(data=plot3data, aes(y=aggr.system.damages, colour="Egalitarian"), span=0.1, linetype="dashed") +
  # geom_smooth(data=plot4data, aes(y=aggr.system.damages, colour="Difference-proportionate"), span=0.1, linetype="dashed") +
  # geom_smooth(data=plot5data, aes(y=aggr.system.damages, colour="Sufficientarian"), span=0.1, linetype="dashed") +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Aggregate resource system damage repairs", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)), 
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

#####################################################################
#####################################################################


ggarrange(gg1, gg3, gg2, gg4, 
          labels = c("A:", "B:", "C:", "D:"),
          ncol = 2, nrow = 2, common.legend = TRUE, legend="bottom")
ggsave("summary-cap-attainments-1.png",width = 16, height = 12)


ggarrange(gg7, gg5, gg6, gg8, 
          labels = c("A:", "B:", "C:", "D:"),
          ncol = 2, nrow = 2, common.legend = TRUE, legend="bottom")
ggsave("summary-other-metrics-1.png",width = 16, height = 12)

