library(foreach)


BASE_DAT_FNAME <- '/tic-tac-toe-'
BASE_DAT_DIR <- './data/tic-tac-toe/'

runKNN <- function(){
  trainingDat <- featurizer(getTrainData())
  testDat <- featurizer(getTestData())
  xvalRunTime <-  system.time(xvalNums <- sum(xval(trainingDat)[,'numGood'])/
                nrow(trainingDat))['elapsed']
  
  testGood <- sum(validate(testDat,trainingDat ))/nrow(testDat)
  print(paste0('6-fold x-validation clock time: ',round(xvalRunTime,digits = 3),' seconds'))
  print(paste0('6-fold x-val % correct: ',round(xvalNums,digits=4)*100))
  print(paste0('test data % correct: ',round(testGood,digits=4)*100))  
}


getTrainData <- function(){
  foreach(i=1:6,.combine=rbind) %do% {
    read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'train-',i,'.txt'),header=F)
  }
  
}

getTestData <- function(){
  read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'test.txt'),header=F)
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

classify <- function(obs,trainingDat,n=1){
  dist <- apply(trainingDat,1,function(tr)hamDist(obs,tr))
  topSamp <- order(dist,decreasing = T)
  trainingDat[topSamp[1],1]
}

validate <- function(obs,trainingDat){
  f <- function(obsp){!xor(classify(matrix(obsp,ncol=ncol(obs)),trainingDat),(obsp[1]))}
  matrix(apply(obs,1,f),ncol=1)
}

xval <- function(trainingDat){
  nums <- rep(1:6,ceiling(nrow(trainingDat)/6))[1:nrow(trainingDat)]
  sets <- sample(nums,nrow(trainingDat),replace = F)
  foreach(i=1:6,.combine=rbind,
          .export = c('validate','classify','hamDist')
  ) %dopar% {
    holdout <- which(sets==i)
    train <- setdiff(1:nrow(trainingDat),holdout)
    data.frame(i=i,numGood=sum(validate(trainingDat[holdout,,drop=F],
                                  trainingDat[train,,drop=F]))
      
    )
  } 
}


