#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)



fisher.test(matrix(c(as.numeric(args[1]), as.numeric(args[2]), as.numeric(args[3]), as.numeric(args[4])), 2, 2))$p.value

