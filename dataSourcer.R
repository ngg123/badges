
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



importBadgeData <- function(){
  badges <- read.csv('./data/badges.txt',header=F,stringsAsFactors = F, sep=' ')
  
  #
  # Some people don't have middle names
  # Let's make sure their family name is in the lname column, not the mname one
  #
  badges$V4[badges$V4 == ''] <- badges$V3[badges$V4 == '']
  badges$V3[badges$V4 == badges$V3] <- ''
  
  #
  # There are a couple people with 'four' names ('de la lname' confuses
  # import.csv).  Their real last name gets put in the label column of the
  # next row, and we want to avoid that.
  #
  badges <- subset(badges, V1 %in% c('+','-'))
  
  #
  # Give names to the columns
  #
  colnames(badges) <- c('label','fname','mname','lname')
  badges
}
#
# For badges data
#
nameToMax <- function(nameList) {
  #
  # These are the universe of characters allowed in names
  #
  lets <- c(letters,'-','.')
  
  nameMax <- matrix(0,nrow=length(nameList),ncol=length(lets)*max(nchar(nameList)))
  
  #
  #  Build binary vectors for each character position in the name
  #
  for(i in 1:length(nameList)) {
    name <- nameList[i]
    for(j in 1:nchar(name)){
      ch <- substr(name,j,j)
      col <- length(lets)*(j-1)+which(lets == tolower(ch))
      nameMax[i,col] <- 1
    }
    
  }
  nameMax
}
