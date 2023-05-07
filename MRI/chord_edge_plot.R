# https://github.com/jokergoo/circlize/issues/286


df <- read.csv("Results.csv")

nodes <- unique(c(df$roi.x, df$roi.y))

nodes2 <- data.frame(id = 1:length(nodes),
                     node  = nodes,
                     side = substr(nodes, nchar(nodes), nchar(nodes)))

# Calculate the ANGLE of the labels
nodes2$angle <- 90 - 360 * nodes2$id / length(nodes)
# Calculate the alignment of labels: right or left
# If I am on the left part of the plot, my labels have currently an angle < -90
nodes2$hjust <- ifelse( nodes2$angle < -90, 1, 0)
# Flip angle BY to make them readable
nodes2$angle <- ifelse(nodes2$angle < -90, nodes2$angle+180, nodes2$angle)

# Plotting only schizophrenia
schiz <- df[, c("roi.x","roi.y", "d.schiz", "p.schiz", "p.schiz.fwer")]

# Applying FWER correction
schiz2 <- schiz[schiz$p.schiz.fwer <0.05,]

# The connection object must refer to the ids of the leaves:
schiz2$roi.x  <-  match(schiz2$roi.x, nodes)
schiz2$roi.y  <-  match(schiz2$roi.y, nodes)

net.tidy <- tbl_graph(nodes = nodes2, edges = schiz2, directed = TRUE)

ggraph(net.tidy, layout = 'linear', circular = TRUE) + 
  geom_edge_arc(aes(color = d.schiz, width = d.schiz, alpha = d.schiz)) + 
  scale_edge_width(range = c(0,1), guide = "none") +
  scale_edge_alpha(guide = "none") +
  scale_edge_color_gradient2(limits = c(-0.4, 0.4)) +
  geom_node_point(size = 2) +
  geom_node_label(aes(label=node)) +
  labs(edge_width = "d.schiz") +
  ggtitle("DLPFC Network Connectivity in Schizophrenia") +
  theme_void() +
  theme(legend.position = "bottom")



# Chord diagram using Circlize

conmat <- matrix(data = NA, nrow = length(nodes), ncol = length(nodes),
                 dimnames = list(nodes, nodes))

for(i in nodes){
  for(j in nodes) {
    if(i==j) {
      conmat[i,j] <- 1}
    if(match(i, nodes) < match(j, nodes)) {
      conmat[i,j] <- df[df$roi.x == i & df$roi.y == j, "d.schiz"]}
    if(match(i, nodes) > match(j, nodes)) {
      conmat[i,j] <- df[df$roi.x == j & df$roi.y == i, "d.schiz"]}
  }
}

schiz <- df[, c("roi.x","roi.y", "d.schiz", "p.schiz", "p.schiz.fwer")]
schiz2 <- schiz[schiz$p.schiz.fwer <0.05,]

circos.clear()
circos.par(start.degree = 90, clock.wise = FALSE)
chordDiagramFromDataFrame(schiz2[, 1:3],
                          order = nodes2[order(nodes2$side),]$node,
                          link.sort = TRUE, link.decreasing = TRUE,
             col = colorRamp2(c(-0.8, 0, 0.8), c("blue", "white", "red")))
