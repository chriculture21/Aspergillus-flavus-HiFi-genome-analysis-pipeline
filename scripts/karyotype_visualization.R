# ---------------------------------------------------------------
# Ideogram of Aspergillus flavus BAF47:
# gene density, biosynthetic gene clusters, aflatoxin cluster
# ---------------------------------------------------------------

library(karyoploteR)
library(rtracklayer)

# 1. Chromosomes: name and length
chr <- read.table("C:/Users/User/Documents/BAF47_chromosomes.tsv",
                  sep = "\t", col.names = c("chr", "end"))
genome <- toGRanges(data.frame(chr = chr$chr, start = 1, end = chr$end))

# 2. Genes: protein-coding genes (mRNA features) from funannotate
gff   <- import("C:/Users/User/Documents/Aspergillus_flavus_BAF47.gff3")
genes <- gff[gff$type == "mRNA"]

# 3. Gene density: count genes in 100 kb windows
wins <- unlist(tile(genome, width = 100000))
wins$genes <- countOverlaps(wins, genes)

# 4. Biosynthetic gene clusters from antiSMASH
bgc <- read.table("C:/Users/User/Documents/BAF47_antismash_regions.tsv", sep = "\t",
                  col.names = c("chr", "start", "end", "region", "type"))
bgc$start <- bgc$start + 1

bgc$class <- ifelse(grepl("PKS", bgc$type) & grepl("NRPS", bgc$type), "PKS-NRPS hybrid",
                    ifelse(grepl("PKS", bgc$type),     "PKS",
                           ifelse(grepl("NRPS", bgc$type),    "NRPS",
                                  ifelse(grepl("terpene", bgc$type), "Terpene", "Other"))))

cols <- c("PKS" = "#e41a1c", "NRPS" = "#377eb8", "PKS-NRPS hybrid" = "#984ea3",
          "Terpene" = "#4daf4a", "Other" = "#ff7f00")

# 5. The aflatoxin cluster (KnownClusterBlast top hit: BGC0000007)
afla <- bgc[bgc$chr == "ptg000004l" & bgc$region == "region010", ]

# 6. Layout settings
pp <- getDefaultPlotParams(plot.type = 1)
pp$ideogramheight <- 40
pp$data1height <- 100
pp$leftmargin <- 0.10

# 7. Draw
png("BAF47_ideogram.png", width = 2200, height = 1400, res = 200)

kp <- plotKaryotype(genome = genome, plot.type = 1, plot.params = pp,
                    ideogram.plotter = NULL, cex = 0.9)

# chromosomes coloured by gene density, with an outline
kpHeatmap(kp, data = wins, y = wins$genes, data.panel = "ideogram",
          colors = c("#f7fbff", "#6baed6", "#08306b"))
kpRect(kp, data = genome, y0 = 0, y1 = 1, data.panel = "ideogram",
       col = NA, border = "grey30")

# all clusters as triangles
kpPoints(kp, chr = bgc$chr, x = (bgc$start + bgc$end) / 2, y = 0.3,
         pch = 25, cex = 1.1, col = "grey20", bg = cols[bgc$class], data.panel = 1)

# aflatoxin cluster: bigger triangle with a thick outline, plus a label
kpPoints(kp, chr = afla$chr, x = (afla$start + afla$end) / 2, y = 0.3,
         pch = 25, cex = 1.8, lwd = 2, col = "black", bg = cols[afla$class], data.panel = 1)
kpText(kp, chr = afla$chr, x = (afla$start + afla$end) / 2, y = 0.75,
       labels = "Aflatoxin cluster", cex = 0.8, font = 3, data.panel = 1)

# ruler, title, legend
kpAddBaseNumbers(kp, tick.dist = 1e6, minor.tick.dist = 5e5, add.units = TRUE, cex = 0.6)
kpAddMainTitle(kp, main = expression(italic("Aspergillus flavus") ~ "BAF47"), cex = 1.3)
legend("bottomright", legend = names(cols), pt.bg = cols, pch = 25,
       col = "grey20", bty = "n", cex = 0.8, title = "Biosynthetic gene clusters")

dev.off()


