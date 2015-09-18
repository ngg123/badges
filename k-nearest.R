library(foreach)


classify <- function(obs,trainingDat){
  dist <- foreach(i=1:nrow(trainingDat),.combine=c) %do% {
    hamDist(obs,trainingDat[i,])
  }
  trainingDat[which.max(dist),1]
}

featurizer <- function(mat){
  cbind(mat[,'V10']=='positive',
        foreach(i=1:ncol(mat),.combine=cbind) %do% {
          xs <- mat[,i]=='x'
          os <- mat[,i]=='o'
          cbind(xs,os)
        })
}

hamDist <- function(newDat,oldDat){
  ln <- length(newDat)
  newDat <- newDat[-1]
  oldDat <- oldDat[-1]
  sum(!(xor(oldDat,newDat)))
}



validate <- function(obs,trainingDat){!xor(classify(obs,trainingDat),(obs[1]))}

xval <- function(trainingDat){
  foreach(i=1:6) %do% {
    holdout <- sample(1:nrow(trainingDat),nrow(trainingDat)/6)
    train <- setdiff(1:nrow(trainingDat),holdout)
    sum(unlist(
      foreach(i=holdout) %do% { validate(trainingDat[i,],trainingDat[train,])}))
  }
}


