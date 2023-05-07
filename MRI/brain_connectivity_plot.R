library(brainconn)


# My custom-made helper function to transform long-form data back to matrices!
table.to.matrix <- function(x=NULL, conmat = NULL) { 
  nodes <- unique(c(x$roi.x, x$roi.y))
  if (is.null(x)) {
    stop("You need to provide your results data frame with the following columns: \n roi.x, roi.y, d.fwer")
  }
  if (!all(c("roi.x", "roi.y", "d.fwer") %in% names(x))) {
    stop("You need to provide your results data frame with the following columns: \n roi.x, roi.y, d.fwer")
  }
  
  if(is.null(conmat)) {conmat = matrix(data = NA, 
                                       nrow = length(nodes), 
                                       ncol = length(nodes),
                                       dimnames = list(nodes, nodes))}
  for(i in nodes){
    for(j in nodes) {
      if(i==j) {conmat[i,j] <- 1}
      if(match(i, nodes) < match(j, nodes)) {
        conmat[i,j] <- x[x$roi.x == i & schiz$roi.y == j, "d.fwer"]}
      if(match(i, nodes) > match(j, nodes)) {
        conmat[i,j] <- x[x$roi.x == j & schiz$roi.y == i, "d.fwer"]}
    }
  }
  return(conmat)
}


# Load the brainnetome atlas labels file
bn_atlas <- read.csv("BN_246_LUT_Labs_Coords.csv")
bn_atlas <- bn_atlas[, c("label", "x.mni","y.mni", "z.mni", "Yeo_7network")]

names(bn_atlas)[1] <- 'ROI.Name' # Change these names, for brainconn
names(bn_atlas)[5] <- "network"

bn_atlas$ROI.Name <- gsub("/", ".", bn_atlas$ROI.Name)  #Change slashes into periods, for R!

check_atlas(bn_atlas)


# Make a connectivity matrix template for brainconn
bn.rois = bn_atlas$ROI.Name 
bn.conmat <- matrix(data = NA, nrow = length(bn.rois), ncol = length(bn.rois),
                    dimnames = list(bn.rois, bn.rois))
bn.conmat <- data.frame(conmat)



# Read the results file
df <- read.csv("Results.csv")

df$roi.x <- gsub("/", ".", df$roi.x)
df$roi.y <- gsub("/", ".", df$roi.y)

 # Changing the specific results into matrices

schiz <- df[, c("roi.x","roi.y", "d.schiz", "p.schiz.fwer")]
dep <- df[, c("roi.x","roi.y", "d.dep", "p.dep.fwer")]

schiz$d.fwer <- ifelse(schiz$p.schiz.fwer > 0.05, NA, schiz$d.schiz)
dep$d.fwer <- ifelse(dep$p.dep.fwer > 0.05, NA, dep$d.dep)

mat.schiz = table.to.matrix(x=schiz, conmat = bn.conmat)
mat.dep = table.to.matrix(x=dep, conmat = bn.conmat)

mat.schiz[is.na(mat.schiz)] <- 0
mat.dep[is.na(mat.dep)] <- 0


brainconn(atlas = bn_atlas, conmat = mat.schiz,view = "ortho",
          node.size = 1.5, edge.width = 0.8,
         edge.color.weighted = T,
         edge.color = scale_edge_color_gradient2( low = "darkred", 
                                                  mid = "white", 
                                                  high ="blue", 
                                                  midpoint = 0, 
                                                  space = "Lab", 
                                                  na.value = "grey50", 
                                                  guide = "edge_colourbar"),
          node.color = "network",
          labels = TRUE,
          label.size = 3)

brainconn(atlas = bn_atlas, conmat = mat.dep,view = "ortho",
          node.size = 1.5, edge.width = 0.8,
          edge.color.weighted = T,
          edge.color = scale_edge_color_gradient2( low = "darkred", 
                                                   mid = "white", 
                                                   high ="blue", 
                                                   midpoint = 0, 
                                                   space = "Lab", 
                                                   na.value = "grey50", 
                                                   guide = "edge_colourbar"),
          node.color = "network",
          labels = TRUE,
          label.size = 3)

