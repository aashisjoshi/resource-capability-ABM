library(data.table)
library(ggplot2)
library(extrafont)
library(ggpubr)
loadfonts(device = "win")

options(stringsAsFactors = FALSE)
setwd("C:/Users/aashisjoshi/surfdrive/Sustainability paper/Sustainability paper/final")
filename='experiment-results-additional.csv'
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

gg1 <- ggplot(NULL, aes(x=random.damage.limit)) + 
  geom_smooth(data=plot2data, aes(y=access.potential.final.global.mean, colour="No redistribution"), span=0.3  ) +
  geom_smooth(data=plot3data, aes(y=access.potential.final.global.mean, colour="Egalitarian"), span=0.3  ) +
  geom_smooth(data=plot4data, aes(y=access.potential.final.global.mean, colour="Difference-proportionate"), span=0.3  ) +
  geom_smooth(data=plot5data, aes(y=access.potential.final.global.mean, colour="Sufficientarian"), span=0.3  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Access potential global mean", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)),
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg2 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_point(data=plot2data, aes(y=access.potential.final.global.mean, colour="No redistribution"), shape=0 ) +
  geom_point(data=plot3data, aes(y=access.potential.final.global.mean, colour="Egalitarian"), shape=1 ) +
  geom_point(data=plot4data, aes(y=access.potential.final.global.mean, colour="Difference-proportionate"), shape=2 ) +
  geom_point(data=plot5data, aes(y=access.potential.final.global.mean, colour="Sufficientarian"), shape=3 ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Access potential global mean", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)),
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg3 <- ggplot(NULL, aes(x=random.damage.limit)) + 
  geom_smooth(data=plot2data, aes(y=access.potential.final.global.stdev, colour="No redistribution"), span=0.3  ) +
  geom_smooth(data=plot3data, aes(y=access.potential.final.global.stdev, colour="Egalitarian"), span=0.3  ) +
  geom_smooth(data=plot4data, aes(y=access.potential.final.global.stdev, colour="Difference-proportionate"), span=0.3  ) +
  geom_smooth(data=plot5data, aes(y=access.potential.final.global.stdev, colour="Sufficientarian"), span=0.3  ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Access potential global standard deviation", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)),
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))

gg4 <- ggplot(NULL, aes(x=random.damage.limit, size=duration)) + 
  geom_point(data=plot2data, aes(y=access.potential.final.global.stdev, colour="No redistribution"), shape=0 ) +
  geom_point(data=plot3data, aes(y=access.potential.final.global.stdev, colour="Egalitarian"), shape=1 ) +
  geom_point(data=plot4data, aes(y=access.potential.final.global.stdev, colour="Difference-proportionate"), shape=2 ) +
  geom_point(data=plot5data, aes(y=access.potential.final.global.stdev, colour="Sufficientarian"), shape=3 ) +
  scale_colour_manual("", breaks = c("No redistribution","Egalitarian","Difference-proportionate","Sufficientarian"), 
                      values = c("gray20","springgreen4","orange","royalblue1")) +
  labs(title="Access potential global standard deviation", 
       y="indicator units", x="random damage limit %") +
  theme(axis.title.y=element_text(family="Times", size=rel(1.5),face="bold"),
        axis.title.x=element_text(family="Times", size=rel(1.5),face="bold"),
        plot.title = element_text(family="Times", size = rel(1.5), face="bold"),
        plot.subtitle = element_text(family="Times", size = rel(1.7)),
        legend.text = element_text(family="Times", size=rel(1.5),face="bold"))


#########################################################################
#########################################################################


ggarrange(gg1, gg2, gg3, gg4,
          labels = c("A:", "B:", "C:","D:"),
          ncol = 2, nrow = 2)
ggsave("stdevs-access-potential-2.png",width = 16, height = 12)


ggarrange(gg1 + ylim(0,1), gg3 + ylim(0,1),
          labels = c("A:", "B:"),
          ncol = 2, nrow = 1, common.legend = TRUE, legend="bottom")
ggsave("stdevs-access-potential-3.png", width = 16, height = 8)