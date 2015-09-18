
getTicTacTrainData <- function(){
  foreach(i=1:6,.combine=rbind) %do% {
    read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'train-',i,'.txt'),header=F)
  }
  
}

getTicTacTestData <- function(){
  read.csv(paste0(BASE_DAT_DIR,BASE_DAT_FNAME,'test.txt'),header=F)
}

featurizer.TicTac <- function(mat){
  cbind(mat[,'V10']=='positive',
        foreach(i=1:(ncol(mat)-1),.combine=cbind) %do% {
          xs <- mat[,i]=='x'
          os <- mat[,i]=='o'
          cbind(xs,os)
        })
}