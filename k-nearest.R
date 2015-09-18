library(foreach)


BASE_DAT_FNAME <- '/tic-tac-toe-'
BASE_DAT_DIR <- './data/tic-tac-toe/'

runKNN <- function(){
  trainingDat <- featurizer(getTestData())
  testDat <- featurizer(getTrainData())
  sum(unlist(xval(trainingDat = trainingDat)))/nrow(trainingDat)
}


getTrainData <- function(){
  foreach(i=1:6,.combine=rbind) %do% {
    read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'train-',i,'.txt'),header=F)
  }
  
}

getTestData <- function(){
  read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'test.txt'),header=F)
}

classify <- function(obs,trainingDat){
  dist <- apply(trainingDat,1,function(tr)hamDist(obs,tr))
  trainingDat[which.max(dist),1]
}

featurizer <- function(mat){
  cbind(mat[,'V10']=='positive',
        foreach(i=1:(ncol(mat)-1),.combine=cbind) %do% {
          xs <- mat[,i]=='x'
          os <- mat[,i]=='o'
          cbind(xs,os)
        })
}

hamDist <- function(newDat,oldDat){
  newDat <- newDat[-1]
  oldDat <- oldDat[-1]
  sum(!(xor(oldDat,newDat)))
}



validate <- function(obs,trainingDat){!xor(classify(obs,trainingDat),(obs[1]))}

xval <- function(trainingDat){
  nums <- rep(1:6,ceiling(nrow(trainingDat)/6))[1:nrow(trainingDat)]
  sets <- sample(nums,nrow(trainingDat),replace = F)
  foreach(i=1:6,.combine=c,
          .packages = 'foreach',
          .export = c('validate','classify','hamDist')
  ) %dopar% {
    holdout <- which(sets==i)
    train <- setdiff(1:nrow(trainingDat),holdout)
    sum(
      foreach(j=holdout,.combine=c) %do% { 
        validate(trainingDat[j,],trainingDat[train,])
      }
    )
  } 
}


